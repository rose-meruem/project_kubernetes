from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg://urlshortener:urlshortener@postgres:5432/urlshortener"
    app_name: str = "url-shortener-api"

    class Config:
        env_file = ".env"


settings = Settings()
