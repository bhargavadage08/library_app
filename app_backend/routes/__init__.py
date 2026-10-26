from fastapi import APIRouter
from .auth import router as auth_router
from .books import router as books_router
from .users import router as users_router

api_router = APIRouter()

api_router.include_router(
    auth_router,
    prefix="/auth",
    tags=["Authentication"],
)

api_router.include_router(
    books_router,
    prefix="/books",
    tags=["Books & Library"],
)

api_router.include_router(
    users_router,
    prefix="/users",
    tags=["Users"],
)

__all__ = ["api_router"]
