from typing import List, Optional
from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy.orm import Session
from core.database import get_db
from models.user import User
from schemas.book import (
    BookContentResponse,
    BookCreate,
    BookDetailResponse,
    BookPageResponse,
    BookResponse,
    BookUpdate,
    CategoryResponse,
    FavoriteToggleResponse,
    ReadingProgressResponse,
    ReadingProgressUpdate,
)
from services.book_service import BookService
from services.book_reader_service import BookReaderService
from .deps import get_current_user, get_optional_current_user

router = APIRouter()


@router.get(
    "",
    response_model=List[BookResponse],
    summary="List and search books",
)
def list_books(
    query: Optional[str] = Query(None, description="Search by title, author, or category"),
    category: Optional[str] = Query(None, description="Filter by category name"),
    skip: int = Query(0, ge=0),
    limit: int = Query(30, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Retrieve books with optional query search and category filter.
    """
    user_id = current_user.id if current_user else None
    return BookService.get_books(
        db,
        skip=skip,
        limit=limit,
        query=query,
        category=category,
        user_id=user_id,
    )


@router.get(
    "/categories",
    response_model=List[CategoryResponse],
    summary="List book categories",
)
def list_categories(
    db: Session = Depends(get_db),
):
    """
    Retrieve available categories with icons, colors, and book counts.
    """
    return BookService.get_categories(db)


@router.get(
    "/favorites",
    response_model=List[BookResponse],
    summary="Get user favorite books",
)
def get_user_favorites(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve all books favorited by the currently logged-in user.
    """
    return BookService.get_user_favorites(db, user_id=current_user.id)


@router.get(
    "/{book_id}",
    response_model=BookDetailResponse,
    summary="Get book details and content",
)
def get_book(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Retrieve complete book details including full text content for reading.
    """
    user_id = current_user.id if current_user else None
    book = BookService.get_book_by_id(db, book_id=book_id, user_id=user_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )
    return book


@router.post(
    "",
    response_model=BookResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new book",
)
def create_book(
    book_in: BookCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Add a new book to the library catalog.
    """
    return BookService.create_book(db, book_in=book_in)


@router.put(
    "/{book_id}",
    response_model=BookResponse,
    summary="Update a book",
)
def update_book(
    book_id: int,
    book_in: BookUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update details of an existing book.
    """
    book = BookService.get_book_by_id(db, book_id=book_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )
    return BookService.update_book(db, book=book, book_in=book_in)


@router.delete(
    "/{book_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a book",
)
def delete_book(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Remove a book from the library catalog.
    """
    book = BookService.get_book_by_id(db, book_id=book_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )
    BookService.delete_book(db, book=book)


@router.post(
    "/{book_id}/favorite",
    response_model=FavoriteToggleResponse,
    summary="Toggle favorite status of a book",
)
def toggle_favorite(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Add or remove a book from the current user's favorites list.
    """
    book = BookService.get_book_by_id(db, book_id=book_id)
    if not book:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Book not found",
        )

    is_favorite, message = BookService.toggle_favorite(
        db,
        user_id=current_user.id,
        book_id=book_id,
    )
    return FavoriteToggleResponse(
        book_id=book_id,
        is_favorite=is_favorite,
        message=message,
    )


# --- Reading & Pagination Endpoints ---

@router.get(
    "/{book_id}/content",
    response_model=BookContentResponse,
    summary="Get full readable book content",
)
def get_book_content(
    book_id: int,
    fallback_url: Optional[str] = Query(None, description="Direct text or HTML format URL from formats"),
    fallback_title: Optional[str] = Query(None, description="Optional book title from client"),
    fallback_author: Optional[str] = Query(None, description="Optional book author from client"),
    db: Session = Depends(get_db),
):
    """
    Retrieve the full readable text or HTML content of a book.
    Attempts local PostgreSQL database first, then caches, then Project Gutenberg mirrors.
    """
    return BookReaderService.get_book_content_response(
        db=db,
        book_id=book_id,
        fallback_url=fallback_url,
        fallback_title=fallback_title,
        fallback_author=fallback_author,
    )


@router.get(
    "/{book_id}/pages",
    response_model=BookPageResponse,
    summary="Get paginated reading page for a book",
)
def get_book_page(
    book_id: int,
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    pageSize: int = Query(2500, ge=500, le=20000, description="Approximate characters per reading page"),
    fallback_url: Optional[str] = Query(None, description="Direct text format URL from formats"),
    fallback_title: Optional[str] = Query(None, description="Optional book title from client"),
    fallback_author: Optional[str] = Query(None, description="Optional book author from client"),
    db: Session = Depends(get_db),
):
    """
    Retrieve a specific reading page for a book.
    Uses smart word and paragraph boundary splitting to ensure text is never cut awkwardly.
    """
    return BookReaderService.get_book_pages(
        db=db,
        book_id=book_id,
        page=page,
        page_size=pageSize,
        fallback_url=fallback_url,
        fallback_title=fallback_title,
        fallback_author=fallback_author,
    )


@router.get(
    "/{book_id}/progress",
    response_model=ReadingProgressResponse,
    summary="Get reading progress for a book",
)
def get_reading_progress(
    book_id: int,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
    device_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Retrieve saved reading progress (last-read page, percentage).
    Associates with authenticated user, or falls back to device ID.
    """
    user_id = current_user.id if current_user else None
    effective_device_id = x_device_id or device_id
    return BookReaderService.get_reading_progress(
        db=db,
        book_id=book_id,
        user_id=user_id,
        device_id=effective_device_id,
    )


@router.put(
    "/{book_id}/progress",
    response_model=ReadingProgressResponse,
    summary="Save reading progress for a book",
)
def save_reading_progress(
    book_id: int,
    progress_in: ReadingProgressUpdate,
    x_device_id: Optional[str] = Header(None, alias="X-Device-Id"),
    device_id: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: Optional[User] = Depends(get_optional_current_user),
):
    """
    Save or update current reading position (page, total pages, percentage) in the database.
    """
    user_id = current_user.id if current_user else None
    effective_device_id = x_device_id or device_id
    return BookReaderService.save_reading_progress(
        db=db,
        book_id=book_id,
        progress_in=progress_in,
        user_id=user_id,
        device_id=effective_device_id,
    )

