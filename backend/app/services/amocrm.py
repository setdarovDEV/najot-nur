"""AMOCRM integration — push a lead when a user registers.

No-op (logs only) until AMOCRM credentials are configured. Designed to be called
fire-and-forget so registration latency is never blocked by CRM availability.
"""
from __future__ import annotations

import httpx

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("amocrm")


async def push_lead(
    *, full_name: str | None, phone: str | None, email: str | None, source: str
) -> bool:
    if not settings.amocrm_base_url or not settings.amocrm_access_token:
        log.info("amocrm.skip_not_configured", phone=phone, source=source)
        return False

    name = full_name or phone or email or "NotiqAI foydalanuvchi"
    custom_fields = []
    if phone:
        custom_fields.append(
            {"field_code": "PHONE", "values": [{"value": phone}]}
        )
    if email:
        custom_fields.append(
            {"field_code": "EMAIL", "values": [{"value": email}]}
        )

    payload = [
        {
            "name": f"NotiqAI — {name}",
            "pipeline_id": settings.amocrm_pipeline_id or None,
            "responsible_user_id": settings.amocrm_responsible_user_id or None,
            "_embedded": {
                "contacts": [
                    {"name": name, "custom_fields_values": custom_fields or None}
                ],
                "tags": [{"name": "NotiqAI"}, {"name": source}],
            },
        }
    ]
    try:  # pragma: no cover - network dependent
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(
                f"{settings.amocrm_base_url.rstrip('/')}/api/v4/leads/complex",
                headers={
                    "Authorization": f"Bearer {settings.amocrm_access_token}",
                    "Content-Type": "application/json",
                },
                json=payload,
            )
        ok = resp.status_code in (200, 201)
        log.info("amocrm.lead_pushed", status=resp.status_code, ok=ok)
        return ok
    except Exception as exc:
        log.error("amocrm.push_failed", error=str(exc))
        return False
