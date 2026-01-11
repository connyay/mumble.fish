import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    let rawText: String
    let polishedText: String
    let style: String
    let createdAt: Date

    init(rawText: String, polishedText: String, style: ToneStyle) {
        self.id = UUID()
        self.rawText = rawText
        self.polishedText = polishedText
        self.style = style.rawValue
        self.createdAt = Date()
    }
}
