"""Server-side speech-to-text (STT) — TZ §3.1.

Turns an uploaded audio file into a transcript **with word-level timestamps**
so the deep char-level analysis can attach per-word timing / speech-rate
(TZ §3.5.4). The primary provider is Groq's hosted Whisper large-v3, exposed
through an OpenAI-compatible ``/audio/transcriptions`` endpoint.

Mirroring ``ai/client.py``: when no STT provider is configured (or a request
fails) ``transcribe`` returns ``None`` and the caller keeps working with a
client-supplied transcript — the app stays usable offline / in dev.
"""
from __future__ import annotations

from typing import Any

import httpx

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("stt")


def _normalize(data: dict[str, Any]) -> dict[str, Any]:
    """Coerce a Whisper ``verbose_json`` payload into our stable shape."""
    words: list[dict[str, Any]] = []
    for w in data.get("words") or []:
        word = (w.get("word") or "").strip()
        if not word:
            continue
        words.append(
            {
                "word": word,
                "start": float(w.get("start", 0.0)),
                "end": float(w.get("end", 0.0)),
            }
        )
    return {
        "text": (data.get("text") or "").strip(),
        "words": words,
        "duration": float(data.get("duration") or 0.0),
        "language": data.get("language") or settings.stt_language,
    }


async def _groq_transcribe(
    *, data: bytes, filename: str, content_type: str | None, language: str
) -> dict[str, Any] | None:
    api_key = settings.effective_groq_key
    if not api_key:
        return None
    url = f"{settings.groq_base_url.rstrip('/')}/audio/transcriptions"
    files = {"file": (filename, data, content_type or "application/octet-stream")}
    # Whisper params per TZ §3.1.2: verbose_json + word timestamps, temp 0.
    form = {
        "model": settings.groq_stt_model,
        "response_format": "verbose_json",
        "timestamp_granularities[]": "word",
        "temperature": "0",
    }
    if language:
        form["language"] = language
    headers = {"Authorization": f"Bearer {api_key}"}
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            r = await client.post(url, data=form, files=files, headers=headers)
        if r.status_code >= 400:
            log.error("stt.groq_http_error", status=r.status_code, body=r.text[:500])
            return None
        return _normalize(r.json())
    except Exception as exc:  # pragma: no cover - network dependent
        log.error("stt.groq_failed", error=str(exc))
        return None


async def transcribe(
    *,
    data: bytes,
    filename: str,
    content_type: str | None = None,
    language: str | None = None,
) -> dict[str, Any] | None:
    """Transcribe audio bytes via the configured provider, or ``None``.

    Returns ``{"text", "words": [{"word","start","end"}], "duration", "language"}``.
    """
    lang = language or settings.stt_language
    if settings.stt_provider == "groq":
        return await _groq_transcribe(
            data=data, filename=filename, content_type=content_type, language=lang
        )
    # openai_whisper / google share the OpenAI-compatible contract via the same
    # generic key; only Groq is wired up for now.
    return None
