import Foundation
import Security
import AppKit

// MARK: - Keychain Helper

enum KeychainError: Error {
    case duplicateEntry
    case invalidData
    case unknown(OSStatus)
}

struct Keychain {
    static let service = "fish.mumble.MumbleFish"

    static func save(_ value: String, for account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    static func retrieve(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    static func delete(for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Auth Manager

@MainActor
class AuthManager: ObservableObject {
    private static let tokenAccount = "auth_token"
    private static let emailAccount = "user_email"
    private static let openaiKeyAccount = "openai_api_key"
    private static let baseURL = "https://mumble.fish"

    @Published var isSignedIn = false
    @Published var userEmail: String?
    @Published var useBYOK = false

    init() {
        if let token = Keychain.retrieve(for: Self.tokenAccount), !token.isEmpty {
            isSignedIn = true
            userEmail = Keychain.retrieve(for: Self.emailAccount)
        }

        useBYOK = Keychain.retrieve(for: Self.openaiKeyAccount) != nil
    }

    var authToken: String? {
        Keychain.retrieve(for: Self.tokenAccount)
    }

    var openaiApiKey: String {
        get { Keychain.retrieve(for: Self.openaiKeyAccount) ?? "" }
        set {
            if newValue.isEmpty {
                Keychain.delete(for: Self.openaiKeyAccount)
                useBYOK = false
            } else {
                try? Keychain.save(newValue, for: Self.openaiKeyAccount)
                useBYOK = true
            }
        }
    }

    var hasOpenAIKey: Bool {
        !openaiApiKey.isEmpty
    }

    var canPolish: Bool {
        isSignedIn || hasOpenAIKey
    }

    // MARK: - Sign In

    func signIn(with provider: String = "google") {
        let redirectUri = "mumblefish://auth/callback"
        let urlString = "\(Self.baseURL)/api/v1/auth/oauth/\(provider)?redirect_uri=\(redirectUri.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? redirectUri)"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Handle OAuth Callback

    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              queryItems.first(where: { $0.name == "error" })?.value == nil,
              let token = queryItems.first(where: { $0.name == "token" })?.value else {
            return
        }

        do {
            try Keychain.save(token, for: Self.tokenAccount)
            isSignedIn = true
            Task { await fetchUserInfo() }
        } catch {
            print("[MumbleFish] Failed to save auth token: \(error)")
        }
    }

    // MARK: - Fetch User Info

    private func fetchUserInfo() async {
        guard let token = authToken else { return }

        var request = URLRequest(url: URL(string: "\(Self.baseURL)/api/v1/auth/me")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        struct MeResponse: Codable {
            let success: Bool
            let data: UserData?

            struct UserData: Codable {
                let id: String
                let email: String
            }
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let meResponse = try? JSONDecoder().decode(MeResponse.self, from: data),
              let userData = meResponse.data else {
            return
        }

        userEmail = userData.email
        try? Keychain.save(userData.email, for: Self.emailAccount)
    }

    // MARK: - Sign Out

    func signOut() {
        Keychain.delete(for: Self.tokenAccount)
        Keychain.delete(for: Self.emailAccount)
        isSignedIn = false
        userEmail = nil
    }
}
