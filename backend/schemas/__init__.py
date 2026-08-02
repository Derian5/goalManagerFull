from .auth import UserDto, LoginRequest, LoginResponse, RegisterRequest
from .goal import GlobalGoalDto, CreateGlobalGoalRequest, UpdateGlobalGoalRequest, GlobalGoalsResponse
from .week import WeekDto, ActivityDto, CreateWeekRequest, UpdateWeekRequest, UpdateHoursRequest

__all__ = [
    "UserDto", "LoginRequest", "LoginResponse", "RegisterRequest",
    "GlobalGoalDto", "CreateGlobalGoalRequest", "UpdateGlobalGoalRequest", "GlobalGoalsResponse",
    "WeekDto", "ActivityDto", "CreateWeekRequest", "UpdateWeekRequest", "UpdateHoursRequest",
]