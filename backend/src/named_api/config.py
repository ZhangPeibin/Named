from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "Named API"
    app_env: str = "development"
    api_v1_prefix: str = "/api/v1"
    database_url: str = "mysql+asyncmy://named:named@127.0.0.1:3306/named?charset=utf8mb4"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")


@lru_cache
def get_settings() -> Settings:
    return Settings()
