import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost/hr_system")


def normalize_database_url(database_url: str) -> str:
    # Some providers expose postgres:// which SQLAlchemy may not parse correctly.
    if database_url.startswith("postgres://"):
        database_url = database_url.replace("postgres://", "postgresql://", 1)

    # Only add SSL on Railway (or when FORCE_SSL env var is set)
    is_railway = os.getenv("RAILWAY_ENVIRONMENT") or os.getenv("FORCE_SSL")
    if (
        is_railway
        and database_url.startswith("postgresql://")
        and "sslmode=" not in database_url
    ):
        separator = "&" if "?" in database_url else "?"
        database_url = f"{database_url}{separator}sslmode=require"

    return database_url


DATABASE_URL = normalize_database_url(DATABASE_URL)

# Use pool_pre_ping to detect and recover from stale connections
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=1800,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
