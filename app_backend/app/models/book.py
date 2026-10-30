from datetime import datetime, timezone
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from core.database import Base


class Book(Base):
    __tablename__ = "books"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True, nullable=False)
    author_name = Column(String, index=True, default="Unknown Author")
    category = Column(String, index=True, default="Fiction")
    cover_url = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    content = Column(Text, nullable=True)
    download_count = Column(Integer, default=0)
    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    favorites = relationship(
        "FavoriteBook",
        back_populates="book",
        cascade="all, delete-orphan",
    )


class FavoriteBook(Base):
    __tablename__ = "favorite_books"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    book_id = Column(Integer, ForeignKey("books.id", ondelete="CASCADE"), nullable=False)
    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    user = relationship("User", back_populates="favorites")
    book = relationship("Book", back_populates="favorites")

    __table_args__ = (
        UniqueConstraint("user_id", "book_id", name="uq_user_book_favorite"),
    )
