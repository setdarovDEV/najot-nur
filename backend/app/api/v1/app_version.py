"""Public app-version endpoint for forced/optional mobile updates.

Hit on cold start by the Flutter client. Public on purpose — the data
is non-sensitive (the Play Store URL is already public) and the
client needs the answer before it can decide whether to render the
login or home screen.
"""
from __future__ import annotations

from fastapi import APIRouter, Request

from app.core.config import settings
from app.schemas.app_version import AppVersionResponse

router = APIRouter()


def _pick_message(request: Request) -> str:
    """Pick a localised message based on the Accept-Language header.

    Falls back to UZ (the project's primary language) when the client
    doesn't advertise a supported locale.
    """
    header = (request.headers.get("accept-language") or "").lower()
    if header.startswith("en") and settings.app_update_message_en:
        return settings.app_update_message_en
    if header.startswith("ru") and settings.app_update_message_ru:
        return settings.app_update_message_ru
    return settings.app_update_message_uz


@router.get("/version", response_model=AppVersionResponse)
async def app_version(request: Request) -> AppVersionResponse:
    """Returns the current Play Store version + the minimum supported build.

    Mobile compares its own version+buildNumber to `min_supported_version`
    and to `force_update` to decide whether to show the blocking update
    dialog.
    """
    return AppVersionResponse(
        latest_version=settings.app_latest_version,
        min_supported_version=settings.app_min_supported_version,
        force_update=settings.app_force_update,
        update_url=settings.app_play_store_url,
        message=_pick_message(request),
    )
