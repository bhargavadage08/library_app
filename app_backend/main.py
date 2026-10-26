from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.config import settings
from core.database import Base, SessionLocal, engine
from models.book import Book
from models.user import User
from routes import api_router


def seed_initial_data():
    """Seed initial sample books and a default user if database is empty."""
    db = SessionLocal()
    try:
        # Check if books already exist
        if db.query(Book).count() == 0:
            sample_books = [
                Book(
                    title="Frankenstein",
                    author_name="Mary Wollstonecraft Shelley",
                    category="Science",
                    cover_url="https://www.gutenberg.org/cache/epub/84/pg84.cover.medium.jpg",
                    description="The story of Victor Frankenstein and his monstrous creation.",
                    content=(
                        "You will rejoice to hear that no disaster has accompanied the "
                        "commencement of an enterprise which you have regarded with such evil "
                        "forebodings. I arrived here yesterday, and my first task is to assure "
                        "my dear sister of my welfare and increasing confidence in the success "
                        "of my undertaking.\n\n"
                        "I am already far north of London, and as I walk in the streets of "
                        "Petersburgh, I feel a cold northern breeze play upon my cheeks, which "
                        "braces my nerves and fills me with delight."
                    ),
                    download_count=98250,
                ),
                Book(
                    title="Pride and Prejudice",
                    author_name="Jane Austen",
                    category="Romance",
                    cover_url="https://www.gutenberg.org/cache/epub/1342/pg1342.cover.medium.jpg",
                    description="A classic romantic novel of manners written by Jane Austen in 1813.",
                    content=(
                        "It is a truth universally acknowledged, that a single man in possession "
                        "of a good fortune, must be in want of a wife.\n\n"
                        "However little known the feelings or views of such a man may be on his "
                        "first entering a neighbourhood, this truth is so well fixed in the minds "
                        "of the surrounding families, that he is considered the rightful property "
                        "of some one or other of their daughters."
                    ),
                    download_count=75320,
                ),
                Book(
                    title="The Great Gatsby",
                    author_name="F. Scott Fitzgerald",
                    category="Fiction",
                    cover_url="https://www.gutenberg.org/cache/epub/64317/pg64317.cover.medium.jpg",
                    description="The tragic story of Jay Gatsby and his pursuit of Daisy Buchanan.",
                    content=(
                        "In my younger and more vulnerable years my father gave me some advice "
                        "that I've been turning over in my mind ever since.\n\n"
                        "'Whenever you feel like criticizing any one,' he told me, 'just "
                        "remember that all the people in this world haven't had the advantages "
                        "that you've had.'"
                    ),
                    download_count=61200,
                ),
                Book(
                    title="Alice's Adventures in Wonderland",
                    author_name="Lewis Carroll",
                    category="Fantasy",
                    cover_url="https://www.gutenberg.org/cache/epub/11/pg11.cover.medium.jpg",
                    description="Alice's descent into a subterranean fantasy world of curious creatures.",
                    content=(
                        "Alice was beginning to get very tired of sitting by her sister on the "
                        "bank, and of having nothing to do: once or twice she had peeped into the "
                        "book her sister was reading, but it had no pictures or conversations in "
                        "it, 'and what is the use of a book,' thought Alice 'without pictures or "
                        "conversations?'"
                    ),
                    download_count=45100,
                ),
                Book(
                    title="The Adventures of Sherlock Holmes",
                    author_name="Arthur Conan Doyle",
                    category="Adventure",
                    cover_url="https://www.gutenberg.org/cache/epub/1661/pg1661.cover.medium.jpg",
                    description="A collection of twelve short stories featuring Sherlock Holmes.",
                    content=(
                        "To Sherlock Holmes she is always THE woman. I have seldom heard him "
                        "mention her under any other name. In his eyes she eclipses and "
                        "predominates the whole of her sex."
                    ),
                    download_count=89400,
                ),
            ]
            db.add_all(sample_books)
            db.commit()
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

# Include API v1 router
app.include_router(api_router, prefix=settings.API_V1_STR)


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
