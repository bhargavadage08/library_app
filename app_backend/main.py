from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from core.database import Base, SessionLocal, engine
import models  # Ensures all SQLAlchemy models are registered
from models.book import Book
from models.user import User
from routes import api_router


def seed_initial_data():
    """Seed initial sample books with authentic Gutenberg content and IDs."""
    from services.book_reader_service import BookReaderService

    db = SessionLocal()
    try:
        sample_catalog = [
            {
                "id": 84,
                "title": "Frankenstein; Or, The Modern Prometheus",
                "author_name": "Mary Wollstonecraft Shelley",
                "category": "Science",
                "cover_url": "https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg",
                "description": "The tragic story of Victor Frankenstein and his monstrous creation.",
                "download_count": 98250,
            },
            {
                "id": 1342,
                "title": "Pride and Prejudice",
                "author_name": "Jane Austen",
                "category": "Romance",
                "cover_url": "https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg",
                "description": "A classic romantic novel of manners written by Jane Austen in 1813.",
                "download_count": 75320,
            },
            {
                "id": 64317,
                "title": "The Great Gatsby",
                "author_name": "F. Scott Fitzgerald",
                "category": "Fiction",
                "cover_url": "https://www.gutenberg.org/cache/epub/64317/pg64317.cover.medium.jpg",
                "description": "The story of Jay Gatsby and his pursuit of Daisy Buchanan in the Roaring Twenties.",
                "download_count": 61200,
            },
            {
                "id": 11,
                "title": "Alice's Adventures in Wonderland",
                "author_name": "Lewis Carroll",
                "category": "Fantasy",
                "cover_url": "https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg",
                "description": "Alice's descent into a subterranean fantasy world of curious creatures.",
                "download_count": 45100,
            },
            {
                "id": 1661,
                "title": "The Adventures of Sherlock Holmes",
                "author_name": "Arthur Conan Doyle",
                "category": "Adventure",
                "cover_url": "https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg",
                "description": "A collection of twelve short stories featuring the legendary detective Sherlock Holmes.",
                "download_count": 89400,
            },
        ]

        # Ensure books with authentic Gutenberg IDs exist
        for item in sample_catalog:
            existing = db.query(Book).filter(Book.id == item["id"]).first()
            if not existing:
                try:
                    content, _, _, _ = BookReaderService.get_book_readable_content(
                        db=db,
                        book_id=item["id"],
                        fallback_title=item["title"],
                        fallback_author=item["author_name"],
                    )
                except Exception:
                    content = None
                new_book = Book(
                    id=item["id"],
                    title=item["title"],
                    author_name=item["author_name"],
                    category=item["category"],
                    cover_url=item["cover_url"],
                    description=item["description"],
                    content=content,
                    download_count=item["download_count"],
                )
                db.add(new_book)
                db.commit()

        # Update legacy books (IDs 1-5) if they only have short placeholder snippets (<5000 chars)
        legacy_map = {1: 84, 2: 1342, 3: 64317, 4: 11, 5: 1661}
        for local_id, gid in legacy_map.items():
            local_b = db.query(Book).filter(Book.id == local_id).first()
            if local_b and (not local_b.content or len(local_b.content.strip()) < 5000):
                g_book = db.query(Book).filter(Book.id == gid).first()
                if g_book and g_book.content:
                    local_b.content = g_book.content
                    local_b.title = g_book.title
                    local_b.author_name = g_book.author_name
                    db.commit()

        # Synchronize legacy progress into reading_history
        from datetime import datetime, timezone
        from models.reading_history import ReadingHistory
        from models.reading_progress import ReadingProgress

        user_progresses = (
            db.query(ReadingProgress)
            .filter(ReadingProgress.user_id.isnot(None))
            .all()
        )
        for rp in user_progresses:
            existing_hist = (
                db.query(ReadingHistory)
                .filter_by(user_id=rp.user_id, book_id=rp.book_id)
                .first()
            )
            if not existing_hist:
                b_match = db.query(Book).filter(Book.id == rp.book_id).first()
                title_val = b_match.title if b_match else f"Book #{rp.book_id}"
                author_val = b_match.author_name if b_match else "Unknown Author"
                cover_val = b_match.cover_url if b_match else None
                now_ts = rp.updated_at or datetime.now(timezone.utc)
                new_hist = ReadingHistory(
                    user_id=rp.user_id,
                    book_id=rp.book_id,
                    title=title_val,
                    author=author_val,
                    cover_url=cover_val,
                    current_page=rp.current_page,
                    total_pages=rp.total_pages,
                    progress_percent=round(rp.percentage),
                    created_at=now_ts,
                    last_read_at=now_ts,
                )
                db.add(new_hist)
        db.commit()
    except Exception as e:
        db.rollback()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: initialize database tables and seed initial data
    Base.metadata.create_all(bind=engine)
    seed_initial_data()
    yield
    # Shutdown logic (if any)


# Initialize FastAPI application
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="REST API backend for Online Book Library mobile/web app.",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Set up CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routers (both /api/v1 and /api aliases)
app.include_router(api_router, prefix=settings.API_V1_STR)
app.include_router(api_router, prefix="/api")


@app.get("/", tags=["Health & Status"])
def root():
    """Root welcome endpoint."""
    return {
        "message": f"Welcome to {settings.PROJECT_NAME}",
        "version": settings.VERSION,
        "docs_url": "/docs",
        "api_v1": settings.API_V1_STR,
    }


@app.get("/health", tags=["Health & Status"])
def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "project": settings.PROJECT_NAME,
        "version": settings.VERSION,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
