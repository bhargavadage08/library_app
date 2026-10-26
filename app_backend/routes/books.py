from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from core.database import get_db
from models.user import User
from schemas.book import (
    BookCreate,
    BookDetailResponse,
    BookResponse,
    BookUpdate,
    CategoryResponse,
    FavoriteToggleResponse,
)
from services.book_service import BookService
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
