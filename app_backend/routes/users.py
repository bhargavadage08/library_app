from typing import List
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from core.database import get_db
from models.user import User
from schemas.user import UserResponse, UserUpdate
from services.user_service import UserService
from .deps import get_current_user

router = APIRouter()


@router.get(
    "",
    response_model=List[UserResponse],
    summary="List users",
)
def list_users(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    List registered users (requires authentication).
    """
    return UserService.get_users(db, skip=skip, limit=limit)


@router.get(
    "/{user_id}",
    response_model=UserResponse,
    summary="Get user by ID",
)
def get_user_by_id(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Get public profile information for a specific user.
    """
    user = UserService.get_by_id(db, user_id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return user


@router.put(
    "/me",
    response_model=UserResponse,
    summary="Update current user profile",
)
def update_my_profile(
    user_in: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Update profile details for the currently authenticated user.
    """
    return UserService.update_user(db, user=current_user, user_in=user_in)
