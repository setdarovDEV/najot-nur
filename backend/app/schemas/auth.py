"""Auth request/response schemas."""
from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class RefreshRequest(BaseModel):
    refresh_token: str


# ───── Phone OTP ─────
class PhoneRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?\d{9,15}$", examples=["+998901234567"])


class OTPVerifyRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?\d{9,15}$")
    code: str = Field(..., min_length=4, max_length=8)
    full_name: str | None = Field(None, max_length=160)
    # Optional registration fields (used when this is the user's first login)
    first_name: str | None = Field(None, max_length=80)
    last_name: str | None = Field(None, max_length=80)
    password: str | None = Field(None, min_length=6, max_length=128)
    offer_accepted: bool = False


class PhoneExistsResponse(BaseModel):
    exists: bool
    has_password: bool


class PhoneLoginRequest(BaseModel):
    phone: str = Field(..., pattern=r"^\+?\d{9,15}$")
    password: str = Field(..., min_length=6, max_length=128)


# ───── OAuth ─────
class GoogleAuthRequest(BaseModel):
    id_token: str = Field(..., description="Google ID token from the mobile client")


class TelegramAuthRequest(BaseModel):
    """Payload from the Telegram Login Widget (hash-verified server-side)."""

    id: int
    first_name: str | None = None
    last_name: str | None = None
    username: str | None = None
    photo_url: str | None = None
    auth_date: int
    hash: str


# ───── Email/password (admin & curators) ─────
class EmailLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=6)


class AuthResult(BaseModel):
    is_new_user: bool
    tokens: TokenPair
