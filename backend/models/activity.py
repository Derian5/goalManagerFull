import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, DateTime, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from core.database import Base

class Activity(Base):
    __tablename__ = "activities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    week_id = Column(UUID(as_uuid=True), ForeignKey("weeks.id", ondelete="CASCADE"), nullable=False, index=True)
    global_goal_id = Column(UUID(as_uuid=True), ForeignKey("global_goals.id", ondelete="SET NULL"), nullable=True)
    name = Column(String, nullable=False)
    color = Column(String, nullable=False)
    planned_hours = Column(Integer, nullable=False)
    spent_hours = Column(JSON, nullable=False, default=dict)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    week = relationship("Week", back_populates="activities")
    global_goal = relationship("GlobalGoal", back_populates="activities")