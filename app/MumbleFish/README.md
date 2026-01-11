# MumbleFish

macOS menu bar app for voice-to-polished-text.

## Features

- **Voice Recording**: Native macOS speech recognition
- **AI Polish**: Multiple tone styles (casual, professional, formal, friendly, concise)
- **Dual Mode**: Sign in for hosted API or bring your own OpenAI key
- **History**: Save and revisit past notes
- **Always Accessible**: Lives in your menu bar

## Requirements

- macOS 13.0+
- Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating project)

## Development

```bash
# Install XcodeGen if needed
brew install xcodegen

# Generate Xcode project
xcodegen generate

# Open in Xcode
open MumbleFish.xcodeproj

# Build and run (Cmd+R in Xcode)
```

## Build from Command Line

```bash
xcodebuild -scheme MumbleFish -configuration Release build
```

The app will be at:

```
~/Library/Developer/Xcode/DerivedData/MumbleFish-*/Build/Products/Release/MumbleFish.app
```

## Structure

```
MumbleFish/
├── Sources/
│   ├── MumbleFishApp.swift      # App entry point
│   ├── ContentView.swift        # Main UI (tabs, views)
│   ├── AuthManager.swift        # OAuth + token management
│   ├── APIClient.swift          # API calls (hosted + BYOK)
│   ├── SpeechRecognizer.swift   # Voice-to-text
│   ├── Note.swift               # Note model
│   └── NotesStore.swift         # Local persistence
├── Assets.xcassets/
├── project.yml                  # XcodeGen config
├── MumbleFish.entitlements
└── Info.plist
```

## Auth Flow

### Hosted Mode (Sign In)

1. User clicks "Sign in with Google/GitHub"
2. App opens browser to `https://mumble.fish/api/v1/auth/oauth/{provider}`
3. After OAuth, backend redirects to `mumblefish://auth/callback?token=xxx`
4. App catches URL scheme, stores token in Keychain
5. API calls use `Authorization: Bearer {token}` header

### BYOK Mode

1. User enters OpenAI API key in Settings
2. API calls go directly to OpenAI (no rate limits)
3. Key stored in macOS Keychain

## Data Storage

| Data       | Location                                              |
| ---------- | ----------------------------------------------------- |
| Auth token | Keychain (`fish.mumble.MumbleFish`)                   |
| OpenAI key | Keychain (`fish.mumble.MumbleFish`)                   |
| Notes      | `~/Library/Application Support/MumbleFish/notes.json` |

## Permissions

The app requests:

- **Microphone**: For voice recording
- **Speech Recognition**: For transcription
- **Network**: For API calls

## URL Scheme

Registered URL scheme: `mumblefish://`

Used for OAuth callbacks:

```
mumblefish://auth/callback?token=xxx
```

## Customization

To change the API endpoint, edit `APIClient.swift`:

```swift
private static let mumbleFishURL = "https://mumble.fish/api/v1/polish"
```

To change the OpenAI model, edit `APIClient.swift`:

```swift
model: "gpt-4.1-nano"
```
