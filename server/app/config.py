import os
from pathlib import Path
from pydantic import BaseModel

BASE_DIR = Path(__file__).resolve().parent.parent

class Settings(BaseModel):
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8080"))
    DATABASE_PATH: str = os.getenv("DATABASE_PATH", str(BASE_DIR / "dashboard.db"))
    API_KEY: str = os.getenv("API_KEY", "stupid-dashboard-local-key")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "production")
    CORS_ORIGINS: list[str] = ["*"]

settings = Settings()
