import Combine
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Protocol representing an authenticated user
protocol AuthUser {
    var uid: String { get }
    var displayName: String? { get }
    var email: String? { get }
}

extension FirebaseAuth.User: AuthUser {}

/// Protocol for the underlying authentication provider to enable testability.
@MainActor
protocol AuthCoreProvider {
    var currentUser: AuthUser? { get }
    func signInWithGoogle() async throws -> AuthUser
    func signOut() throws
    func addStateDidChangeListener(_ listener: @escaping (AuthUser?) -> Void) -> Any
    func restorePreviousSignIn() async throws -> AuthUser
}

/// Firebase implementation of the AuthCoreProvider
@MainActor
class FirebaseAuthCoreProvider: AuthCoreProvider {
    var currentUser: AuthUser? {
        guard FirebaseApp.app() != nil else { return nil }
        return Auth.auth().currentUser
    }

    func signInWithGoogle() async throws -> AuthUser {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(
                domain: "AuthService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Firebase Client ID not found"]
            )
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        #if canImport(UIKit)
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController
            else {
                throw NSError(
                    domain: "AuthService",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No root view controller found"]
                )
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        #elseif canImport(AppKit)
            guard let presentingWindow = NSApplication.shared.keyWindow else {
                throw NSError(
                    domain: "AuthService",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "No key window found"]
                )
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)
        #endif

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(
                domain: "AuthService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Google ID Token missing"]
            )
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user
    }

    func signOut() throws {
        guard FirebaseApp.app() != nil else { return }
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    func addStateDidChangeListener(_ listener: @escaping (AuthUser?) -> Void) -> Any {
        guard FirebaseApp.app() != nil else { return "no_firebase_handle" }
        return Auth.auth().addStateDidChangeListener { _, user in
            listener(user)
        }
    }

    func restorePreviousSignIn() async throws -> AuthUser {
        guard FirebaseApp.app() != nil else {
            throw NSError(
                domain: "AuthService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Firebase not configured"]
            )
        }
        let user = try await GIDSignIn.sharedInstance.restorePreviousSignIn()

        let idToken = try await user.refreshTokensIfNeeded().idToken?.tokenString
        let accessToken = user.accessToken.tokenString

        guard let idToken else {
            throw NSError(
                domain: "AuthService",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Failed to restore ID Token"]
            )
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user
    }
}

/// Protocol for authentication services, enabling dependency injection and testing
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var currentUser: AuthUser? { get }
    func signInWithGoogle() async throws
    func signOut()
}

@MainActor
class AuthService: ObservableObject, AuthServiceProtocol {
    static let shared = AuthService()

    @Published private(set) var currentUser: AuthUser?
    private let provider: AuthCoreProvider
    private var authListenerHandle: Any?

    // Task to track pending logout debounce
    private var pendingLogoutTask: Task<Void, Never>?

    // Flag to track if logout was explicitly requested by the user
    // This allows us to ignore all transient nil states from Firebase
    private var isExplicitlySigningOut = false

    /// Initializer for production (uses Firebase)
    private init() {
        self.provider = FirebaseAuthCoreProvider()
        self.currentUser = self.provider.currentUser
        self.setupAuthStateListener()
        self.restorePreviousSession()
    }

    /// Initializer for dependency injection (tests)
    init(provider: AuthCoreProvider) {
        self.provider = provider
        self.currentUser = provider.currentUser
        self.setupAuthStateListener()
        self.restorePreviousSession()
    }

    private func restorePreviousSession() {
        Task {
            do {
                _ = try await self.provider.restorePreviousSignIn()
            } catch {
                // Not necessarily an error if no previous session exists
                print("No previous session to restore")
            }
        }
    }

    private func setupAuthStateListener() {
        self.authListenerHandle = self.provider.addStateDidChangeListener { [weak self] user in
            guard let self else { return }

            if let user {
                // Valid user received - cancel any pending logout and update immediately
                print("🔐 AuthState: User received - \(user.uid)")
                self.pendingLogoutTask?.cancel()
                self.pendingLogoutTask = nil
                self.isExplicitlySigningOut = false // Reset explicit flag
                self.currentUser = user
            } else {
                // Nil user received.
                print("🔐 AuthState: NIL user received! isExplicitlySigningOut=\(self.isExplicitlySigningOut)")

                // If we are explicitly signing out, accept it immediately.
                if self.isExplicitlySigningOut {
                    print("🔐 AuthState: Accepting nil (explicit sign out)")
                    self.pendingLogoutTask?.cancel()
                    self.currentUser = nil
                    return
                }

                // Otherwise, debounce it!
                // This protects against ANY transient nil state (token refresh, login flow, sync, etc.)
                print("🔐 AuthState: Starting 2s debounce for transient nil state...")

                // Cancel any existing pending logout
                self.pendingLogoutTask?.cancel()

                // Create a new debounce task
                self.pendingLogoutTask = Task { @MainActor in
                    // Wait 2000ms (2s) to see if this is a transient nil state
                    try? await Task.sleep(nanoseconds: 2_000_000_000)

                    // If we weren't cancelled, the nil state persisted - accept it
                    // This handles real session revocations (remote logout)
                    guard !Task.isCancelled else {
                        print("🔐 AuthState: Debounce cancelled (user recovered)")
                        return
                    }

                    print("🔐 AuthState: Debounce completed - accepting nil user (session expired?)")
                    self.currentUser = nil
                    self.pendingLogoutTask = nil
                }
            }
        }
    }

    func signInWithGoogle() async throws {
        self.isExplicitlySigningOut = false // Ensure we are ready to accept user
        let user = try await provider.signInWithGoogle()
        self.currentUser = user
    }

    func signOut() {
        self.isExplicitlySigningOut = true

        // Cancel any pending debounce
        self.pendingLogoutTask?.cancel()
        self.pendingLogoutTask = nil

        do {
            try self.provider.signOut()
            self.currentUser = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
            self.isExplicitlySigningOut = false // Reset if failed
        }
    }
}
