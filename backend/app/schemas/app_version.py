"""Schemas for the public mobile-app version endpoint."""
from __future__ import annotations

from pydantic import BaseModel, Field


class AppVersionResponse(BaseModel):
    """Version metadata the mobile client fetches on startup.

    * `latest_version` — newest build that's live on the Play Store.
    * `min_supported_version` — clients below this must update; the
      mobile client shows a blocking dialog.
    * `force_update` — global kill switch. When true, every active
      build is told to update regardless of `min_supported_version`.
    * `update_url` — Play Store deep link the user is sent to.
    * `message` — server-provided user-facing text (already localised
      by the backend based on the `Accept-Language` header).
    """

    latest_version: str = Field(..., examples=["1.2.0"])
    min_supported_version: str = Field(..., examples=["1.1.0"])
    force_update: bool = False
    update_url: str = Field(..., examples=["https://play.google.com/store/apps/details?id=uz.najotnur.notiqai"])
    message: str = ""
