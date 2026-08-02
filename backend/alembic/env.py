import asyncio
from logging.config import fileConfig

from sqlalchemy import pool, engine_from_config, create_engine, NullPool
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config

from alembic import context

# Импортируем Base из нашего приложения и модели, чтобы autogenerate видел их
from core.database import Base
from models import User, GlobalGoal, Week, Activity   # noqa: F401

# Импортируем настройки для получения URL базы данных
from core.config import settings

# this is the Alembic Config object, which provides access to the values within the .ini file
config = context.config

# Заменяем URL из .ini на синхронный URL из настроек приложения
# Преобразуем асинхронный URL (postgresql+asyncpg://...) в синхронный (postgresql://...)
sync_database_url = settings.DATABASE_URL.replace('+asyncpg', '')
config.set_main_option('sqlalchemy.url', sync_database_url)

# Interpret the config file for Python logging.
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Добавляем метаданные для autogenerate
target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def do_run_migrations(connection: Connection) -> None:
    """Синхронная функция, выполняющая миграции на переданном соединении."""
    context.configure(connection=connection, target_metadata=target_metadata)

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = create_engine(
        config.get_main_option("sqlalchemy.url"),
        poolclass=NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()