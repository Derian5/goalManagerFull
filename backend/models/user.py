import uuid
from sqlalchemy import Column, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    username = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)  # отображаемое имя
    hashed_password = Column(String, nullable=False)

    goals = relationship("GlobalGoal", back_populates="user", cascade="all, delete-orphan")
    weeks = relationship("Week", back_populates="user", cascade="all, delete-orphan")