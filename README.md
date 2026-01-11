# mumble.fish

A macOS menu bar app that turns your voice notes into polished text using AI.

**Dictate. Polish. Done.**

## Overview

mumble.fish is a simple productivity tool that lives in your menu bar. Record a quick voice note, and AI will clean it up in your preferred tone—casual, professional, formal, friendly, or concise.

- **Voice to Text**: Native macOS speech recognition (no internet required for transcription)
- **AI Polish**: Clean up notes with GPT-5 nano via hosted API or bring your own key
- **Privacy First**: Notes stored locally, BYOK option for complete control
- **Always Accessible**: One click away in your menu bar

## Project Structure

| Directory                        | Description                         |
| -------------------------------- | ----------------------------------- |
| [app/MumbleFish](app/MumbleFish) | Swift macOS menu bar app            |
| [worker](worker)                 | Cloudflare Worker (auth + AI proxy) |
| [web](web)                       | React landing page                  |

## Quick Start

### Prerequisites

- macOS 13.0+
- Xcode 15+ (for Swift app)
- Rust + wrangler CLI (for worker)
- Node.js 18+ (for web)

### Development

**Worker:**

```bash
cd worker
wrangler dev
```

**Web:**

```bash
cd web
npm install
npm run dev
```

**App:**

```bash
cd app/MumbleFish
xcodegen generate
open MumbleFish.xcodeproj
# Build and run in Xcode
```

## Deployment

See individual READMEs for deployment instructions:

- [App](app/MumbleFish/README.md#build-from-command-line)
- [Worker](worker/README.md)
- [Web](web/README.md)

## Architecture

```
┌─────────────────┐     ┌─────────────────────────────────┐     ┌─────────────────┐
│  MumbleFish.app │────▶│  mumble.fish (CF Worker)        │────▶│  OpenAI API     │
│  (macOS)        │     │  ├─ /api/v1/auth/* (OAuth)      │     └─────────────────┘
└─────────────────┘     │  ├─ /api/v1/polish (AI proxy)   │
                        │  └─ /* (SPA assets)             │
                        └─────────────────────────────────┘

Hosted mode:  App sends Bearer token → Worker uses hosted OpenAI key
BYOK mode:    App sends X-OpenAI-Key header → Worker forwards user's key
```

## License

MIT
