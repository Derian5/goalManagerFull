from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from core.database import get_db
from core.security import verify_password, get_password_hash, create_access_token
from schemas.auth import LoginRequest, RegisterRequest, LoginResponse, UserDto
from models.user import User

router = APIRouter()


@router.post("/register", response_model=LoginResponse)
@router.post("/register/", response_model=LoginResponse)

async def register(
        request: RegisterRequest,
        db: AsyncSession = Depends(get_db)
):
    # Проверяем, не занят ли username
    result = await db.execute(select(User).where(User.username == request.username))
    existing_user = result.scalar_one_or_none()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already registered"
        )

    # Определяем отображаемое имя
    name = request.name if request.name else request.username

    # Создаём пользователя
    hashed_password = get_password_hash(request.password)
    new_user = User(
        username=request.username,
        name=name,
        hashed_password=hashed_password
    )
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    # Создаём токен
    access_token = create_access_token(data={"sub": str(new_user.id)})

    # Формируем ответ
    user_dto = UserDto.model_validate(new_user)
    return LoginResponse(token=access_token, user=user_dto)


@router.post("/login", response_model=LoginResponse)
@router.post("/login/", response_model=LoginResponse)
async def login(
        request: LoginRequest,
        db: AsyncSession = Depends(get_db)
):
    # Ищем пользователя по username
    result = await db.execute(select(User).where(User.username == request.username))
    user = result.scalar_one_or_none()
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Создаём токен
    access_token = create_access_token(data={"sub": str(user.id)})

    # Формируем ответ
    user_dto = UserDto.model_validate(user)
    return LoginResponse(token=access_token, user=user_dto)