import SwiftUI

// MARK: - App Delegate for URL handling

class AppDelegate: NSObject, NSApplicationDelegate {
    // Will be set by the App
    var authManager: AuthManager?

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "mumblefish" {
                print("[MumbleFish] Received OAuth callback: \(url)")
                authManager?.handleCallback(url: url)
            }
        }
    }
}

// MARK: - Main App

@main
struct MumbleFishApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var notesStore = NotesStore()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        MenuBarExtra("MumbleFish", image: "MenuBarIcon") {
            ContentView()
                .environmentObject(notesStore)
                .environmentObject(speechRecognizer)
                .environmentObject(authManager)
                .onAppear {
                    appDelegate.authManager = authManager
                }
        }
        .menuBarExtraStyle(.window)
    }
}
