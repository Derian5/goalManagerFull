from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from core.config import settings
from api.endpoints import auth, goals, weeks

app = FastAPI(title=settings.PROJECT_NAME, version=settings.VERSION, redirect_slashes=False)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Здесь будут подключены роутеры
# from app.api.endpoints import auth, goals, weeks
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(goals.router, prefix="/goals", tags=["goals"])
app.include_router(weeks.router, prefix="/weeks", tags=["weeks"])

@app.get("/")
async def root():
    return {"message": "Hello World"}