import os
from pathlib import Path
from dotenv import load_dotenv

# Base directory for the backend
BASE_DIR = Path(__file__).resolve().parent

# Load environment variables from .env file
load_dotenv(BASE_DIR / ".env")

class Config:
    """Central configuration class for CampusTrack Flask application."""
    
    # Flask settings
    SECRET_KEY = os.getenv("SECRET_KEY", "campustrack-secret-key-2026-secure")
    FLASK_ENV = os.getenv("FLASK_ENV", "development")
    DEBUG = os.getenv("FLASK_DEBUG", "1") == "1"
    PORT = int(os.getenv("PORT", 5000))
    HOST = os.getenv("HOST", "0.0.0.0")

    # MongoDB settings (never hardcoded, loaded from .env)
    MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
    MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "campustrack")
    
    # PyMongo client options
    MONGO_CONNECT_TIMEOUT_MS = int(os.getenv("MONGO_CONNECT_TIMEOUT_MS", 5000))
    MONGO_SERVER_SELECTION_TIMEOUT_MS = int(os.getenv("MONGO_SERVER_SELECTION_TIMEOUT_MS", 5000))

    # JWT Authentication settings
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "campustrack-jwt-secret-key-production-grade-2026")
    JWT_EXPIRATION_HOURS = int(os.getenv("JWT_EXPIRATION_HOURS", 24))

    # Email Service Configuration (SMTP / Brevo / Resend)
    MAIL_SERVER = os.getenv("MAIL_SERVER", "")
    MAIL_PORT = int(os.getenv("MAIL_PORT", 587))
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "1").lower() in ("1", "true", "yes")
    MAIL_USERNAME = os.getenv("MAIL_USERNAME", "")
    MAIL_PASSWORD = os.getenv("MAIL_PASSWORD", "")
    MAIL_DEFAULT_SENDER = os.getenv("MAIL_DEFAULT_SENDER", "CampusTrack Academic Portal <noreply@campustrack.edu>")
    FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:5000")
    BREVO_API_KEY = os.getenv("BREVO_API_KEY", "")
    RESEND_API_KEY = os.getenv("RESEND_API_KEY", "")
