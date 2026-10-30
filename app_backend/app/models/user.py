from datetime import datetime, timezone
from sqlalchemy import Boolean, Column, DateTime, Integer, String
from sqlalchemy.orm import relationship
from core.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, default="Reader")
    is_active = Column(Boolean, default=True)
    created_at = Column(
        DateTime,
        default=lambda: datetime.now(timezone.utc),
    )

    # Relationships
    favorites = relationship(
        "FavoriteBook",
        back_populates="user",
        cascade="all, delete-orphan",
    )
