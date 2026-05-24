---
name: python-backend-skill
description: Scaffold and structure Python backend projects with FastAPI, Django, or Flask — project layout, dependency injection, configuration management, virtual environments, and pyproject.toml standards
license: Apache-2.0
compatibility: opencode
metadata:
  audience: developers
  workflow: project-setup
  languages: [python]
---

## What I do

I help you scaffold and structure Python backend projects following industry best practices:

1. **Project Scaffolding**: Create well-organized project structures for FastAPI, Django, or Flask
2. **Dependency Management**: Configure pyproject.toml, requirements files, and virtual environments
3. **Configuration Management**: Environment-based config with pydantic-settings
4. **Dependency Injection**: Wire up DI containers for testability
5. **Application Factory**: Implement the factory pattern for app initialization
6. **Project Standards**: Linting, formatting, type checking, and CI configuration

## When to use me

Use this skill when:
- Starting a new Python backend project
- Restructuring an existing Python project for better organization
- Setting up FastAPI, Django, or Flask with production-ready patterns
- Configuring pyproject.toml and dependency management
- Implementing environment-based configuration
- Setting up Python project standards (ruff, mypy, pytest)
- Migrating between Python frameworks

## Related Skills

- **python-pytest-creator-skill**: Generate tests for Python projects using these structures
- **python-ruff-linter-skill**: Lint and format Python code following these standards
- **nextjs-standard-setup-skill**: The Next.js equivalent of this Python scaffolding skill
- **database-migration-skill**: Alembic/Django migration workflows for Python backends

---

## Step 1: Choose Your Framework

| Framework | Best For | Async | ORM Agnostic | Admin UI |
|-----------|----------|-------|-------------|----------|
| **FastAPI** | APIs, microservices, async | Native | Yes | No |
| **Django** | Full-stack web apps, CMS | ASGI support | Django ORM | Yes |
| **Flask** | Simple APIs, microservices | Via extensions | Yes | No |

---

## Step 2: FastAPI Project Structure

```
project/
├── pyproject.toml
├── README.md
├── .env.example
├── .gitignore
├── Dockerfile
├── docker-compose.yml
├── alembic/
│   ├── env.py
│   └── versions/
├── src/
│   └── app/
│       ├── __init__.py
│       ├── main.py              # FastAPI app factory
│       ├── config.py            # Settings with pydantic
│       ├── dependencies.py      # Shared FastAPI dependencies
│       ├── models/              # SQLAlchemy models
│       │   ├── __init__.py
│       │   └── user.py
│       ├── schemas/             # Pydantic schemas
│       │   ├── __init__.py
│       │   └── user.py
│       ├── routers/             # API route modules
│       │   ├── __init__.py
│       │   └── users.py
│       ├── services/            # Business logic
│       │   ├── __init__.py
│       │   └── user_service.py
│       ├── repositories/        # Data access
│       │   ├── __init__.py
│       │   └── user_repository.py
│       └── middleware/           # Custom middleware
│           ├── __init__.py
│           └── logging.py
└── tests/
    ├── conftest.py
    ├── unit/
    └── integration/
```

### Application Factory

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.routers import users, health

def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.VERSION,
        docs_url="/docs" if settings.DEBUG else None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(users.router, prefix="/api/v1")

    @app.on_event("startup")
    async def startup():
        from app.database import engine
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)

    return app

app = create_app()
```

### Configuration with pydantic-settings

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    APP_NAME: str = "My API"
    VERSION: str = "1.0.0"
    DEBUG: bool = False

    DATABASE_URL: str
    DATABASE_POOL_SIZE: int = 5
    DATABASE_MAX_OVERFLOW: int = 10

    REDIS_URL: str = "redis://localhost:6379/0"

    SECRET_KEY: str
    ALLOWED_ORIGINS: list[str] = ["http://localhost:3000"]

    LOG_LEVEL: str = "INFO"

settings = Settings()
```

### Repository Pattern

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User

class UserRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_by_id(self, user_id: str) -> User | None:
        result = await self.session.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> User | None:
        result = await self.session.execute(select(User).where(User.email == email))
        return result.scalar_one_or_none()

    async def create(self, user: User) -> User:
        self.session.add(user)
        await self.session.flush()
        return user
```

### Dependency Injection

```python
from typing import Annotated
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import async_session_factory
from app.repositories.user_repository import UserRepository
from app.services.user_service import UserService

async def get_db():
    async with async_session_factory() as session:
        async with session.begin():
            yield session

async def get_user_repository(db: Annotated[AsyncSession, Depends(get_db)]) -> UserRepository:
    return UserRepository(db)

async def get_user_service(repo: Annotated[UserRepository, Depends(get_user_repository)]) -> UserService:
    return UserService(repo)

UserServiceDep = Annotated[UserService, Depends(get_user_service)]
```

---

## Step 3: Django Project Structure

```
project/
├── pyproject.toml
├── manage.py
├── config/
│   ├── __init__.py
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py
│   │   ├── development.py
│   │   └── production.py
│   ├── urls.py
│   └── wsgi.py
├── apps/
│   ├── __init__.py
│   ├── users/
│   │   ├── __init__.py
│   │   ├── models.py
│   │   ├── views.py
│   │   ├── serializers.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   └── tests/
│   └── orders/
│       └── ...
├── templates/
├── static/
└── requirements/
    ├── base.txt
    ├── development.txt
    └── production.txt
```

### Django Settings Split

```python
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent.parent

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "rest_framework",
    "apps.users",
    "apps.orders",
]

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "app_db"),
        "USER": os.environ.get("DB_USER", "postgres"),
        "PASSWORD": os.environ.get("DB_PASSWORD", ""),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}
```

---

## Step 4: Flask Project Structure

```
project/
├── pyproject.toml
├── src/
│   └── app/
│       ├── __init__.py         # Factory
│       ├── config.py
│       ├── extensions.py       # db, migrate, cors
│       ├── blueprints/
│       │   ├── __init__.py
│       │   └── users.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── user.py
│       └── services/
│           ├── __init__.py
│           └── user_service.py
└── tests/
```

### Flask Factory

```python
from flask import Flask
from app.extensions import db, migrate, cors
from app.config import config

def create_app(config_name="default"):
    app = Flask(__name__)
    app.config.from_object(config[config_name])

    db.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(app)

    from app.blueprints.users import users_bp
    app.register_blueprint(users_bp, url_prefix="/api/v1/users")

    return app
```

---

## Step 5: pyproject.toml Standard

```toml
[project]
name = "my-api"
version = "1.0.0"
description = "My API service"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "sqlalchemy[asyncio]>=2.0.0",
    "asyncpg>=0.29.0",
    "pydantic-settings>=2.1.0",
    "alembic>=1.13.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "httpx>=0.27.0",
    "ruff>=0.2.0",
    "mypy>=1.8.0",
]

[tool.ruff]
target-version = "py312"
line-length = 120
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "SIM", "C4"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"

[tool.mypy]
python_version = "3.12"
strict = true
plugins = ["pydantic.mypy"]
```

---

## Step 6: Virtual Environment Management

### uv (Recommended)

```bash
uv venv --python 3.12
source .venv/bin/activate
uv pip install -e ".[dev]"
```

### Standard venv

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
```

### .env.example

```
APP_NAME=My API
VERSION=1.0.0
DEBUG=true
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/app_dev
REDIS_URL=redis://localhost:6379/0
SECRET_KEY=change-me-in-production
LOG_LEVEL=DEBUG
ALLOWED_ORIGINS=["http://localhost:3000"]
```
