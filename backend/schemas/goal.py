from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel
from uuid import UUID
from datetime import datetime
from typing import Optional, List


class GlobalGoalDto(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True
    )
    id: UUID
    user_id: UUID          # в БД поле user_id, в JSON будет userId
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    color: str
    created_at: datetime    # в JSON createdAt
    updated_at: Optional[datetime] = None  # в JSON updatedAt
    is_active: bool         # в JSON isActive


class CreateGlobalGoalRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=100)
    color: str = Field(..., pattern=r"^#[0-9A-Fa-f]{6}$")

class UpdateGlobalGoalRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=500)
    category: Optional[str] = Field(None, max_length=100)
    color: Optional[str] = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    isActive: Optional[bool] = None

class GlobalGoalsResponse(BaseModel):
    goals: List[GlobalGoalDto]
    total: int
    page: int
    limit: int