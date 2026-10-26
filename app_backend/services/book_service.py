from typing import List, Optional, Tuple
from sqlalchemy import or_, func
from sqlalchemy.orm import Session
from models.book import Book, FavoriteBook
from schemas.book import BookCreate, BookUpdate, CategoryResponse


class BookService:
    @staticmethod
    def get_books(
        db: Session,
        skip: int = 0,
        limit: int = 50,
        query: Optional[str] = None,
        category: Optional[str] = None,
        user_id: Optional[int] = None,
    ) -> List[Book]:
        db_query = db.query(Book)

        if category and category.strip():
            db_query = db_query.filter(
                func.lower(Book.category) == category.strip().lower()
            )

        if query and query.strip():
            search = f"%{query.strip().lower()}%"
            db_query = db_query.filter(
                or_(
                    func.lower(Book.title).like(search),
                    func.lower(Book.author_name).like(search),
                    func.lower(Book.category).like(search),
                )
            )

        books = (
            db_query.order_by(Book.download_count.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

        # Annotate with user favorite status if user is provided
        if user_id:
            fav_book_ids = {
                f.book_id
                for f in db.query(FavoriteBook.book_id)
                .filter(FavoriteBook.user_id == user_id)
                .all()
            }
            for b in books:
                setattr(b, "is_favorite", b.id in fav_book_ids)

        return books

    @staticmethod
    def get_book_by_id(
        db: Session,
        book_id: int,
        user_id: Optional[int] = None,
    ) -> Optional[Book]:
        book = db.query(Book).filter(Book.id == book_id).first()
        if not book:
            return None

        if user_id:
            is_fav = (
                db.query(FavoriteBook)
                .filter(
                    FavoriteBook.user_id == user_id,
                    FavoriteBook.book_id == book_id,
                )
                .first()
                is not None
            )
            setattr(book, "is_favorite", is_fav)

        return book

    @staticmethod
    def create_book(db: Session, book_in: BookCreate) -> Book:
        db_book = Book(
            title=book_in.title,
            author_name=book_in.author_name,
            category=book_in.category,
            cover_url=book_in.cover_url,
            description=book_in.description,
            content=book_in.content,
            download_count=book_in.download_count or 0,
        )
        db.add(db_book)
        db.commit()
        db.refresh(db_book)
        return db_book

    @staticmethod
    def update_book(db: Session, book: Book, book_in: BookUpdate) -> Book:
        update_data = book_in.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(book, field, value)
        db.commit()
        db.refresh(book)
        return book

    @staticmethod
    def delete_book(db: Session, book: Book) -> None:
        db.delete(book)
        db.commit()

    @staticmethod
    def toggle_favorite(db: Session, user_id: int, book_id: int) -> Tuple[bool, str]:
        existing = (
            db.query(FavoriteBook)
            .filter(
                FavoriteBook.user_id == user_id,
                FavoriteBook.book_id == book_id,
            )
            .first()
        )

        if existing:
            db.delete(existing)
            db.commit()
            return False, "Book removed from favorites"
        else:
            new_fav = FavoriteBook(user_id=user_id, book_id=book_id)
            db.add(new_fav)
            db.commit()
            return True, "Book added to favorites"

    @staticmethod
    def get_user_favorites(db: Session, user_id: int) -> List[Book]:
        favorites = (
            db.query(Book)
            .join(FavoriteBook, Book.id == FavoriteBook.book_id)
            .filter(FavoriteBook.user_id == user_id)
            .all()
        )
        for b in favorites:
            setattr(b, "is_favorite", True)
        return favorites

    @staticmethod
    def get_categories(db: Session) -> List[dict]:
        default_categories = [
            {"name": "Fiction", "icon": "auto_stories", "color": "#7C4DFF"},
            {"name": "Science", "icon": "science", "color": "#009688"},
            {"name": "History", "icon": "history_edu", "color": "#FF9800"},
            {"name": "Romance", "icon": "favorite", "color": "#3F51B5"},
            {"name": "Biography", "icon": "person", "color": "#00ACC1"},
            {"name": "Education", "icon": "school", "color": "#795548"},
            {"name": "Fantasy", "icon": "auto_awesome", "color": "#9C27B0"},
            {"name": "Adventure", "icon": "explore", "color": "#FF5722"},
        ]

        # Calculate counts from database
        counts = dict(
            db.query(Book.category, func.count(Book.id))
            .group_by(Book.category)
            .all()
        )

        result = []
        for cat in default_categories:
            result.append(
                {
                    "name": cat["name"],
                    "icon": cat["icon"],
                    "color": cat["color"],
                    "book_count": counts.get(cat["name"], 0),
                }
            )
        return result
