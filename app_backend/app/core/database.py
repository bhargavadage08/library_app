import os
from typing import Generator
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker, Session
from .config import settings

load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL") or settings.DATABASE_URL
if DATABASE_URL:
    DATABASE_URL = DATABASE_URL.strip().strip('"').strip("'")
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql+psycopg2://", 1)
    elif DATABASE_URL.startswith("postgresql://"):
        DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)

# Check if running on Render and DATABASE_URL is pointing to unreachable localhost
is_render = bool(os.getenv("RENDER") or os.getenv("RENDER_SERVICE_ID") or os.getenv("PORT"))
if is_render and DATABASE_URL and ("localhost" in DATABASE_URL or "127.0.0.1" in DATABASE_URL):
    print(
        "\n" + "=" * 70 + "\n"
        "[Render Notice] DATABASE_URL is pointing to localhost, which is not reachable inside Render's cloud container.\n"
        "[Render Notice] Temporarily falling back to SQLite (sqlite:///./library.db) so the service starts up.\n"
        "[Action Required] For persistent cloud PostgreSQL, create a PostgreSQL database on Render and set DATABASE_URL in Environment Variables.\n"
        + "=" * 70 + "\n",
        flush=True,
    )
    DATABASE_URL = "sqlite:///./library.db"

connect_args = {}
if DATABASE_URL and DATABASE_URL.startswith("sqlite"):
    connect_args["check_same_thread"] = False

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args,
    pool_pre_ping=True,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
