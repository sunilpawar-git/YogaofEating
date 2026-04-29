import Combine
import FirebaseAuth
import FirebaseCore
import Foundation
import GoogleSignIn
import OSLog

private let authLogger = Logger(subsystem: "com.yogaofeating", category: "Auth")

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
    func addStateDidChangeListener(_ listener: @escaping (AuthUser?) -> Void) -> Any?
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

    func addStateDidChangeListener(_ listener: @escaping (AuthUser?) -> Void) -> Any? {
        guard FirebaseApp.app() != nil else { return nil }
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
    private var authListenerHandle: Any? // nil when Firebase is not configured

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
                authLogger.debug("No previous session to restore: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func setupAuthStateListener() {
        self.authListenerHandle = self.provider.addStateDidChangeListener { [weak self] user in
            guard let self else { return }

            if let user {
                authLogger.debug("Auth state: user signed in")
                self.pendingLogoutTask?.cancel()
                self.pendingLogoutTask = nil
                self.isExplicitlySigningOut = false
                self.currentUser = user
            } else {
                authLogger.debug("Auth state: nil user (explicit=\(self.isExplicitlySigningOut, privacy: .public))")

                if self.isExplicitlySigningOut {
                    self.pendingLogoutTask?.cancel()
                    self.currentUser = nil
                    return
                }

                self.pendingLogoutTask?.cancel()
                self.pendingLogoutTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    guard !Task.isCancelled else {
                        authLogger.debug("Auth debounce cancelled (user recovered)")
                        return
                    }
                    authLogger.debug("Auth debounce completed — accepting nil user")
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
            authLogger.error("Sign out failed: \(error.localizedDescription, privacy: .public)")
            self.isExplicitlySigningOut = false
        }
    }
}
