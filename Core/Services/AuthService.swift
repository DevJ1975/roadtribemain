//
//  AuthService.swift
//  Road Tribe
//
//  Created by Jamil Jones on 4/6/26.
//

import Foundation
import AuthenticationServices
import Supabase

/// Manages user authentication via Supabase + Sign in with Apple.
@Observable
@MainActor
final class AuthService {

    private(set) var isAuthenticated = false
    /// Supabase user UUID (persisted by Supabase session manager).
    private(set) var currentUserID: String?
    /// SwiftData UserProfile.id — set to equal the Supabase user UUID after onboarding.
    private(set) var currentProfileID: UUID?

    private let keychain = KeychainHelper()
    private static let profileIDKey = "com.roadtribe.currentProfileID"

    init() {
        // Restore Supabase session (synchronous — Supabase caches it)
        if let session = supabase.auth.currentSession {
            currentUserID = session.user.id.uuidString
            isAuthenticated = true
        }

        // Restore profile UUID
        if let stored = UserDefaults.standard.string(forKey: Self.profileIDKey),
           let id = UUID(uuidString: stored) {
            currentProfileID = id
        }
    }

    // MARK: - Sign in with Apple → Supabase

    /// Called from OnboardingView after the user completes the Apple auth sheet.
    /// `nonce` is the **raw** (unhashed) nonce — Supabase hashes it internally.
    func handleAuthorization(result: Result<ASAuthorization, Error>, nonce: String) async throws {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8)
            else { throw AuthError.invalidCredential }

            // Apple only sends name/email on the very first sign-in — cache them
            if let email = credential.email {
                keychain.save(key: .email, value: email)
            }
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                if !name.isEmpty { keychain.save(key: .displayName, value: name) }
            }

            // Exchange Apple identity token for a Supabase session
            let session = try await supabase.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )

            currentUserID = session.user.id.uuidString
            isAuthenticated = true

        case .failure(let error):
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    /// Called after the UserProfile is created/fetched during onboarding.
    func setCurrentProfileID(_ id: UUID) {
        currentProfileID = id
        UserDefaults.standard.set(id.uuidString, forKey: Self.profileIDKey)
    }

    /// Sign out of Supabase and clear local state.
    func signOut() {
        Task { try? await supabase.auth.signOut() }
        keychain.delete(key: .email)
        keychain.delete(key: .displayName)
        currentUserID = nil
        isAuthenticated = false
        currentProfileID = nil
        UserDefaults.standard.removeObject(forKey: Self.profileIDKey)
    }

    // MARK: - Keychain Accessors

    var storedEmail: String? { keychain.read(key: .email) }
    var storedDisplayName: String? { keychain.read(key: .displayName) }
}

// MARK: - Keychain Helper

private struct KeychainHelper {

    enum Key: String {
        case email       = "com.roadtribe.email"
        case displayName = "com.roadtribe.displayName"
    }

    func save(key: Key, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: Key) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case signInFailed(String)
    case notAuthenticated
    case credentialRevoked

    var errorDescription: String? {
        switch self {
        case .invalidCredential:        return "Invalid sign-in credential."
        case .signInFailed(let reason): return "Sign in failed: \(reason)"
        case .notAuthenticated:         return "You are not signed in."
        case .credentialRevoked:        return "Your sign-in has been revoked. Please sign in again."
        }
    }
}
