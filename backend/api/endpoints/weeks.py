from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from typing import List, Optional

from sqlalchemy.orm.attributes import flag_modified

from core.database import get_db
from api.dependencies import get_current_active_user
from models.user import User
from models.week import Week
from models.activity import Activity
from models.global_goal import GlobalGoal
from schemas.week import (
    WeekDto,
    ActivityDto,
    CreateWeekRequest,
    UpdateWeekRequest,
    UpdateHoursRequest
)

router = APIRouter()


# Вспомогательная функция для загрузки недели с активностями
async def get_week_with_activities(week_id: str, user_id: str, db: AsyncSession):
    stmt = select(Week).where(
        Week.id == week_id,
        Week.user_id == user_id
    ).options(selectinload(Week.activities))
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


@router.get("/", response_model=List[WeekDto])
async def get_weeks(
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    # Без пагинации для простоты, можно добавить позже
    stmt = select(Week).where(
        Week.user_id == current_user.id
    ).options(selectinload(Week.activities)).order_by(Week.start_date.desc())
    result = await db.execute(stmt)
    weeks = result.scalars().all()
    return [WeekDto.model_validate(w) for w in weeks]

@router.post("/", response_model=WeekDto, status_code=status.HTTP_201_CREATED)
async def create_week(
        request: CreateWeekRequest,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    # Собираем все global_goal_id из активностей (исключая None)
    goal_ids = [act.global_goal_id for act in request.activities if act.global_goal_id]

    # Загружаем цели, чтобы проверить существование и получить цвета
    goals_map = {}
    if goal_ids:
        stmt = select(GlobalGoal).where(
            GlobalGoal.id.in_(goal_ids),
            GlobalGoal.user_id == current_user.id
        )
        result = await db.execute(stmt)
        goals = result.scalars().all()
        goals_map = {goal.id: goal for goal in goals}

        # Проверяем, что все указанные цели найдены
        found_ids = set(goals_map.keys())
        missing = set(goal_ids) - found_ids
        if missing:
            raise HTTPException(
                status_code=400,
                detail=f"Global goals with ids {missing} not found or not owned by user"
            )

    # Создаём неделю
    new_week = Week(
        user_id=current_user.id,
        start_date=request.start_date,
        end_date=request.end_date
    )
    db.add(new_week)
    await db.flush()  # получаем id недели

    # Создаём активности
    for act_req in request.activities:
        # Определяем цвет
        if act_req.color is not None:
            color = act_req.color
        elif act_req.global_goal_id is not None:
            # Берём цвет из цели
            goal = goals_map.get(act_req.global_goal_id)
            color = goal.color if goal else None
        else:
            color = None

        if color is None:
            raise HTTPException(
                status_code=400,
                detail="Color is required for activity without global goal"
            )

        activity = Activity(
            week_id=new_week.id,
            global_goal_id=act_req.global_goal_id,
            name=act_req.name,
            color=color,
            planned_hours=act_req.planned_hours,
            spent_hours=act_req.spent_hours or {}
        )
        db.add(activity)

    await db.commit()

    # Загружаем созданную неделю с активностями
    week = await get_week_with_activities(new_week.id, current_user.id, db)
    return WeekDto.model_validate(week)


@router.get("/{week_id}", response_model=WeekDto)
@router.get("/{week_id}/", response_model=WeekDto)

async def get_week(
        week_id: str,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    week = await get_week_with_activities(week_id, current_user.id, db)
    if not week:
        raise HTTPException(status_code=404, detail="Week not found")
    return WeekDto.model_validate(week)


@router.put("/{week_id}", response_model=WeekDto)
@router.put("/{week_id}/", response_model=WeekDto)

async def update_week(
        week_id: str,
        request: UpdateWeekRequest,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    week = await get_week_with_activities(week_id, current_user.id, db)
    if not week:
        raise HTTPException(status_code=404, detail="Week not found")

    # Обновляем поля недели, если переданы
    if request.startDate is not None:
        week.start_date = request.startDate
    if request.endDate is not None:
        week.end_date = request.endDate

    # Если передан список активностей, заменяем все существующие
    if request.activities is not None:
        # Проверка целей (аналогично созданию)
        goal_ids = [act.globalGoalId for act in request.activities if act.globalGoalId]
        if goal_ids:
            stmt = select(GlobalGoal.id).where(
                GlobalGoal.id.in_(goal_ids),
                GlobalGoal.user_id == current_user.id
            )
            result = await db.execute(stmt)
            existing_ids = set(row[0] for row in result.fetchall())
            missing = set(goal_ids) - existing_ids
            if missing:
                raise HTTPException(
                    status_code=400,
                    detail=f"Global goals with ids {missing} not found or not owned by user"
                )

        # Удаляем старые активности
        for act in week.activities:
            await db.delete(act)

        # Создаём новые
        for act_req in request.activities:
            activity = Activity(
                week_id=week.id,
                global_goal_id=act_req.globalGoalId,
                name=act_req.name,
                color=act_req.color,
                planned_hours=act_req.plannedHours,
                spent_hours=act_req.spentHours or {}
            )
            db.add(activity)

    await db.commit()

    # Перезагружаем с активностями
    updated_week = await get_week_with_activities(week_id, current_user.id, db)
    return WeekDto.model_validate(updated_week)


@router.delete("/{week_id}", status_code=status.HTTP_204_NO_CONTENT)
@router.delete("/{week_id}/", status_code=status.HTTP_204_NO_CONTENT)

async def delete_week(
        week_id: str,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    week = await get_week_with_activities(week_id, current_user.id, db)
    if not week:
        raise HTTPException(status_code=404, detail="Week not found")

    await db.delete(week)
    await db.commit()
    return None


@router.patch("/{week_id}/hours", response_model=ActivityDto)
@router.patch("/{week_id}/hours/", response_model=ActivityDto)

async def update_activity_hours_by_week(
        week_id: str,
        request: UpdateHoursRequest,
        current_user: User = Depends(get_current_active_user),
        db: AsyncSession = Depends(get_db)
):
    """
    Обновляет потраченные часы для конкретной активности в рамках указанной недели.
    - `week_id` — идентификатор недели (для проверки принадлежности)
    - В теле запроса передаётся `UpdateHoursRequest` с `activityId`, `hourIndex`, `spentHours`
    """
    # Проверяем, что активность принадлежит указанной неделе и пользователю
    stmt = select(Activity).join(Week).where(
        Activity.id == request.activityId,
        Week.id == week_id,
        Week.user_id == current_user.id
    )
    result = await db.execute(stmt)
    activity = result.scalar_one_or_none()

    if not activity:
        raise HTTPException(
            status_code=404,
            detail="Activity not found in this week or you don't have permission"
        )

    # Обновляем поле spent_hours (JSON)
    hour_key = str(request.hourIndex)
    current_spent = activity.spent_hours or {}
    current_spent[hour_key] = request.spentHours
    activity.spent_hours = current_spent
    flag_modified(activity, "spent_hours")  # <-- принудительно помечаем поле как изменённое

    print(f"Before commit: {activity.spent_hours}")
    await db.commit()
    print("Commit done")
    await db.refresh(activity)
    print(f"After refresh: {activity.spent_hours}")

    return ActivityDto.model_validate(activity)