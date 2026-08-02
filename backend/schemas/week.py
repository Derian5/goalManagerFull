from pydantic import BaseModel, Field, ConfigDict
from uuid import UUID
from datetime import date, datetime
from typing import Optional, List, Dict

from pydantic.alias_generators import to_camel


class ActivityDto(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True
    )
    id: UUID
    name: str
    global_goal_id: Optional[UUID] = None  # globalGoalId
    planned_hours: int                     # plannedHours
    spent_hours: Dict[str, float]          # spentHours

class WeekDto(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True
    )
    id: UUID
    user_id: UUID
    start_date: date       # startDate
    end_date: date         # endDate
    activities: List[ActivityDto]
    created_at: datetime   # createdAt

class CreateActivityRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )
    name: str
    global_goal_id: Optional[UUID] = None
    planned_hours: int
    spent_hours: Dict[str, float] = {}
    color: Optional[str] = None  # теперь необязательное

class CreateWeekRequest(BaseModel):
    model_config = ConfigDict(
        populate_by_name=True,  # разрешает обращаться по оригинальному имени (start_date)
        alias_generator=to_camel  # генерирует алиас в camelCase для каждого поля
    )
    start_date: date  # в JSON будет ожидаться startDate
    end_date: date  # endDate
    activities: List[CreateActivityRequest]

class UpdateWeekRequest(BaseModel):
    startDate: Optional[date] = None
    endDate: Optional[date] = None
    activities: Optional[List[CreateActivityRequest]] = None

class UpdateHoursRequest(BaseModel):
    activityId: UUID
    hourIndex: int = Field(..., ge=0, le=167)
    spentHours: float = Field(..., ge=0)