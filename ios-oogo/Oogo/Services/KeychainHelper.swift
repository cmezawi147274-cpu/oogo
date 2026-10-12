//
//  KeychainHelper.swift
//  Oogo
//
//  Small wrapper over the keychain for auth tokens.
//

import Foundation
import Security

/// Nonisolated so the Supabase client can read the token from any thread.
nonisolated enum KeychainHelper {
    static func set(_ key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Token names oogo keeps in the keychain.
nonisolated enum AuthToken {
    static let access = "access_token"
    static let refresh = "refresh_token"

    /// Current access token, readable from any thread. `nil` means signed out.
    static func currentAccess() -> String? {
        KeychainHelper.get(access)
    }
}
