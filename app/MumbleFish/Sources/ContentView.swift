import SwiftUI

// MARK: - Theme Colors

extension Color {
    static let mumbleTeal = Color(red: 0.29, green: 0.87, blue: 0.64) // #4ADE80
    static let mumbleTealDark = Color(red: 0.22, green: 0.65, blue: 0.48)
    static let mumbleBg = Color(red: 0.09, green: 0.11, blue: 0.13) // #171C21
    static let mumbleBgLight = Color(red: 0.13, green: 0.16, blue: 0.19)
    static let mumbleText = Color(red: 0.85, green: 0.87, blue: 0.89)
    static let mumbleTextMuted = Color(red: 0.55, green: 0.58, blue: 0.62)
}

enum ViewTab: String, CaseIterable {
    case record = "Record"
    case history = "History"
    case settings = "Settings"
}

struct ContentView: View {
    @EnvironmentObject var notesStore: NotesStore
    @EnvironmentObject var speechRecognizer: SpeechRecognizer
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var apiClient = APIClient()

    @State private var selectedTab: ViewTab = .record
    @AppStorage("selectedToneStyle") private var selectedStyleRaw: String = ToneStyle.concise.rawValue
    @State private var showCopied: Bool = false
    @State private var editingNote: Note? = nil

    private var selectedStyle: ToneStyle {
        get { ToneStyle(rawValue: selectedStyleRaw) ?? .concise }
        nonmutating set { selectedStyleRaw = newValue.rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Picker("", selection: $selectedTab) {
                ForEach(ViewTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            switch selectedTab {
            case .record:
                recordView
            case .history:
                historyView
            case .settings:
                settingsView
            }
        }
        .frame(width: 440, height: 580)
        .background(Color.mumbleBg)
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Spacer()
            HStack(spacing: 8) {
                Text("mumble.fish")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mumbleTextMuted)
                Circle()
                    .fill(speechRecognizer.isRecording ? Color.mumbleTeal : Color.mumbleTextMuted.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Record View

    private var recordView: some View {
        ScrollView {
            VStack(spacing: 16) {
                recordButton

                if !speechRecognizer.transcript.isEmpty {
                    transcriptSection
                }

                if let error = speechRecognizer.errorMessage ?? apiClient.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }

                if !speechRecognizer.transcript.isEmpty && !speechRecognizer.isRecording {
                    polishSection
                }

                // Polished result (show when we have text OR when processing/re-polishing)
                if !apiClient.polishedText.isEmpty || apiClient.isProcessing {
                    polishedSection
                }

                Spacer()
            }
            .padding()
        }
    }

    private var recordButton: some View {
        VStack(spacing: 8) {
            if editingNote != nil {
                HStack {
                    Text("Continuing note...")
                        .font(.caption)
                        .foregroundColor(.mumbleTextMuted)
                    Button("Cancel") {
                        editingNote = nil
                        speechRecognizer.transcript = ""
                        apiClient.polishedText = ""
                    }
                    .font(.caption)
                    .buttonStyle(.borderless)
                    .foregroundColor(.mumbleTeal)
                }
                .padding(.bottom, 4)
            }

            Button(action: {
                if speechRecognizer.isRecording {
                    speechRecognizer.stopRecording()
                    // If continuing, append to existing transcript
                    if let note = editingNote, !speechRecognizer.transcript.isEmpty {
                        let combined = note.rawText + " " + speechRecognizer.transcript
                        speechRecognizer.transcript = combined
                    }
                } else {
                    apiClient.polishedText = ""
                    speechRecognizer.startRecording(clearTranscript: editingNote == nil)
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(speechRecognizer.isRecording ? Color.mumbleTeal : Color.mumbleTealDark)
                            .frame(width: 56, height: 56)
                        Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(speechRecognizer.isRecording ? .mumbleBg : .white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(speechRecognizer.isRecording ? "Recording..." : (editingNote != nil ? "Add More" : "Start Recording"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.mumbleText)
                        Text(speechRecognizer.isRecording ? "Speak naturally" : "Click to begin")
                            .font(.system(size: 14))
                            .foregroundColor(.mumbleTextMuted)
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .disabled(!speechRecognizer.isAuthorized)
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RAW")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mumbleTextMuted)
                .tracking(1)

            Text("\"\(speechRecognizer.transcript)\"")
                .font(.system(size: 15))
                .italic()
                .foregroundColor(.mumbleText.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(4)
        }
    }

    private var polishSection: some View {
        VStack(spacing: 16) {
            if apiClient.polishedText.isEmpty && !apiClient.isProcessing {
                toneButtonsView
            }

            if apiClient.polishedText.isEmpty {
                Button(action: {
                    Task {
                        await apiClient.polishNote(speechRecognizer.transcript, style: selectedStyle, authManager: authManager)
                    }
                }) {
                    HStack {
                        if apiClient.isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.mumbleBg)
                        }
                        Text(apiClient.isProcessing ? "Polishing..." : "Polish as \(selectedStyle.rawValue)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.mumbleTeal)
                    .foregroundColor(.mumbleBg)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(apiClient.isProcessing || !authManager.canPolish)
            }

            if !authManager.canPolish {
                Text("Sign in or add your API key in Settings to polish notes")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private var polishedSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.mumbleTeal)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("POLISHED")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.mumbleTeal)
                        .tracking(1)

                    Spacer()

                    if !apiClient.isProcessing {
                        Button(action: copyToClipboard) {
                            HStack(spacing: 4) {
                                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                Text(showCopied ? "Copied!" : "Copy")
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.mumbleTeal)
                        }
                        .buttonStyle(.borderless)
                    }
                }

                if apiClient.isProcessing {
                    SkeletonView()
                } else {
                    Text("\"\(apiClient.polishedText)\"")
                        .font(.system(size: 15))
                        .foregroundColor(.mumbleText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineSpacing(4)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mumbleTeal.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mumbleTeal.opacity(0.4), lineWidth: 1)
                    )
            )

            toneButtonsView

            Button(action: {
                if let oldNote = editingNote {
                    notesStore.deleteNote(oldNote)
                }
                let note = Note(
                    rawText: speechRecognizer.transcript,
                    polishedText: apiClient.polishedText,
                    style: selectedStyle
                )
                notesStore.addNote(note)
                copyToClipboard()
                editingNote = nil
            }) {
                Text(editingNote != nil ? "Update Note" : "Save to History")
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.mumbleBgLight)
                    .foregroundColor(.mumbleText)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .disabled(apiClient.isProcessing)
            .opacity(apiClient.isProcessing ? 0.5 : 1)
        }
    }

    private var toneButtonsView: some View {
        HStack(spacing: 6) {
            ForEach(ToneStyle.allCases) { style in
                Button(action: {
                    if selectedStyle != style {
                        selectedStyle = style
                        // Only re-polish if we already have polished text
                        if !apiClient.polishedText.isEmpty {
                            Task {
                                await apiClient.polishNote(speechRecognizer.transcript, style: style, authManager: authManager)
                            }
                        }
                    }
                }) {
                    Text(style.rawValue)
                        .font(.system(size: 12, weight: selectedStyle == style ? .semibold : .regular))
                        .foregroundColor(selectedStyle == style ? .mumbleBg : .mumbleTextMuted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedStyle == style ? Color.mumbleTeal : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedStyle == style ? Color.clear : Color.mumbleTextMuted.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(apiClient.isProcessing)
            }
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(apiClient.polishedText, forType: .string)
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showCopied = false
        }
    }

    // MARK: - History View

    private var historyView: some View {
        VStack {
            if notesStore.notes.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.mumbleTextMuted)
                    Text("No notes yet")
                        .foregroundColor(.mumbleTextMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(notesStore.notes) { note in
                            NoteRow(
                                note: note,
                                apiClient: apiClient,
                                onDelete: { notesStore.deleteNote(note) },
                                onContinue: {
                                    editingNote = note
                                    speechRecognizer.transcript = note.rawText
                                    apiClient.polishedText = note.polishedText
                                    if let style = ToneStyle.allCases.first(where: { $0.rawValue == note.style }) {
                                        selectedStyle = style
                                    }
                                    selectedTab = .record
                                },
                                onRepolish: { style in
                                    editingNote = note
                                    speechRecognizer.transcript = note.rawText
                                    if let toneStyle = ToneStyle.allCases.first(where: { $0.rawValue == style }) {
                                        selectedStyle = toneStyle
                                    }
                                    selectedTab = .record
                                    Task {
                                        await apiClient.polishNote(note.rawText, style: selectedStyle, authManager: authManager)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }

                Button("Clear History") {
                    notesStore.clearHistory()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red.opacity(0.8))
                .padding()
            }
        }
    }

    // MARK: - Settings View

    private var settingsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("ACCOUNT")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.mumbleTextMuted)
                        .tracking(0.5)

                    if authManager.isSignedIn {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Signed in as")
                                    .font(.system(size: 12))
                                    .foregroundColor(.mumbleTextMuted)
                                Text(authManager.userEmail ?? "Unknown")
                                    .font(.system(size: 14))
                                    .foregroundColor(.mumbleText)
                            }
                            Spacer()
                            Button("Sign Out") {
                                authManager.signOut()
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.red.opacity(0.8))
                            .buttonStyle(.borderless)
                        }
                        .padding(14)
                        .background(Color.mumbleBgLight)
                        .cornerRadius(10)
                    } else {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Sign in for free AI polishing (rate limited)")
                                .font(.system(size: 13))
                                .foregroundColor(.mumbleTextMuted)

                            HStack(spacing: 12) {
                                Button(action: { authManager.signIn(with: "google") }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "globe")
                                        Text("Google")
                                    }
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.mumbleText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.mumbleBg)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)

                                Button(action: { authManager.signIn(with: "github") }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                                        Text("GitHub")
                                    }
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.mumbleText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.mumbleBg)
                                    .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .background(Color.mumbleBgLight)
                        .cornerRadius(10)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("BRING YOUR OWN KEY")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.mumbleTextMuted)
                        .tracking(0.5)

                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $authManager.useBYOK) {
                            Text("Use my own OpenAI API key")
                                .font(.system(size: 13))
                                .foregroundColor(.mumbleText)
                        }
                        .toggleStyle(.switch)
                        .tint(.mumbleTeal)

                        if authManager.useBYOK {
                            SecureField("OpenAI API Key", text: Binding(
                                get: { authManager.openaiApiKey },
                                set: { authManager.openaiApiKey = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(10)
                            .background(Color.mumbleBg)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.mumbleTextMuted.opacity(0.3), lineWidth: 1)
                            )

                            Text("Get your API key from platform.openai.com")
                                .font(.system(size: 12))
                                .foregroundColor(.mumbleTextMuted)
                        }
                    }
                    .padding(14)
                    .background(Color.mumbleBgLight)
                    .cornerRadius(10)
                }

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit MumbleFish")
                        .font(.system(size: 13))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.borderless)
                .padding(.bottom, 8)
            }
            .padding()
        }
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: Note
    @ObservedObject var apiClient: APIClient
    let onDelete: () -> Void
    let onContinue: () -> Void
    let onRepolish: (String) -> Void

    @State private var showCopied = false
    @State private var isExpanded = false

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.polishedText, forType: .string)
        showCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showCopied = false
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(note.style)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.mumbleTeal)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.mumbleTeal.opacity(0.15))
                    .cornerRadius(4)

                Spacer()

                Text(note.createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(.mumbleTextMuted)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11))
                    .foregroundColor(.mumbleTextMuted)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            Text(note.polishedText)
                .font(.system(size: 14))
                .foregroundColor(.mumbleText)
                .lineLimit(isExpanded ? nil : 2)

            if isExpanded {
                Divider()
                    .background(Color.mumbleTextMuted.opacity(0.3))

                VStack(alignment: .leading, spacing: 6) {
                    Text("RAW")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.mumbleTextMuted)
                        .tracking(0.5)
                    Text(note.rawText)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(.mumbleTextMuted)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.mumbleBg)
                        .cornerRadius(6)
                }

                HStack(spacing: 10) {
                    Button(action: copyToClipboard) {
                        Label(showCopied ? "Copied!" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.mumbleTeal)

                    Button(action: onContinue) {
                        Label("Add More", systemImage: "plus.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.mumbleTeal)

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.borderless)
                }

                HStack(spacing: 6) {
                    Text("Repolish:")
                        .font(.system(size: 11))
                        .foregroundColor(.mumbleTextMuted)

                    ForEach(ToneStyle.allCases.filter { $0.rawValue != note.style }) { style in
                        Button(style.rawValue) {
                            onRepolish(style.rawValue)
                        }
                        .font(.system(size: 11))
                        .foregroundColor(.mumbleTextMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.mumbleBg)
                        .cornerRadius(4)
                        .buttonStyle(.plain)
                        .disabled(apiClient.isProcessing)
                    }
                }
            } else {
                // Collapsed quick actions
                HStack {
                    Button(action: copyToClipboard) {
                        Label(showCopied ? "Copied!" : "Copy", systemImage: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.mumbleTeal)

                    Spacer()

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundColor(.red.opacity(0.6))
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
        .padding(14)
        .background(Color.mumbleBgLight)
        .cornerRadius(10)
    }
}

// MARK: - Skeleton Loading View

struct SkeletonView: View {
    @State private var shimmerOffset: CGFloat = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SkeletonLine(width: 0.9)
            SkeletonLine(width: 0.7)
            SkeletonLine(width: 0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mask(
            LinearGradient(
                gradient: Gradient(colors: [
                    .black.opacity(0.4),
                    .black,
                    .black.opacity(0.4)
                ]),
                startPoint: UnitPoint(x: shimmerOffset - 0.3, y: 0.5),
                endPoint: UnitPoint(x: shimmerOffset + 0.3, y: 0.5)
            )
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2
            }
        }
    }
}

struct SkeletonLine: View {
    let width: CGFloat

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.mumbleTextMuted.opacity(0.3))
                .frame(width: geometry.size.width * width, height: 14)
        }
        .frame(height: 14)
    }
}

#Preview {
    ContentView()
        .environmentObject(NotesStore())
        .environmentObject(SpeechRecognizer())
        .environmentObject(AuthManager())
}
