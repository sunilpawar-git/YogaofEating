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

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?

    private init() {
        self.currentUser = Auth.auth().currentUser
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
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.currentUser = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
