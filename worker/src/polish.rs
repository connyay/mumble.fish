use crate::auth::extract_and_verify_token;
use crate::models::{ApiResponse, PolishRequest, PolishResponse};
use worker::*;

/// Max input length for hosted API (~10 mins of speech, ~2000 tokens)
const MAX_TEXT_LENGTH_HOSTED: usize = 8000;

pub async fn polish(mut req: Request, ctx: RouteContext<()>) -> Result<Response> {
    let byok_key = req.headers().get("X-OpenAI-Key")?;

    let (api_key, is_byok) = match byok_key {
        Some(key) => (key, true),
        None => {
            match extract_and_verify_token(&req, &ctx) {
                Ok(user_id) => {
                    let rate_limiter = ctx.rate_limiter("RATE_LIMIT")?;
                    let outcome = rate_limiter.limit(user_id).await?;
                    if !outcome.success {
                        return Response::from_json(&ApiResponse::<()>::error(
                            "Rate limit exceeded",
                        ))
                        .map(|r| r.with_status(429));
                    }
                }
                Err(e) => {
                    return Response::from_json(&ApiResponse::<()>::error(format!(
                        "Authentication required: {}. Use X-OpenAI-Key header for BYOK mode.",
                        e
                    )))
                    .map(|r| r.with_status(401));
                }
            }

            let key = ctx
                .env
                .secret("OPENAI_API_KEY")
                .map(|k| k.to_string())
                .map_err(|_| {
                    Error::RustError("OpenAI API key not configured on server".to_string())
                })?;

            (key, false)
        }
    };

    let body: PolishRequest = match req.json().await {
        Ok(b) => b,
        Err(_) => {
            return Response::from_json(&ApiResponse::<()>::error("Invalid request body"))
                .map(|r| r.with_status(400));
        }
    };

    let trimmed_text = body.text.trim();
    if trimmed_text.is_empty() {
        return Response::from_json(&ApiResponse::<()>::error("Text cannot be empty"))
            .map(|r| r.with_status(400));
    }

    // Enforce length limit for hosted API (BYOK has no limit)
    if !is_byok && trimmed_text.len() > MAX_TEXT_LENGTH_HOSTED {
        return Response::from_json(&ApiResponse::<()>::error(format!(
            "Text too long ({} chars). Maximum is {} chars (~10 mins of speech). Use your own API key for longer texts.",
            trimmed_text.len(),
            MAX_TEXT_LENGTH_HOSTED
        )))
        .map(|r| r.with_status(400));
    }

    let polished = match call_openai(&api_key, &body).await {
        Ok(text) => text,
        Err(e) => {
            console_error!("OpenAI error: {:?}", e);
            return Response::from_json(&ApiResponse::<()>::error(format!(
                "AI processing failed: {}",
                e
            )))
            .map(|r| r.with_status(500));
        }
    };

    Response::from_json(&ApiResponse::success(PolishResponse { polished }))
}

async fn call_openai(api_key: &str, request: &PolishRequest) -> Result<String> {
    let headers = Headers::new();
    headers.set("Content-Type", "application/json")?;
    headers.set("Authorization", &format!("Bearer {}", api_key))?;

    // Using gpt-5-nano-2025-08-07 for fast, cost-effective text polishing
    let openai_request = serde_json::json!({
        "model": "gpt-5-nano-2025-08-07",
        "messages": [
            {
                "role": "system",
                "content": request.tone.system_prompt()
            },
            {
                "role": "user",
                "content": request.text
            }
        ]
    });

    let mut init = RequestInit::new();
    init.with_method(Method::Post);
    init.with_headers(headers);
    init.with_body(Some(serde_json::to_string(&openai_request)?.into()));

    let req = Request::new_with_init("https://api.openai.com/v1/chat/completions", &init)?;
    let mut resp = Fetch::Request(req).send().await?;

    if resp.status_code() != 200 {
        let error_text = resp.text().await?;
        return Err(Error::RustError(format!(
            "OpenAI API error ({}): {}",
            resp.status_code(),
            error_text
        )));
    }

    let response_data: serde_json::Value = resp.json().await?;

    let content = response_data["choices"][0]["message"]["content"]
        .as_str()
        .ok_or_else(|| Error::RustError("No content in response".to_string()))?
        .to_string();

    Ok(content)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_max_text_length_hosted_constant() {
        // ~8000 chars = ~2000 tokens = ~10 mins of speech
        assert_eq!(MAX_TEXT_LENGTH_HOSTED, 8000);
    }

    #[test]
    fn test_max_text_length_reasonable_range() {
        // Should be at least 1000 chars (reasonable minimum for text polishing)
        assert!(MAX_TEXT_LENGTH_HOSTED >= 1000);
        // Should be at most 50000 chars (reasonable max to prevent abuse)
        assert!(MAX_TEXT_LENGTH_HOSTED <= 50000);
    }
}
