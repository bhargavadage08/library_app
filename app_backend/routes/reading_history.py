
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from core.database import get_db
from models.book import Book
from models.reading_history import ReadingHistory
from models.user import User
from routes.deps import get_current_user
from schemas.book import (
    ReadingHistoryResponse,
    ReadingProgressUpdate,
)

router = APIRouter(
    prefix="/reading-history",
    tags=["Reading History"],
)


@router.post(
    "/{book_id}",
    response_model=ReadingHistoryResponse,
)
def save_reading_progress(
    book_id: int,
    payload: ReadingProgressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if book_id <= 0:
        raise HTTPException(status_code=400, detail="Invalid book ID")

    if (
        payload.total_pages is not None
        and payload.current_page > payload.total_pages
    ):
        raise HTTPException(
            status_code=422,
            detail="Current page cannot exceed total pages",
        )

    progress = 0
    if payload.total_pages:
        progress = min(
            100,
            round(payload.current_page / payload.total_pages * 100),
        )

    # Look up catalog book if title or author or cover is missing
    book_obj = db.query(Book).filter(Book.id == book_id).first()
    title = payload.title or (book_obj.title if book_obj else f"Book #{book_id}")
    author = payload.author or (book_obj.author_name if book_obj else None)
    cover_url = payload.cover_url or (book_obj.cover_url if book_obj else None)

    record = (
        db.query(ReadingHistory)
        .filter_by(user_id=current_user.id, book_id=book_id)
        .first()
    )

    now = datetime.now(timezone.utc)

    if record is None:
        record = ReadingHistory(
            user_id=current_user.id,
            book_id=book_id,
            title=title,
            author=author,
            cover_url=cover_url,
            current_page=payload.current_page,
            total_pages=payload.total_pages,
            progress_percent=progress,
            created_at=now,
            last_read_at=now,
        )
        db.add(record)
    else:
        if payload.title:
            record.title = payload.title
        elif not record.title:
            record.title = title
        if payload.author:
            record.author = payload.author
        elif not record.author:
            record.author = author
        if payload.cover_url:
            record.cover_url = payload.cover_url
        elif not record.cover_url:
            record.cover_url = cover_url
        record.current_page = payload.current_page
        record.total_pages = payload.total_pages
        record.progress_percent = progress
        record.last_read_at = now


    try:
        db.commit()
        db.refresh(record)
        return record
    except Exception:
        db.rollback()
        raise


@router.get("", response_model=list[ReadingHistoryResponse])
def get_reading_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(ReadingHistory)
        .filter(ReadingHistory.user_id == current_user.id)
        .order_by(ReadingHistory.last_read_at.desc())
        .all()
    )


@router.get(
    "/{book_id}",
    response_model=ReadingHistoryResponse,
)
def get_book_progress(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    record = (
        db.query(ReadingHistory)
        .filter_by(user_id=current_user.id, book_id=book_id)
        .first()
    )

    if record is None:
        raise HTTPException(
            status_code=404,
            detail="Reading history not found",
        )

    return record


@router.delete("/{book_id}", status_code=204)
def delete_book_history(
    book_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    record = (
        db.query(ReadingHistory)
        .filter_by(user_id=current_user.id, book_id=book_id)
        .first()
    )

    if record is None:
        raise HTTPException(
            status_code=404,
            detail="Reading history not found",
        )

    db.delete(record)
    db.commit()
    return Response(status_code=204)


@router.delete("", status_code=204)
def clear_reading_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    db.query(ReadingHistory).filter(ReadingHistory.user_id == current_user.id).delete()
    db.commit()
    return Response(status_code=204)

