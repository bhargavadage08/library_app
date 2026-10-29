from datetime import datetime, timezone
from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from core.database import Base


class ReadingHistory(Base):
    __tablename__ = "reading_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    book_id = Column(Integer, nullable=False, index=True)
    title = Column(String, nullable=False, default="Unknown Book")
    author = Column(String, nullable=True)
    cover_url = Column(String, nullable=True)
    current_page = Column(Integer, default=1, nullable=False)
    total_pages = Column(Integer, nullable=True)
    progress_percent = Column(Integer, default=0, nullable=False)
    created_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    last_read_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    user = relationship("User", backref="reading_histories")

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "book_id",
            name="uq_user_book_history",
        ),
    )
