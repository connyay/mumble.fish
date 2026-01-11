import Foundation

@MainActor
class NotesStore: ObservableObject {
    @Published var notes: [Note] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MumbleFish", isDirectory: true)

        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        fileURL = appDir.appendingPathComponent("notes.json")
        loadNotes()
    }

    func addNote(_ note: Note) {
        notes.insert(note, at: 0)
        saveNotes()
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }

    func clearHistory() {
        notes.removeAll()
        saveNotes()
    }

    private func loadNotes() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            print("[MumbleFish] Failed to load notes: \(error.localizedDescription)")
        }
    }

    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL)
        } catch {
            print("[MumbleFish] Failed to save notes: \(error.localizedDescription)")
        }
    }
}
