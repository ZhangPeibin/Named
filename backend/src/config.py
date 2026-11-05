from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Named API"
    app_env: str = "development"
    api_v1_prefix: str = "/api/v1"
    database_url: str = "mysql+asyncmy://named:named@127.0.0.1:3306/named?charset=utf8mb4"

    auth_secret: str = "dev-only-change-me"
    auth_code_ttl_seconds: int = 600
    auth_code_resend_cooldown_seconds: int = 60
    auth_code_max_attempts: int = 5
    auth_code_max_per_hour: int = 10
    auth_session_ttl_days: int = 30
    auth_dev_log_codes: bool = False

    ai_model: str = "deepseek:deepseek-flash"
    ai_prompt_version: str = "discover-v1"
    deepseek_api_key: str | None = None
    openai_api_key: str | None = None

    dashscope_api_key: str | None = None
    dashscope_workspace: str | None = None
    dashscope_region: str = "cn-beijing"
    dashscope_websocket_url: str | None = None
    tts_model: str = "qwen-audio-3.1-tts-plus"
    tts_voice_us: str = "longanfengyue_v3.1"
    tts_voice_uk: str = "longanfengyue_v3.1"
    tts_voice_talk: str = "longanfengyue_v3.1"
    tts_format: str = "mp3"
    tts_rate: float = 1.0
    talk_audio_ttl_seconds: int = 604800
    media_root: str = "media"
    media_url_prefix: str = "/api/v1/audio"
    image_url_prefix: str = "/api/v1/images"
    image_max_bytes: int = 10 * 1024 * 1024
    image_max_dimension: int = 2048
    rate_limit_discover_per_minute: int = 30
    rate_limit_talk_per_minute: int = 60

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
