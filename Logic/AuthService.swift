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

extension FirebaseAuth.User: AuthUser {
    // These properties already exist on FirebaseAuth.User
}

/// Protocol for authentication services, enabling dependency injection and testing
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    /// The currently authenticated Firebase user
    var currentUser: AuthUser? { get set }

    /// Sign in with Google account
    func signInWithGoogle() async throws

    /// Sign out the current user
    func signOut()
}

@MainActor
class AuthService: ObservableObject, AuthServiceProtocol {
    // Use a computed property to lazily create the shared instance
    // This prevents Firebase access during module loading in tests
    private nonisolated(unsafe) static var _shared: AuthService?

    static var shared: AuthService {
        // Return a dummy instance during unit tests to prevent Firebase access
        if NSClassFromString("XCTestCase") != nil {
            if _shared == nil {
                _shared = AuthService(currentUser: nil)
            }
        } else if _shared == nil {
            _shared = AuthService(initializeFromFirebase: true)
        }
        guard let shared = _shared else {
            fatalError("Failed to initialize AuthService shared instance")
        }
        return shared
    }

    @Published var currentUser: AuthUser?

    // Private initializer for singleton - only called when shared is first accessed
    private init(initializeFromFirebase: Bool) {
        if initializeFromFirebase, FirebaseApp.app() != nil {
            self.currentUser = Auth.auth().currentUser
        } else {
            self.currentUser = nil
        }
    }

    // Initializer for dependency injection in tests - does NOT access Firebase
    init(currentUser: User? = nil) {
        self.currentUser = currentUser
    }

    func signInWithGoogle() async throws {
        // 1. Get client ID
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let errorMsg = "Firebase Client ID not found"
            throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        // 2. Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        // 3. Start sign in flow
        #if canImport(UIKit)
            // iOS: Need root view controller
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController
            else {
                let errorMsg = "No root view controller found"
                throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        #elseif canImport(AppKit)
            // macOS: Use key window for presentation
            guard let presentingWindow = NSApplication.shared.keyWindow else {
                let errorMsg = "No key window found for Google Sign-In"
                throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)
        #endif

        // 4. Authenticate with Firebase
        guard let idToken = result.user.idToken?.tokenString else {
            let errorMsg = "Google ID Token missing"
            throw NSError(domain: "AuthService", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        self.currentUser = authResult.user
    }

    func signOut() {
        // Only sign out from Firebase if it's configured
        if FirebaseApp.app() != nil {
            do {
                try Auth.auth().signOut()
                GIDSignIn.sharedInstance.signOut()
            } catch {
                print("Error signing out: \(error.localizedDescription)")
            }
        }
        // Always clear the current user
        self.currentUser = nil
    }
}
