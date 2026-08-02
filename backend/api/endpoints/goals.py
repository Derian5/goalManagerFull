from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List, Optional
from core.database import get_db
from api.dependencies import get_current_active_user
from models.user import User
from models.global_goal import GlobalGoal
from schemas.goal import (
    GlobalGoalDto,
    CreateGlobalGoalRequest,
    UpdateGlobalGoalRequest,
    GlobalGoalsResponse
)

router = APIRouter()


@router.get("/", response_model=GlobalGoalsResponse)
async def get_goals(
        page: int = 1,
        limit: int = 10,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    # Пагинация
    offset = (page - 1) * limit

    # Запрос целей пользователя
    stmt = select(GlobalGoal).where(
        GlobalGoal.user_id == current_user.id
    ).offset(offset).limit(limit)
    result = await db.execute(stmt)
    goals = result.scalars().all()

    # Общее количество
    count_stmt = select(func.count()).select_from(GlobalGoal).where(
        GlobalGoal.user_id == current_user.id
    )
    total = await db.scalar(count_stmt)

    return GlobalGoalsResponse(
        goals=[GlobalGoalDto.model_validate(g) for g in goals],
        total=total or 0,
        page=page,
        limit=limit
    )


@router.post("/", response_model=GlobalGoalDto, status_code=status.HTTP_201_CREATED)
async def create_goal(
        request: CreateGlobalGoalRequest,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    new_goal = GlobalGoal(
        user_id=current_user.id,
        name=request.name,
        description=request.description,
        category=request.category,
        color=request.color
    )
    db.add(new_goal)
    await db.commit()
    await db.refresh(new_goal)
    return GlobalGoalDto.model_validate(new_goal)


@router.get("/{goal_id}", response_model=GlobalGoalDto)
@router.get("/{goal_id}/", response_model=GlobalGoalDto)

async def get_goal(
        goal_id: str,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    stmt = select(GlobalGoal).where(
        GlobalGoal.id == goal_id,
        GlobalGoal.user_id == current_user.id
    )
    result = await db.execute(stmt)
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    return GlobalGoalDto.model_validate(goal)


@router.put("/{goal_id}", response_model=GlobalGoalDto)
@router.put("/{goal_id}/", response_model=GlobalGoalDto)

async def update_goal(
        goal_id: str,
        request: UpdateGlobalGoalRequest,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    stmt = select(GlobalGoal).where(
        GlobalGoal.id == goal_id,
        GlobalGoal.user_id == current_user.id
    )
    result = await db.execute(stmt)
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")

    # Обновляем только переданные поля
    update_data = request.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(goal, field, value)

    await db.commit()
    await db.refresh(goal)
    return GlobalGoalDto.model_validate(goal)


@router.delete("/{goal_id}", status_code=status.HTTP_204_NO_CONTENT)
@router.delete("/{goal_id}/", status_code=status.HTTP_204_NO_CONTENT)

async def delete_goal(
        goal_id: str,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    stmt = select(GlobalGoal).where(
        GlobalGoal.id == goal_id,
        GlobalGoal.user_id == current_user.id
    )
    result = await db.execute(stmt)
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")

    await db.delete(goal)
    await db.commit()
    return None