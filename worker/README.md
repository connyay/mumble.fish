# mumble.fish Worker

Rust Cloudflare Worker handling authentication and AI proxy.

## Features

- **Auth**: Email/password + OAuth (Google, GitHub)
- **AI Proxy**: Proxies requests to OpenAI with rate limiting
- **BYOK Support**: Pass `X-OpenAI-Key` header to use your own key
- **SPA Hosting**: Serves the web landing page

## API Endpoints

### Auth

```
POST /api/v1/auth/register
POST /api/v1/auth/login
GET  /api/v1/auth/me
GET  /api/v1/auth/oauth/:provider
GET  /api/v1/auth/oauth/:provider/callback
```

### AI

```
POST /api/v1/polish
```

Request body:

```json
{
  "text": "your raw transcript",
  "tone": "professional"
}
```

Tones: `casual`, `professional`, `formal`, `friendly`, `concise`

### Health

```
GET /api/health
```

## Development

```bash
# Install wrangler if needed
npm install -g wrangler

# Create D1 database (first time only)
wrangler d1 create mumble-fish

# Update wrangler.toml with the database_id from above

# Start dev server
npm run dev
```

## Deployment

### 1. Create D1 Database

```bash
wrangler d1 create mumble-fish
```

Copy the `database_id` to `wrangler.toml`.

### 2. Set Secrets

```bash
wrangler secret put JWT_SECRET
wrangler secret put OPENAI_API_KEY
wrangler secret put GOOGLE_CLIENT_ID
wrangler secret put GOOGLE_CLIENT_SECRET
wrangler secret put GITHUB_CLIENT_ID
wrangler secret put GITHUB_CLIENT_SECRET
```

### 3. Deploy

```bash
npm run deploy
```

## OAuth Setup

### Google

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URI: `https://mumble.fish/api/v1/auth/oauth/google/callback`

### GitHub

1. Go to [GitHub Developer Settings](https://github.com/settings/developers)
2. Create new OAuth App
3. Set callback URL: `https://mumble.fish/api/v1/auth/oauth/github/callback`

## Environment Variables

| Variable               | Description                                 |
| ---------------------- | ------------------------------------------- |
| `JWT_SECRET`           | Secret for signing tokens                   |
| `OPENAI_API_KEY`       | OpenAI API key for hosted mode              |
| `GOOGLE_CLIENT_ID`     | Google OAuth client ID                      |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret                  |
| `GITHUB_CLIENT_ID`     | GitHub OAuth client ID                      |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth client secret                  |
| `ALLOWED_REDIRECTS`    | Comma-separated allowed OAuth redirect URIs |
