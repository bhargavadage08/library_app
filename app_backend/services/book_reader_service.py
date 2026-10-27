import logging
from typing import Dict, List, Optional, Tuple
import httpx
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from models.book import Book
from models.reading_progress import ReadingProgress
from schemas.book import (
    BookContentResponse,
    BookPageResponse,
    ReadingProgressResponse,
    ReadingProgressUpdate,
)
from utils.book_text_parser import clean_gutenberg_text, clean_html_text, paginate_text

logger = logging.getLogger(__name__)

# In-memory LRU-like caches for fast responses
_CONTENT_CACHE: Dict[int, Tuple[str, str, str, str]] = {}  # id -> (content, title, author, format)
_PAGES_CACHE: Dict[Tuple[int, int], List[str]] = {}  # (id, page_size) -> pages list


class BookReaderService:
    @staticmethod
    def _fetch_from_url(client: httpx.Client, url: str) -> Optional[Tuple[str, str]]:
        """
        Attempts to download book content from a given URL.
        Returns (raw_content, content_type) or None if request fails.
        """
        try:
            resp = client.get(url)
            if resp.status_code == 200 and len(resp.text.strip()) > 300:
                content_type = resp.headers.get("content-type", "").lower()
                fmt = "text/html" if "html" in content_type or url.endswith(".html") else "text/plain"
                return resp.text, fmt
        except Exception as e:
            logger.debug(f"Failed to fetch {url}: {e}")
        return None

    @classmethod
    def get_book_readable_content(
        cls,
        db: Session,
        book_id: int,
        fallback_url: Optional[str] = None,
        fallback_title: Optional[str] = None,
        fallback_author: Optional[str] = None,
    ) -> Tuple[str, str, str, str]:
        """
        Returns (content, title, author, format) for the given book ID.
        Rejects short placeholder/hand-written snippets (<5,000 chars) to guarantee
        that the real, authentic book with all its complete pages is returned.
        """
        import re

        # Map seeded/local IDs to authentic Project Gutenberg IDs
        LOCAL_TO_GUTENBERG = {
            1: 84,     # Frankenstein (Mary Shelley)
            2: 1342,   # Pride and Prejudice (Jane Austen)
            3: 64317,  # The Great Gatsby (F. Scott Fitzgerald)
            4: 11,     # Alice's Adventures in Wonderland (Lewis Carroll)
            5: 1661,   # The Adventures of Sherlock Holmes (Arthur Conan Doyle)
        }

        # 1. Check in-memory cache first
        if book_id in _CONTENT_CACHE:
            cached_content, c_title, c_author, c_fmt = _CONTENT_CACHE[book_id]
            if len(cached_content.strip()) >= 5000:
                return cached_content, c_title, c_author, c_fmt

        # 2. Check local database for authentic full book content (>= 5,000 characters)
        db_book = db.query(Book).filter(Book.id == book_id).first()
        if db_book and db_book.content and len(db_book.content.strip()) >= 5000:
            return (
                db_book.content,
                db_book.title or "Book",
                db_book.author_name or "Unknown Author",
                "text/plain",
            )

        # Also check if the mapped Gutenberg ID is already in DB with full content
        mapped_gid = LOCAL_TO_GUTENBERG.get(book_id)
        if mapped_gid and mapped_gid != book_id:
            mapped_book = db.query(Book).filter(Book.id == mapped_gid).first()
            if mapped_book and mapped_book.content and len(mapped_book.content.strip()) >= 5000:
                # Update current book with full real content so future queries are instant
                if db_book:
                    db_book.content = mapped_book.content
                    if not db_book.title or db_book.title == "Untitled":
                        db_book.title = mapped_book.title
                    if not db_book.author_name:
                        db_book.author_name = mapped_book.author_name
                    db.commit()
                return (
                    mapped_book.content,
                    mapped_book.title or (db_book.title if db_book else "Book"),
                    mapped_book.author_name or (db_book.author_name if db_book else "Unknown Author"),
                    "text/plain",
                )

        # 3. Resolve the actual Gutenberg book ID
        gutenberg_id = LOCAL_TO_GUTENBERG.get(book_id, book_id)
        if db_book and db_book.cover_url:
            m = re.search(r"/epub/(\d+)/", db_book.cover_url)
            if m:
                gutenberg_id = int(m.group(1))
        elif fallback_url:
            m = re.search(r"/(?:epub|ebooks|files)/(\d+)", fallback_url)
            if m:
                gutenberg_id = int(m.group(1))

        title = fallback_title or (db_book.title if db_book else f"Book #{gutenberg_id}")
        author = fallback_author or (db_book.author_name if db_book else "Unknown Author")
        content: Optional[str] = None
        detected_format = "text/plain"

        # 4. Fetch the authentic full book text from Gutenberg cache/files mirrors
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) BookHavenLibrary/1.0",
            "Accept": "text/html,text/plain,application/xhtml+xml;q=0.9,*/*;q=0.8",
        }

        with httpx.Client(timeout=25.0, follow_redirects=True, headers=headers) as client:
            # Candidate 1: Standard Gutenberg cache text mirror (fastest and cleanest)
            if not content and gutenberg_id > 0:
                url = f"https://www.gutenberg.org/cache/epub/{gutenberg_id}/pg{gutenberg_id}.txt"
                res = cls._fetch_from_url(client, url)
                if res:
                    raw_text, detected_format = res
                    content = clean_gutenberg_text(raw_text)

            # Candidate 2: Gutenberg files text mirror
            if not content and gutenberg_id > 0:
                url = f"https://www.gutenberg.org/files/{gutenberg_id}/{gutenberg_id}-0.txt"
                res = cls._fetch_from_url(client, url)
                if res:
                    raw_text, detected_format = res
                    content = clean_gutenberg_text(raw_text)

            # Candidate 3: Gutenberg HTML cache
            if not content and gutenberg_id > 0:
                url = f"https://www.gutenberg.org/cache/epub/{gutenberg_id}/pg{gutenberg_id}-images.html"
                res = cls._fetch_from_url(client, url)
                if res:
                    raw_text, _ = res
                    content = clean_html_text(raw_text)
                    detected_format = "text/html"

            # Candidate 4: Client provided fallback URL
            if not content and fallback_url and fallback_url.startswith("http"):
                res = cls._fetch_from_url(client, fallback_url)
                if res:
                    raw_text, detected_format = res
                    content = clean_html_text(raw_text) if "html" in detected_format else clean_gutenberg_text(raw_text)

            # Candidate 5: Query Gutendex for format URLs
            if not content and gutenberg_id > 0:
                try:
                    gd_resp = client.get(f"https://gutendex.com/books/{gutenberg_id}")
                    if gd_resp.status_code == 200:
                        gd_data = gd_resp.json()
                        title = gd_data.get("title", title)
                        authors_list = gd_data.get("authors", [])
                        if authors_list:
                            author = authors_list[0].get("name", author)

                        formats = gd_data.get("formats", {})
                        format_candidates = [
                            formats.get("text/plain; charset=utf-8"),
                            formats.get("text/plain"),
                            formats.get("text/html; charset=utf-8"),
                            formats.get("text/html"),
                            formats.get("text/plain; charset=us-ascii"),
                        ]
                        for fmt_url in format_candidates:
                            if fmt_url and fmt_url.startswith("http"):
                                res = cls._fetch_from_url(client, fmt_url)
                                if res:
                                    raw_text, detected_format = res
                                    content = (
                                        clean_html_text(raw_text)
                                        if "html" in detected_format
                                        else clean_gutenberg_text(raw_text)
                                    )
                                    break
                except Exception as e:
                    logger.warning(f"Gutendex query failed for book {gutenberg_id}: {e}")

        if not content or len(content.strip()) < 1000:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(
                    f"Authentic full content for book ID {book_id} (Gutenberg #{gutenberg_id}) "
                    "could not be retrieved. Please check your network connection."
                ),
            )

        # 4. Save to in-memory cache
        _CONTENT_CACHE[book_id] = (content, title, author, detected_format)

        # 5. Persist or update in PostgreSQL database so subsequent reads are instant
        try:
            if db_book:
                db_book.content = content
                if not db_book.title or db_book.title == "Untitled":
                    db_book.title = title
                if not db_book.author_name:
                    db_book.author_name = author
                db.commit()
            else:
                new_book = Book(
                    id=book_id,
                    title=title,
                    author_name=author,
                    category="Classic",
                    content=content,
                    download_count=1000,
                )
                db.add(new_book)
                db.commit()
        except Exception as e:
            db.rollback()
            logger.warning(f"Could not persist book content to DB: {e}")

        return content, title, author, detected_format

    @classmethod
    def get_book_content_response(
        cls,
        db: Session,
        book_id: int,
        fallback_url: Optional[str] = None,
        fallback_title: Optional[str] = None,
        fallback_author: Optional[str] = None,
    ) -> BookContentResponse:
        is_cached = book_id in _CONTENT_CACHE
        content, title, author, fmt = cls.get_book_readable_content(
            db=db,
            book_id=book_id,
            fallback_url=fallback_url,
            fallback_title=fallback_title,
            fallback_author=fallback_author,
        )
        return BookContentResponse(
            book_id=book_id,
            title=title,
            authors=author,
            format=fmt,
            total_length=len(content),
            content=content,
            is_cached=is_cached,
        )

    @classmethod
    def get_book_pages(
        cls,
        db: Session,
        book_id: int,
        page: int = 1,
        page_size: int = 2500,
        fallback_url: Optional[str] = None,
        fallback_title: Optional[str] = None,
        fallback_author: Optional[str] = None,
    ) -> BookPageResponse:
        """
        Retrieves paginated content for a book using sensible word/paragraph boundaries.
        """
        content, title, author, _ = cls.get_book_readable_content(
            db=db,
            book_id=book_id,
            fallback_url=fallback_url,
            fallback_title=fallback_title,
            fallback_author=fallback_author,
        )

        cache_key = (book_id, page_size)
        if cache_key not in _PAGES_CACHE:
            _PAGES_CACHE[cache_key] = paginate_text(content, page_size=page_size)

        pages = _PAGES_CACHE[cache_key]
        total_pages = max(len(pages), 1)

        # Clamp page index
        if page < 1:
            page = 1
        elif page > total_pages:
            page = total_pages

        page_content = pages[page - 1] if pages else "No content available."

        return BookPageResponse(
            book_id=book_id,
            title=title,
            author=author,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
            total_characters=len(content),
            content=page_content,
            has_prev=page > 1,
            has_next=page < total_pages,
            is_app_generated=True,
        )

    @staticmethod
    def get_reading_progress(
        db: Session,
        book_id: int,
        user_id: Optional[int] = None,
        device_id: Optional[str] = None,
    ) -> ReadingProgressResponse:
        """
        Retrieves user or device reading progress for a given book.
        """
        query = db.query(ReadingProgress).filter(ReadingProgress.book_id == book_id)

        if user_id:
            progress = query.filter(ReadingProgress.user_id == user_id).first()
        elif device_id:
            progress = query.filter(ReadingProgress.device_id == device_id).first()
        else:
            progress = None

        if progress:
            return ReadingProgressResponse(
                book_id=progress.book_id,
                current_page=progress.current_page,
                total_pages=progress.total_pages,
                percentage=progress.percentage,
                updated_at=progress.updated_at,
            )

        # Default initial progress
        return ReadingProgressResponse(
            book_id=book_id,
            current_page=1,
            total_pages=1,
            percentage=0.0,
            updated_at=None,
        )

    @staticmethod
    def save_reading_progress(
        db: Session,
        book_id: int,
        progress_in: ReadingProgressUpdate,
        user_id: Optional[int] = None,
        device_id: Optional[str] = None,
    ) -> ReadingProgressResponse:
        """
        Persists updated reading progress for the authenticated user or device.
        """
        current_page = max(1, progress_in.current_page)
        total_pages = max(1, progress_in.total_pages)
        percentage = round((current_page / total_pages) * 100, 1)
        if percentage > 100.0:
            percentage = 100.0

        progress: Optional[ReadingProgress] = None

        if user_id:
            progress = (
                db.query(ReadingProgress)
                .filter(
                    ReadingProgress.book_id == book_id,
                    ReadingProgress.user_id == user_id,
                )
                .first()
            )
        elif device_id:
            progress = (
                db.query(ReadingProgress)
                .filter(
                    ReadingProgress.book_id == book_id,
                    ReadingProgress.device_id == device_id,
                )
                .first()
            )

        if progress:
            progress.current_page = current_page
            progress.total_pages = total_pages
            progress.percentage = percentage
        else:
            progress = ReadingProgress(
                book_id=book_id,
                user_id=user_id,
                device_id=device_id,
                current_page=current_page,
                total_pages=total_pages,
                percentage=percentage,
            )
            db.add(progress)

        db.commit()
        db.refresh(progress)

        return ReadingProgressResponse(
            book_id=progress.book_id,
            current_page=progress.current_page,
            total_pages=progress.total_pages,
            percentage=progress.percentage,
            updated_at=progress.updated_at,
        )
