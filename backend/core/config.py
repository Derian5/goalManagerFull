from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    PROJECT_NAME: str = "My App"
    VERSION: str = "0.1.0"
    BACKEND_CORS_ORIGINS: List[str] = ["*"]

    SECRET_KEY: str = "change-me"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 дней
    #jdbc: postgresql: // localhost: 5432 / postgres
    #postgresql+asyncpg://admin:password@localhost/goalTaskManager
    DATABASE_URL: str = "postgresql+asyncpg://admin:password@db:5432/goalTaskManager"

    class Config:
        env_file = ".env"

settings = Settings()
