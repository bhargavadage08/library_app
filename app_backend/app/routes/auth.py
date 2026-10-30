from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from core.database import get_db
from core.security import create_access_token
from models.user import User
from schemas.user import Token, UserCreate, UserLogin, UserResponse
from services.user_service import UserService
from .deps import get_current_user

router = APIRouter()


@router.post(
    "/register",
    response_model=Token,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new user",
)
def register(
    user_in: UserCreate,
    db: Session = Depends(get_db),
):
    """
    Register a new user with email, password, and optional full name.
    """
    existing = UserService.get_by_email(db, email=user_in.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists.",
        )

    user = UserService.create_user(db, user_in=user_in)
    access_token = create_access_token(subject=user.id)

    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.post(
    "/login",
    response_model=Token,
    summary="User Login",
)
def login(
    login_data: UserLogin,
    db: Session = Depends(get_db),
):
    """
    Authenticate with email and password to receive a JWT access token.
    """
    user = UserService.authenticate(
        db,
        email=login_data.email,
        password=login_data.password,
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is inactive",
        )

    access_token = create_access_token(subject=user.id)

    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Get current user profile",
)
def get_me(
    current_user: User = Depends(get_current_user),
):
    """
    Retrieve profile details for the currently authenticated user.
    """
    return current_user





@router.post(
    "/logout",
    status_code=status.HTTP_200_OK,
    summary="User Logout",
)
def logout(
    current_user: User = Depends(get_current_user),
):
    """
    Validate the current user's authentication and acknowledge logout.
    """
    return {"message": "Successfully logged out"}
