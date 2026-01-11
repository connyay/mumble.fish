import Foundation

// MARK: - Tone Style

enum ToneStyle: String, CaseIterable, Identifiable {
    case casual = "Casual"
    case professional = "Professional"
    case formal = "Formal"
    case friendly = "Friendly"
    case concise = "Concise"

    var id: String { rawValue }
}

// MARK: - API Models

struct PolishRequest: Codable {
    let text: String
    let tone: String
}

struct PolishResponse: Codable {
    let success: Bool
    let data: PolishData?
    let error: String?

    struct PolishData: Codable {
        let polished: String
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case sessionExpired

    var errorDescription: String? {
        switch self {
        case .sessionExpired:
            return "Session expired. Please sign in again."
        }
    }
}

// MARK: - API Client

@MainActor
class APIClient: ObservableObject {
    @Published var isProcessing = false
    @Published var polishedText = ""
    @Published var errorMessage: String?

    private static let mumbleFishURL = URL(string: "https://mumble.fish/api/v1/polish")!

    func polishNote(_ rawText: String, style: ToneStyle, authManager: AuthManager) async {
        guard !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "No text to polish"
            return
        }

        guard authManager.canPolish else {
            errorMessage = "Please sign in or set your own API key in Settings"
            return
        }

        isProcessing = true
        errorMessage = nil
        // Don't clear polishedText - keep showing previous result until new one arrives

        do {
            polishedText = try await callAPI(
                rawText,
                style: style,
                authToken: authManager.authToken,
                openAIKey: authManager.useBYOK ? authManager.openaiApiKey : nil
            )
        } catch APIError.sessionExpired {
            authManager.signOut()
            errorMessage = "Session expired. Please sign in again."
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    // MARK: - API

    private func callAPI(_ text: String, style: ToneStyle, authToken: String?, openAIKey: String?) async throws -> String {
        var request = URLRequest(url: Self.mumbleFishURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // BYOK mode: pass OpenAI key via header, worker uses it directly
        // Authenticated mode: pass auth token for rate limiting, worker uses its own key
        if let openAIKey = openAIKey, !openAIKey.isEmpty {
            request.setValue(openAIKey, forHTTPHeaderField: "X-OpenAI-Key")
        } else if let authToken = authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder().encode(PolishRequest(text: text, tone: style.rawValue.lowercased()))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode == 401 {
            throw APIError.sessionExpired
        }

        if httpResponse.statusCode == 429 {
            throw NSError(domain: "APIClient", code: 429, userInfo: [NSLocalizedDescriptionKey: "Rate limit exceeded. Please wait a moment or use your own API key."])
        }

        if httpResponse.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "APIClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error (\(httpResponse.statusCode)): \(errorBody)"])
        }

        let polishResponse = try JSONDecoder().decode(PolishResponse.self, from: data)

        if let error = polishResponse.error {
            throw NSError(domain: "APIClient", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
        }

        return polishResponse.data?.polished ?? ""
    }
}
