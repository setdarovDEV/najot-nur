"""Application configuration loaded from environment / .env.

All settings are typed and validated by pydantic-settings. The repo-root `.env`
is read first (so a single env file powers the whole monorepo), then a local
`backend/.env` may override it.
"""
from __future__ import annotations

from functools import lru_cache
from typing import Literal

from pydantic import Field, computed_field
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
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 14
    otp_ttl_seconds: int = 120
    otp_length: int = 6

    # ───── OAuth ─────
    google_client_id: str = ""
    google_client_secret: str = ""
    telegram_bot_token: str = ""
    telegram_bot_username: str = ""

    # ───── OTP delivery ─────
    # telegram → OTP Telegram bot orqali yuboriladi (foydalanuvchi avval botni ishlatgan bo'lishi kerak)
    # sms      → SMS gateway orqali yuboriladi
    otp_provider: Literal["sms", "telegram"] = "sms"

    # ───── SMS ─────
    sms_provider: Literal["mock", "eskiz", "playmobile"] = "mock"
    sms_api_url: str = ""
    sms_api_token: str = ""
    sms_sender: str = "NotiqAI"
    # Eskiz credentials (token auto-refreshed on startup when provider=eskiz)
    eskiz_email: str = ""
    eskiz_password: str = ""

    # ───── AI ─────
    anthropic_api_key: str = ""
    ai_model: str = "claude-opus-4-8"
    # Gemini (Google) — used when AI_PROVIDER=gemini or AI_PROVIDER=dual
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.5-flash-preview-05-20"
    # Override the base URL if you go through a proxy (OpenRouter, LiteLLM, …)
    gemini_base_url: str = "https://generativelanguage.googleapis.com/v1beta"
    # Groq LLM — used when AI_PROVIDER=groq or AI_PROVIDER=dual
    # Same groq_api_key serves both STT (Whisper) and LLM (Llama)
    groq_llm_model: str = "qwen/qwen3-32b"
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

    # ───── Payments (later) ─────
    uzum_merchant_id: str = ""
    uzum_secret_key: str = ""
    uzum_nasiya_api_key: str = ""
    atmos_store_id: str = ""
    atmos_consumer_key: str = ""
    atmos_consumer_secret: str = ""

    # ───── Monitoring ─────
    sentry_dsn: str = ""

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
