use worker::*;

mod auth;
mod models;
mod polish;

#[event(fetch)]
async fn fetch(req: Request, env: Env, _ctx: Context) -> Result<Response> {
    console_error_panic_hook::set_once();

    Router::new()
        .get_async("/api/health", health)
        .post_async("/api/v1/auth/register", auth::register)
        .post_async("/api/v1/auth/login", auth::login)
        .get_async("/api/v1/auth/me", auth::get_me)
        .get_async("/api/v1/auth/oauth/:provider", auth::oauth_start)
        .get_async(
            "/api/v1/auth/oauth/:provider/callback",
            auth::oauth_callback,
        )
        .post_async("/api/v1/polish", polish::polish)
        .run(req, env)
        .await
}

async fn health(_req: Request, _ctx: RouteContext<()>) -> Result<Response> {
    Response::from_json(&serde_json::json!({
        "status": "ok"
    }))
}
