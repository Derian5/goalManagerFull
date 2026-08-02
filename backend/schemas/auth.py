from pydantic import BaseModel, Field, ConfigDict
from uuid import UUID
from typing import Optional

from pydantic.alias_generators import to_camel


class UserDto(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        alias_generator=to_camel,
        populate_by_name=True
    )
    id: UUID
    username: str
    name: str

class LoginRequest(BaseModel):
    username: str
    password: str

class LoginResponse(BaseModel):
    token: str
    user: UserDto

class RegisterRequest(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=6)
    name: Optional[str] = Field(None, min_length=1, max_length=100)  # если не указано, можно установить = username