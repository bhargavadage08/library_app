
from datetime import datetime, timezone

from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship

from core.database import Base
from .reading_history import ReadingHistory


class ReadingProgress(Base):
    __tablename__ = "reading_progress"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
    device_id = Column(String, nullable=True, index=True)
    book_id = Column(Integer, nullable=False, index=True)
    current_page = Column(Integer, default=1, nullable=False)
    total_pages = Column(Integer, default=1, nullable=False)
    percentage = Column(Float, default=0.0, nullable=False)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    user = relationship("User", backref="reading_progresses")

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "book_id",
            name="uq_user_book_progress",
        ),
    )
