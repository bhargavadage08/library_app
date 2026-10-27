from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict


class BookBase(BaseModel):
    title: str
    author_name: str = "Unknown Author"
    category: str = "Fiction"
    cover_url: Optional[str] = None
    description: Optional[str] = None


class BookCreate(BookBase):
    content: Optional[str] = None
    download_count: Optional[int] = 0


class BookUpdate(BaseModel):
    title: Optional[str] = None
    author_name: Optional[str] = None
    category: Optional[str] = None
    cover_url: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None


class BookResponse(BookBase):
    id: int
    download_count: int
    created_at: datetime
    is_favorite: Optional[bool] = False

    model_config = ConfigDict(from_attributes=True)


class BookDetailResponse(BookResponse):
    content: Optional[str] = None


class CategoryResponse(BaseModel):
    name: str
    icon: Optional[str] = None
    color: Optional[str] = None
    book_count: int = 0


class FavoriteToggleResponse(BaseModel):
    book_id: int
    is_favorite: bool
    message: str


# --- Book Reading & Pagination Schemas ---

class BookContentResponse(BaseModel):
    book_id: int
    title: str
    authors: str
    format: str = "text/plain"
    total_length: int
    content: str
    is_cached: bool = False


class BookPageResponse(BaseModel):
    book_id: int
    title: str
    author: str = "Unknown Author"
    page: int
    page_size: int
    total_pages: int
    total_characters: int
    content: str
    has_prev: bool
    has_next: bool
    is_app_generated: bool = True


class ReadingProgressUpdate(BaseModel):
    current_page: int
    total_pages: int


class ReadingProgressResponse(BaseModel):
    book_id: int
    current_page: int
    total_pages: int
    percentage: float
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)
