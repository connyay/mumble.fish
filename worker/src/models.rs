use serde::{Deserialize, Serialize};

#[derive(Serialize)]
pub struct ApiResponse<T: Serialize> {
    pub success: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub data: Option<T>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

impl<T: Serialize> ApiResponse<T> {
    pub fn success(data: T) -> Self {
        Self {
            success: true,
            data: Some(data),
            error: None,
        }
    }

    pub fn error(message: impl Into<String>) -> ApiResponse<()> {
        ApiResponse {
            success: false,
            data: None,
            error: Some(message.into()),
        }
    }
}

#[derive(Deserialize)]
pub struct AuthCredentials {
    pub email: String,
    pub password: String,
}

#[derive(Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: UserInfo,
}

#[derive(Serialize, Deserialize)]
pub struct UserInfo {
    pub id: String,
    pub email: String,
}

#[derive(Serialize, Deserialize)]
pub struct TokenClaims {
    pub sub: String, // user_id
    pub exp: i64,    // expiry timestamp
}

#[derive(Deserialize)]
pub struct PolishRequest {
    pub text: String,
    pub tone: ToneStyle,
}

#[derive(Deserialize, Clone, Copy)]
#[serde(rename_all = "lowercase")]
pub enum ToneStyle {
    Casual,
    Professional,
    Formal,
    Friendly,
    Concise,
}

impl ToneStyle {
    pub fn system_prompt(&self) -> &'static str {
        match self {
            ToneStyle::Casual => {
                "Rewrite this dictated note in a casual, conversational tone. Fix any grammar issues and make it flow naturally, but keep it relaxed and informal. Return ONLY the rewritten text, no preamble or explanation."
            }
            ToneStyle::Professional => {
                "Rewrite this dictated note in a professional tone suitable for work communication. Fix grammar, improve clarity, and make it polished but not overly formal. Return ONLY the rewritten text, no preamble or explanation."
            }
            ToneStyle::Formal => {
                "Rewrite this dictated note in a formal tone suitable for official correspondence. Use proper grammar, professional vocabulary, and a respectful tone. Return ONLY the rewritten text, no preamble or explanation."
            }
            ToneStyle::Friendly => {
                "Rewrite this dictated note in a warm, friendly tone. Keep the message approachable and personable while fixing any grammar or clarity issues. Return ONLY the rewritten text, no preamble or explanation."
            }
            ToneStyle::Concise => {
                "Rewrite this dictated note to be as concise as possible. Remove filler words, tighten the language, and get straight to the point while preserving the core message. Return ONLY the rewritten text, no preamble or explanation."
            }
        }
    }
}

#[derive(Serialize)]
pub struct PolishResponse {
    pub polished: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_api_response_success() {
        let response = ApiResponse::success("test data");
        assert!(response.success);
        assert_eq!(response.data, Some("test data"));
        assert!(response.error.is_none());
    }

    #[test]
    fn test_api_response_success_serialization() {
        let response = ApiResponse::success(42);
        let json = serde_json::to_string(&response).unwrap();

        assert!(json.contains("\"success\":true"));
        assert!(json.contains("\"data\":42"));
        assert!(!json.contains("\"error\""));
    }

    #[test]
    fn test_api_response_error() {
        let response = ApiResponse::<()>::error("something went wrong");
        assert!(!response.success);
        assert!(response.data.is_none());
        assert_eq!(response.error, Some("something went wrong".to_string()));
    }

    #[test]
    fn test_api_response_error_serialization() {
        let response = ApiResponse::<()>::error("bad request");
        let json = serde_json::to_string(&response).unwrap();

        assert!(json.contains("\"success\":false"));
        assert!(json.contains("\"error\":\"bad request\""));
        assert!(!json.contains("\"data\""));
    }

    #[test]
    fn test_api_response_error_from_string() {
        let msg = String::from("dynamic error");
        let response = ApiResponse::<()>::error(msg);
        assert_eq!(response.error, Some("dynamic error".to_string()));
    }

    #[test]
    fn test_tone_style_casual_prompt() {
        let prompt = ToneStyle::Casual.system_prompt();
        assert!(prompt.contains("casual"));
        assert!(prompt.contains("conversational"));
        assert!(prompt.contains("ONLY the rewritten text"));
    }

    #[test]
    fn test_tone_style_professional_prompt() {
        let prompt = ToneStyle::Professional.system_prompt();
        assert!(prompt.contains("professional"));
        assert!(prompt.contains("work"));
        assert!(prompt.contains("ONLY the rewritten text"));
    }

    #[test]
    fn test_tone_style_formal_prompt() {
        let prompt = ToneStyle::Formal.system_prompt();
        assert!(prompt.contains("formal"));
        assert!(prompt.contains("official"));
        assert!(prompt.contains("ONLY the rewritten text"));
    }

    #[test]
    fn test_tone_style_friendly_prompt() {
        let prompt = ToneStyle::Friendly.system_prompt();
        assert!(prompt.contains("friendly"));
        assert!(prompt.contains("warm"));
        assert!(prompt.contains("ONLY the rewritten text"));
    }

    #[test]
    fn test_tone_style_concise_prompt() {
        let prompt = ToneStyle::Concise.system_prompt();
        assert!(prompt.contains("concise"));
        assert!(prompt.contains("filler"));
        assert!(prompt.contains("ONLY the rewritten text"));
    }

    #[test]
    fn test_all_tones_have_unique_prompts() {
        let tones = [
            ToneStyle::Casual,
            ToneStyle::Professional,
            ToneStyle::Formal,
            ToneStyle::Friendly,
            ToneStyle::Concise,
        ];

        let prompts: Vec<&str> = tones.iter().map(|t| t.system_prompt()).collect();

        for i in 0..prompts.len() {
            for j in (i + 1)..prompts.len() {
                assert_ne!(prompts[i], prompts[j], "All tone prompts should be unique");
            }
        }
    }

    #[test]
    fn test_tone_style_deserialization() {
        let json = r#"{"text": "hello", "tone": "casual"}"#;
        let req: PolishRequest = serde_json::from_str(json).unwrap();
        assert!(matches!(req.tone, ToneStyle::Casual));

        let json = r#"{"text": "hello", "tone": "professional"}"#;
        let req: PolishRequest = serde_json::from_str(json).unwrap();
        assert!(matches!(req.tone, ToneStyle::Professional));

        let json = r#"{"text": "hello", "tone": "formal"}"#;
        let req: PolishRequest = serde_json::from_str(json).unwrap();
        assert!(matches!(req.tone, ToneStyle::Formal));

        let json = r#"{"text": "hello", "tone": "friendly"}"#;
        let req: PolishRequest = serde_json::from_str(json).unwrap();
        assert!(matches!(req.tone, ToneStyle::Friendly));

        let json = r#"{"text": "hello", "tone": "concise"}"#;
        let req: PolishRequest = serde_json::from_str(json).unwrap();
        assert!(matches!(req.tone, ToneStyle::Concise));
    }

    #[test]
    fn test_token_claims_serialization_roundtrip() {
        let claims = TokenClaims {
            sub: "user-123".to_string(),
            exp: 1700000000,
        };

        let json = serde_json::to_string(&claims).unwrap();
        let parsed: TokenClaims = serde_json::from_str(&json).unwrap();

        assert_eq!(parsed.sub, "user-123");
        assert_eq!(parsed.exp, 1700000000);
    }
}
