use crate::models::{ApiResponse, AuthCredentials, AuthResponse, TokenClaims, UserInfo};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier, password_hash::SaltString};
use base64::{Engine, engine::general_purpose::URL_SAFE_NO_PAD};
use hmac::{Hmac, Mac};
use rand::rngs::OsRng;
use sha2::Sha256;
use worker::*;

type HmacSha256 = Hmac<Sha256>;

pub async fn register(mut req: Request, ctx: RouteContext<()>) -> Result<Response> {
    let body: AuthCredentials = match req.json().await {
        Ok(b) => b,
        Err(_) => {
            return Response::from_json(&ApiResponse::<()>::error("Invalid request body"))
                .map(|r| r.with_status(400));
        }
    };

    if !body.email.contains('@') {
        return Response::from_json(&ApiResponse::<()>::error("Invalid email format"))
            .map(|r| r.with_status(400));
    }

    if body.password.len() < 8 {
        return Response::from_json(&ApiResponse::<()>::error(
            "Password must be at least 8 characters",
        ))
        .map(|r| r.with_status(400));
    }

    let db = ctx.env.d1("DB")?;
    let user_id = uuid::Uuid::new_v4().to_string();
    let now = chrono::Utc::now().timestamp() as f64; // D1 needs f64, not i64

    let password_hash = hash_password(&body.password)?;

    let existing = db
        .prepare("SELECT id FROM users WHERE email = ?1")
        .bind(&[body.email.clone().into()])?
        .first::<String>(Some("id"))
        .await?;

    if existing.is_some() {
        return Response::from_json(&ApiResponse::<()>::error("Email already registered"))
            .map(|r| r.with_status(409));
    }

    db.prepare("INSERT INTO users (id, email, password_hash, created_at) VALUES (?1, ?2, ?3, ?4)")
        .bind(&[
            user_id.clone().into(),
            body.email.clone().into(),
            password_hash.into(),
            now.into(),
        ])?
        .run()
        .await?;

    let token = generate_token(&user_id, &ctx)?;

    Response::from_json(&ApiResponse::success(AuthResponse {
        token,
        user: UserInfo {
            id: user_id,
            email: body.email,
        },
    }))
}

pub async fn login(mut req: Request, ctx: RouteContext<()>) -> Result<Response> {
    let body: AuthCredentials = match req.json().await {
        Ok(b) => b,
        Err(_) => {
            return Response::from_json(&ApiResponse::<()>::error("Invalid request body"))
                .map(|r| r.with_status(400));
        }
    };

    let db = ctx.env.d1("DB")?;

    let result = db
        .prepare("SELECT id, email, password_hash FROM users WHERE email = ?1")
        .bind(&[body.email.clone().into()])?
        .first::<serde_json::Value>(None)
        .await?;

    let user = match result {
        Some(u) => u,
        None => {
            return Response::from_json(&ApiResponse::<()>::error("Invalid credentials"))
                .map(|r| r.with_status(401));
        }
    };

    let stored_hash = user["password_hash"].as_str().unwrap_or("");

    if !verify_password(&body.password, stored_hash) {
        return Response::from_json(&ApiResponse::<()>::error("Invalid credentials"))
            .map(|r| r.with_status(401));
    }

    let user_id = user["id"].as_str().unwrap_or("").to_string();
    let email = user["email"].as_str().unwrap_or("").to_string();

    let token = generate_token(&user_id, &ctx)?;

    Response::from_json(&ApiResponse::success(AuthResponse {
        token,
        user: UserInfo { id: user_id, email },
    }))
}

pub async fn get_me(req: Request, ctx: RouteContext<()>) -> Result<Response> {
    let user_id = match extract_and_verify_token(&req, &ctx) {
        Ok(id) => id,
        Err(e) => {
            return Response::from_json(&ApiResponse::<()>::error(e)).map(|r| r.with_status(401));
        }
    };

    let db = ctx.env.d1("DB")?;

    let result = db
        .prepare("SELECT id, email FROM users WHERE id = ?1")
        .bind(&[user_id.into()])?
        .first::<serde_json::Value>(None)
        .await?;

    match result {
        Some(user) => Response::from_json(&ApiResponse::success(UserInfo {
            id: user["id"].as_str().unwrap_or("").to_string(),
            email: user["email"].as_str().unwrap_or("").to_string(),
        })),
        None => Response::from_json(&ApiResponse::<()>::error("User not found"))
            .map(|r| r.with_status(404)),
    }
}

fn get_query_param(url: &Url, key: &str) -> Option<String> {
    url.query_pairs()
        .find(|(k, _)| k == key)
        .map(|(_, v)| v.to_string())
}

pub async fn oauth_start(req: Request, ctx: RouteContext<()>) -> Result<Response> {
    let provider = ctx.param("provider").cloned().unwrap_or_default();

    let url = req.url()?;
    let redirect_uri = get_query_param(&url, "redirect_uri")
        .unwrap_or_else(|| "https://mumble.fish/auth/callback".to_string());

    let allowed = ctx.env.var("ALLOWED_REDIRECTS")?.to_string();
    let allowed_list: Vec<&str> = allowed.split(',').collect();

    if !allowed_list.contains(&redirect_uri.as_str()) {
        return Response::from_json(&ApiResponse::<()>::error("Invalid redirect_uri"))
            .map(|r| r.with_status(400));
    }

    let db = ctx.env.d1("DB")?;
    let now = chrono::Utc::now().timestamp() as f64;

    // Opportunistic cleanup: delete expired sessions
    if let Err(e) = db
        .prepare("DELETE FROM oauth_sessions WHERE expires_at < ?1")
        .bind(&[now.into()])?
        .run()
        .await
    {
        console_log!("Failed to cleanup expired OAuth sessions: {:?}", e);
    }

    let state = uuid::Uuid::new_v4().to_string();
    let expires_at = now + 600.0; // 10 minutes

    db.prepare("INSERT INTO oauth_sessions (state, provider, redirect_uri, expires_at) VALUES (?1, ?2, ?3, ?4)")
        .bind(&[
            state.clone().into(),
            provider.clone().into(),
            redirect_uri.into(),
            expires_at.into(),
        ])?
        .run()
        .await?;

    let oauth_url = match provider.as_str() {
        "google" => {
            let client_id = ctx.env.secret("GOOGLE_CLIENT_ID")?.to_string();
            format!(
                "https://accounts.google.com/o/oauth2/v2/auth?client_id={}&redirect_uri={}&response_type=code&scope=openid%20email%20profile&state={}",
                client_id,
                urlencoding::encode("https://mumble.fish/api/v1/auth/oauth/google/callback"),
                state
            )
        }
        "github" => {
            let client_id = ctx.env.secret("GITHUB_CLIENT_ID")?.to_string();
            format!(
                "https://github.com/login/oauth/authorize?client_id={}&redirect_uri={}&scope=user:email&state={}",
                client_id,
                urlencoding::encode("https://mumble.fish/api/v1/auth/oauth/github/callback"),
                state
            )
        }
        _ => {
            return Response::from_json(&ApiResponse::<()>::error("Unknown OAuth provider"))
                .map(|r| r.with_status(400));
        }
    };

    Response::redirect(Url::parse(&oauth_url)?)
}

pub async fn oauth_callback(req: Request, ctx: RouteContext<()>) -> Result<Response> {
    let provider = ctx.param("provider").cloned().unwrap_or_default();
    let url = req.url()?;

    let (code, state) = match (
        get_query_param(&url, "code"),
        get_query_param(&url, "state"),
    ) {
        (Some(c), Some(s)) => (c, s),
        _ => {
            return Response::from_json(&ApiResponse::<()>::error("Missing code or state"))
                .map(|r| r.with_status(400));
        }
    };

    let db = ctx.env.d1("DB")?;

    let session = db
        .prepare("SELECT redirect_uri, expires_at FROM oauth_sessions WHERE state = ?1 AND provider = ?2")
        .bind(&[state.clone().into(), provider.clone().into()])?
        .first::<serde_json::Value>(None)
        .await?;

    let session = match session {
        Some(s) => s,
        None => {
            return Response::from_json(&ApiResponse::<()>::error("Invalid or expired state"))
                .map(|r| r.with_status(400));
        }
    };

    let redirect_uri = session["redirect_uri"].as_str().unwrap_or("").to_string();
    let expires_at = session["expires_at"].as_f64().unwrap_or(0.0) as i64;

    if chrono::Utc::now().timestamp() > expires_at {
        return Response::from_json(&ApiResponse::<()>::error("OAuth session expired"))
            .map(|r| r.with_status(400));
    }

    // Delete the session (one-time use)
    db.prepare("DELETE FROM oauth_sessions WHERE state = ?1")
        .bind(&[state.into()])?
        .run()
        .await?;

    let (email, provider_id) = match provider.as_str() {
        "google" => exchange_google_code(&code, &ctx).await?,
        "github" => exchange_github_code(&code, &ctx).await?,
        _ => {
            return Response::from_json(&ApiResponse::<()>::error("Unknown provider"))
                .map(|r| r.with_status(400));
        }
    };

    // Static queries per provider - no dynamic SQL, no injection risk
    struct ProviderQueries {
        select: &'static str,
        update: &'static str,
        insert: &'static str,
    }

    let queries = match provider.as_str() {
        "google" => ProviderQueries {
            select: "SELECT id, email FROM users WHERE email = ?1 OR google_id = ?2",
            update: "UPDATE users SET google_id = ?1 WHERE id = ?2",
            insert: "INSERT INTO users (id, email, google_id, created_at) VALUES (?1, ?2, ?3, ?4)",
        },
        "github" => ProviderQueries {
            select: "SELECT id, email FROM users WHERE email = ?1 OR github_id = ?2",
            update: "UPDATE users SET github_id = ?1 WHERE id = ?2",
            insert: "INSERT INTO users (id, email, github_id, created_at) VALUES (?1, ?2, ?3, ?4)",
        },
        _ => unreachable!(), // Already validated above
    };

    let existing = db
        .prepare(queries.select)
        .bind(&[email.clone().into(), provider_id.clone().into()])?
        .first::<serde_json::Value>(None)
        .await?;

    let user_id = if let Some(user) = existing {
        let id = user["id"].as_str().unwrap_or("").to_string();
        db.prepare(queries.update)
            .bind(&[provider_id.into(), id.clone().into()])?
            .run()
            .await?;
        id
    } else {
        let id = uuid::Uuid::new_v4().to_string();
        let now = chrono::Utc::now().timestamp() as f64;
        db.prepare(queries.insert)
            .bind(&[
                id.clone().into(),
                email.clone().into(),
                provider_id.into(),
                now.into(),
            ])?
            .run()
            .await?;
        id
    };

    let token = generate_token(&user_id, &ctx)?;
    let mut final_url = Url::parse(&redirect_uri)?;
    final_url.query_pairs_mut().append_pair("token", &token);

    Response::redirect(final_url)
}

/// Hash a password using Argon2
fn hash_password(password: &str) -> Result<String> {
    let argon2 = Argon2::default();
    let salt = SaltString::generate(&mut OsRng);
    argon2
        .hash_password(password.as_bytes(), &salt)
        .map(|h| h.to_string())
        .map_err(|e| Error::RustError(format!("Password hashing failed: {}", e)))
}

/// Verify a password against a stored Argon2 hash
fn verify_password(password: &str, stored: &str) -> bool {
    let argon2 = Argon2::default();
    let Ok(parsed_hash) = PasswordHash::new(stored) else {
        return false;
    };
    argon2
        .verify_password(password.as_bytes(), &parsed_hash)
        .is_ok()
}

/// Generate a JWT-like token with HMAC-SHA256 signature
fn generate_token(user_id: &str, ctx: &RouteContext<()>) -> Result<String> {
    let secret = ctx
        .env
        .secret("JWT_SECRET")
        .map(|s| s.to_string())
        .map_err(|_| Error::RustError("JWT_SECRET not configured".to_string()))?;

    let claims = TokenClaims {
        sub: user_id.to_string(),
        exp: chrono::Utc::now().timestamp() + 86400 * 90, // 90 days
    };

    // Create JWT-like token: base64url(claims).base64url(hmac-sha256(claims))
    let claims_json = serde_json::to_string(&claims)?;
    let claims_b64 = URL_SAFE_NO_PAD.encode(&claims_json);

    let mut mac =
        HmacSha256::new_from_slice(secret.as_bytes()).expect("HMAC can take key of any size");
    mac.update(claims_b64.as_bytes());
    let signature = mac.finalize().into_bytes();
    let sig_b64 = URL_SAFE_NO_PAD.encode(signature);

    Ok(format!("{}.{}", claims_b64, sig_b64))
}

/// Extract and verify a JWT-like token from the Authorization header
pub fn extract_and_verify_token(
    req: &Request,
    ctx: &RouteContext<()>,
) -> std::result::Result<String, String> {
    let auth_header = req
        .headers()
        .get("Authorization")
        .map_err(|_| "Missing Authorization header")?
        .ok_or("Missing Authorization header")?;

    let token = auth_header
        .strip_prefix("Bearer ")
        .ok_or("Invalid Authorization header format")?;

    let secret = ctx
        .env
        .secret("JWT_SECRET")
        .map(|s| s.to_string())
        .map_err(|_| "JWT_SECRET not configured".to_string())?;

    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 2 {
        return Err("Invalid token format".to_string());
    }

    let mut mac =
        HmacSha256::new_from_slice(secret.as_bytes()).expect("HMAC can take key of any size");
    mac.update(parts[0].as_bytes());

    let expected_sig = URL_SAFE_NO_PAD
        .decode(parts[1])
        .map_err(|_| "Invalid signature encoding")?;

    mac.verify_slice(&expected_sig)
        .map_err(|_| "Invalid token signature")?;

    let claims_json = URL_SAFE_NO_PAD
        .decode(parts[0])
        .map_err(|_| "Invalid token encoding")?;
    let claims_str = String::from_utf8(claims_json).map_err(|_| "Invalid token encoding")?;

    let claims: TokenClaims =
        serde_json::from_str(&claims_str).map_err(|_| "Invalid token claims")?;

    if chrono::Utc::now().timestamp() > claims.exp {
        return Err("Token expired".to_string());
    }

    Ok(claims.sub)
}

async fn exchange_google_code(code: &str, ctx: &RouteContext<()>) -> Result<(String, String)> {
    let client_id = ctx.env.secret("GOOGLE_CLIENT_ID")?.to_string();
    let client_secret = ctx.env.secret("GOOGLE_CLIENT_SECRET")?.to_string();

    let token_url = "https://oauth2.googleapis.com/token";
    let headers = Headers::new();
    headers.set("Content-Type", "application/x-www-form-urlencoded")?;

    let body = format!(
        "code={}&client_id={}&client_secret={}&redirect_uri={}&grant_type=authorization_code",
        urlencoding::encode(code),
        urlencoding::encode(&client_id),
        urlencoding::encode(&client_secret),
        urlencoding::encode("https://mumble.fish/api/v1/auth/oauth/google/callback")
    );

    let mut init = RequestInit::new();
    init.with_method(Method::Post);
    init.with_headers(headers);
    init.with_body(Some(body.into()));

    let req = Request::new_with_init(token_url, &init)?;
    let mut resp = Fetch::Request(req).send().await?;
    let token_data: serde_json::Value = resp.json().await?;

    let access_token = token_data["access_token"]
        .as_str()
        .ok_or_else(|| Error::RustError("No access token".to_string()))?;

    let headers = Headers::new();
    headers.set("Authorization", &format!("Bearer {}", access_token))?;

    let mut init = RequestInit::new();
    init.with_headers(headers);

    let req = Request::new_with_init("https://www.googleapis.com/oauth2/v2/userinfo", &init)?;
    let mut resp = Fetch::Request(req).send().await?;
    let user_info: serde_json::Value = resp.json().await?;

    let email = user_info["email"]
        .as_str()
        .ok_or_else(|| Error::RustError("No email".to_string()))?
        .to_string();
    let google_id = user_info["id"]
        .as_str()
        .ok_or_else(|| Error::RustError("No Google ID".to_string()))?
        .to_string();

    Ok((email, google_id))
}

async fn exchange_github_code(code: &str, ctx: &RouteContext<()>) -> Result<(String, String)> {
    let client_id = ctx.env.secret("GITHUB_CLIENT_ID")?.to_string();
    let client_secret = ctx.env.secret("GITHUB_CLIENT_SECRET")?.to_string();

    let headers = Headers::new();
    headers.set("Content-Type", "application/x-www-form-urlencoded")?;
    headers.set("Accept", "application/json")?;

    let body = format!(
        "code={}&client_id={}&client_secret={}",
        urlencoding::encode(code),
        urlencoding::encode(&client_id),
        urlencoding::encode(&client_secret)
    );

    let mut init = RequestInit::new();
    init.with_method(Method::Post);
    init.with_headers(headers);
    init.with_body(Some(body.into()));

    let req = Request::new_with_init("https://github.com/login/oauth/access_token", &init)?;
    let mut resp = Fetch::Request(req).send().await?;
    let token_data: serde_json::Value = resp.json().await?;

    let access_token = token_data["access_token"]
        .as_str()
        .ok_or_else(|| Error::RustError("No access token".to_string()))?;

    let headers = Headers::new();
    headers.set("Authorization", &format!("Bearer {}", access_token))?;
    headers.set("User-Agent", "mumble.fish")?;

    let mut init = RequestInit::new();
    init.with_headers(headers.clone());

    let req = Request::new_with_init("https://api.github.com/user", &init)?;
    let mut resp = Fetch::Request(req).send().await?;
    let user_info: serde_json::Value = resp.json().await?;

    let github_id = user_info["id"]
        .as_i64()
        .ok_or_else(|| Error::RustError("No GitHub ID".to_string()))?
        .to_string();

    // Get email (might be private)
    let mut init = RequestInit::new();
    init.with_headers(headers);

    let req = Request::new_with_init("https://api.github.com/user/emails", &init)?;
    let mut resp = Fetch::Request(req).send().await?;
    let emails: Vec<serde_json::Value> = resp.json().await?;

    let email = emails
        .iter()
        .find(|e| e["primary"].as_bool() == Some(true))
        .and_then(|e| e["email"].as_str())
        .ok_or_else(|| Error::RustError("No primary email".to_string()))?
        .to_string();

    Ok((email, github_id))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hash_password_format() {
        let hash = hash_password("mypassword123").expect("hashing should succeed");

        // Argon2 hash format: $argon2id$v=19$m=...,t=...,p=...$salt$hash
        assert!(hash.starts_with("$argon2"), "Should be Argon2 format");
    }

    #[test]
    fn test_hash_password_unique_salts() {
        let hash1 = hash_password("samepassword").expect("hashing should succeed");
        let hash2 = hash_password("samepassword").expect("hashing should succeed");

        // Same password should produce different hashes due to random salt
        assert_ne!(hash1, hash2);
    }

    #[test]
    fn test_verify_password_correct() {
        let password = "correcthorse";
        let hash = hash_password(password).expect("hashing should succeed");

        assert!(verify_password(password, &hash));
    }

    #[test]
    fn test_verify_password_incorrect() {
        let hash = hash_password("originalpassword").expect("hashing should succeed");

        assert!(!verify_password("wrongpassword", &hash));
    }

    #[test]
    fn test_verify_password_empty() {
        let hash = hash_password("nonempty").expect("hashing should succeed");

        assert!(!verify_password("", &hash));
    }

    #[test]
    fn test_verify_password_invalid_format() {
        assert!(!verify_password("password", "invalidhash"));
        assert!(!verify_password("password", ""));
        assert!(!verify_password("password", "$argon2id$invalid"));
    }

    #[test]
    fn test_verify_password_special_characters() {
        let password = "p@$$w0rd!#%&*()";
        let hash = hash_password(password).expect("hashing should succeed");

        assert!(verify_password(password, &hash));
    }

    #[test]
    fn test_verify_password_unicode() {
        let password = "пароль密码🔐";
        let hash = hash_password(password).expect("hashing should succeed");

        assert!(verify_password(password, &hash));
    }
}
