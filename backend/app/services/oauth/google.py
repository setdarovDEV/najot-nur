"""Google ID-token verification (mobile sign-in)."""
from __future__ import annotations

import httpx

from app.core.config import settings
from app.core.exceptions import UnauthorizedError
from app.core.logging import get_logger

log = get_logger("oauth.google")

TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo"


async def verify_google_token(id_token: str) -> dict:
    """Validate the Google ID token and return {sub, email, name, picture}.

    Uses Google's tokeninfo endpoint. Raises UnauthorizedError on failure.
    """
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(TOKENINFO_URL, params={"id_token": id_token})
    if resp.status_code != 200:
        raise UnauthorizedError("Google token yaroqsiz.")
    data = resp.json()

    if settings.google_client_id and data.get("aud") != settings.google_client_id:
        raise UnauthorizedError("Google token boshqa ilova uchun berilgan.")

    sub = data.get("sub")
    if not sub:
        raise UnauthorizedError("Google token tarkibi noto'g'ri.")
    return {
        "sub": sub,
        "email": data.get("email"),
        "name": data.get("name"),
        "picture": data.get("picture"),
    }
