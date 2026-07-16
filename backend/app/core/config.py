"""Application configuration loaded from environment / .env.

All settings are typed and validated by pydantic-settings. The repo-root `.env`
is read first (so a single env file powers the whole monorepo), then a local
`backend/.env` may override it.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=("../.env", ".env"),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # ───── App ─────
    app_name: str = "NotiqAI"
    environment: Literal["development", "staging", "production"] = "development"
    debug: bool = True
    api_v1_prefix: str = "/api/v1"
    backend_port: int = 8000
    cors_origins: str = "http://localhost:5173,http://localhost:3000"

    # ───── Mobile app version gate (forced / optional update) ─────
    # The mobile client hits `GET /app/version` on launch and compares its
    # current build to these. Bump them right before/after a Play Store
    # release; users on versions older than `min_supported_version` get a
    # non-dismissible update dialog.
    app_latest_version: str = "1.0.0"
    app_min_supported_version: str = "1.0.0"
    app_force_update: bool = False
    app_play_store_url: str = "https://play.google.com/store/apps/details?id=uz.najotnur.notiqai"
    app_update_message_uz: str = ""
    app_update_message_ru: str = ""
    app_update_message_en: str = ""

    # ───── PostgreSQL ─────
    postgres_user: str = "notiq"
    postgres_password: str = "notiq_dev_password"
    postgres_db: str = "notiqai"
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    database_url: str | None = None

    # ───── Redis ─────
    redis_url: str = "redis://localhost:6379/0"

    # ───── Auth / JWT ─────
    jwt_secret_key: str = "change_me_to_a_long_random_secret"
    jwt_algorithm: str = "HS256"

    # Token lifetimes, per role. All roles get a short access token plus a
    # long, sliding refresh token (rotated on every /refresh call — see
    # auth.py) so an active session practically never re-logins. Admin/
    # curator access tokens are shorter-lived than mobile's since a
    # compromised staff credential has a bigger blast radius.
    access_token_expire_minutes_user: int = 30
    refresh_token_expire_days_user: int = 90
    access_token_expire_minutes_curator: int = 20
    refresh_token_expire_days_curator: int = 30
    access_token_expire_minutes_admin: int = 15
    refresh_token_expire_days_admin: int = 30

    otp_ttl_seconds: int = 120
    otp_length: int = 6

    # ───── OAuth ─────
    google_client_id: str = ""
    google_client_secret: str = ""

    # ───── Telegram Verification Codes ─────
    # Telegram's official auth flow: when a user starts registration or
    # password reset, we call `auth.sendCode` via Telethon and Telegram sends
    # a 6-digit code to the user's "Verification Codes" chat. No custom bot
    # is required.
    #
    # Register an app at https://my.telegram.org to get api_id / api_hash,
    # then run `python -m app.scripts.telegram_login` once to produce
    # TELEGRAM_SESSION.
    telegram_api_id: int = 0
    telegram_api_hash: str = ""
    telegram_session: str = ""

    # ───── SMS ─────
    sms_provider: Literal["mock", "eskiz", "playmobile"] = "mock"
    sms_api_url: str = ""
    sms_api_token: str = ""
    eskiz_sender: str = "NOTIQLIK.UZ"
    # Eskiz credentials (token auto-refreshed on startup when provider=eskiz)
    eskiz_email: str = ""
    eskiz_password: str = ""

    # ───── AI ─────
    anthropic_api_key: str = ""
    ai_model: str = "claude-opus-4-8"
    # Gemini (Google) — used when AI_PROVIDER=gemini or AI_PROVIDER=dual
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash"
    # Override the base URL if you go through a proxy (OpenRouter, LiteLLM, …)
    gemini_base_url: str = "https://generativelanguage.googleapis.com/v1beta"
    # Groq LLM — used when AI_PROVIDER=groq or AI_PROVIDER=dual
    # Same groq_api_key serves both STT (Whisper) and LLM (Llama)
    # llama-3.3-70b: strong Uzbek, and (unlike qwen3-32b) enabled on our
    # Groq project — a blocked primary costs one wasted round-trip per call.
    groq_llm_model: str = "llama-3.3-70b-versatile"
    # AI_PROVIDER controls which LLM backend runs the analysis prompts:
    #   mock  — no LLM, fully deterministic fallback
    #   groq  — Groq Llama (fast, cheap, good Uzbek)
    #   gemini — Google Gemini (rich coaching, schema-enforced)
    #   dual  — Groq + Gemini in parallel, results merged (best quality)
    #   claude — Anthropic Claude (legacy)
    ai_provider: Literal["mock", "claude", "gemini", "groq", "dual"] = "mock"
    stt_provider: Literal["mock", "groq", "openai_whisper", "google"] = "mock"
    stt_api_key: str = ""
    # Groq — both STT (Whisper) and LLM (Llama) use the same API key.
    groq_api_key: str = ""
    groq_stt_model: str = "whisper-large-v3"
    groq_base_url: str = "https://api.groq.com/openai/v1"
    # Default transcription language ("uz" | "ru" | "en"); per-request override.
    stt_language: str = "uz"
    stt_max_audio_mb: int = 50

    # Quiz intro video max size in MB.
    quiz_video_max_mb: int = 200

    # ───── AMOCRM ─────
    amocrm_base_url: str = ""
    amocrm_access_token: str = ""
    amocrm_pipeline_id: str = ""
    amocrm_responsible_user_id: str = ""

    # ───── Storage ─────
    s3_endpoint: str = ""
    s3_region: str = "us-east-1"
    s3_bucket: str = "notiqai-media"
    s3_access_key: str = ""
    s3_secret_key: str = ""
    local_media_dir: str = "./media"

    # ───── Payments ─────
    uzum_merchant_id: str = ""
    uzum_secret_key: str = ""
    # Uzum Nasiya Partner API — Bearer token issued by the Uzum Nasiya manager
    # when the partner is onboarded. Base URL switches between the sandbox
    # (https://dev-merchants-api.uzumnasiya.uz) and production
    # (https://merchants-api.uzumnasiya.uz).
    uzum_nasiya_api_key: str = ""
    uzum_nasiya_base_url: str = "https://merchants-api.uzumnasiya.uz"
    atmos_store_id: str = ""
    atmos_consumer_key: str = ""
    atmos_consumer_secret: str = ""

    # ───── Monitoring ─────
    sentry_dsn: str = ""
    metrics_enabled: bool = True

    # ───── Security ─────
    rate_limit_default: int = 240
    rate_limit_window: int = 60
    brute_force_max_attempts: int = 15
    brute_force_window: int = 300
    cors_allow_private_network: bool = False

    # ───── Push notifications (FCM) ─────
    # Set FCM_ENABLED=true and point FCM_SERVICE_ACCOUNT_PATH to a Firebase
    # service-account JSON to deliver real pushes via Firebase Cloud Messaging.
    # Until then the push endpoint is a no-op and only writes to the DB
    # (mobile still receives the message through /users/me/notifications).
    fcm_enabled: bool = False
    fcm_service_account_path: str = "./secrets/firebase-service-account.json"
    fcm_project_id: str = ""

    # ───── Derived ─────
    @computed_field  # type: ignore[prop-decorator]
    @property
    def sqlalchemy_database_uri(self) -> str:
        if self.database_url:
            return self.database_url
        return (
            f"postgresql+asyncpg://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )

    @computed_field  # type: ignore[prop-decorator]
    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def is_production(self) -> bool:
        return self.environment == "production"

    @property
    def ai_enabled(self) -> bool:
        if self.ai_provider == "gemini":
            return bool(self.gemini_api_key)
        if self.ai_provider == "claude":
            return bool(self.anthropic_api_key)
        if self.ai_provider == "groq":
            return bool(self.effective_groq_key)
        if self.ai_provider == "dual":
            return bool(self.effective_groq_key) or bool(self.gemini_api_key)
        return False

    @property
    def groq_enabled(self) -> bool:
        return bool(self.effective_groq_key) and self.ai_provider in ("groq", "dual")

    @property
    def gemini_enabled(self) -> bool:
        return bool(self.gemini_api_key) and self.ai_provider in ("gemini", "dual")

    @property
    def effective_groq_key(self) -> str:
        """Groq key from GROQ_API_KEY, falling back to the generic STT_API_KEY."""
        return self.groq_api_key or self.stt_api_key

    @property
    def stt_enabled(self) -> bool:
        """True when a real server-side STT provider is configured."""
        if self.stt_provider == "groq":
            return bool(self.effective_groq_key)
        if self.stt_provider in ("openai_whisper", "google"):
            return bool(self.stt_api_key)
        return False

    @property
    def fcm_configured(self) -> bool:
        """True only when FCM is enabled AND a service-account file exists."""
        import os

        if not self.fcm_enabled or not self.fcm_service_account_path:
            return False
        return os.path.isfile(self.fcm_service_account_path)


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
