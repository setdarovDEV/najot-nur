"""Async LLM client supporting Groq (Llama), Gemini, Claude, and dual-ensemble mode.

Dual mode runs Groq + Gemini in parallel and merges their outputs for maximum
quality — Groq handles fast word-level analysis, Gemini adds rich phoneme
coaching. Each provider degrades gracefully to None on failure.

Provider selection is driven by the AI_PROVIDER setting:
  mock   → always None (deterministic fallback only)
  groq   → Groq Llama via OpenAI-compatible chat completions with JSON mode
  gemini → Google Gemini with responseSchema enforcement
  dual   → Groq + Gemini in parallel, results merged
  claude → Anthropic (legacy, kept for backward compat)
"""
from __future__ import annotations

import asyncio
import json
from typing import Any

import httpx

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("ai")

_claude_client: Any | None = None


# ──────────────────────────── Groq LLM ──────────────────────────────────────

def _schema_to_prompt(schema: dict[str, Any]) -> str:
    """Render a JSON schema as a compact instruction for Groq's JSON mode."""
    try:
        return json.dumps(schema, ensure_ascii=False, separators=(",", ":"))
    except Exception:
        return "{}"


# Models tried in order when the primary is blocked at project level.
_GROQ_MODEL_FALLBACKS = [
    "llama-3.3-70b-versatile",
    "meta-llama/llama-4-scout-17b-16e-instruct",
    "llama-3.1-8b-instant",
    "qwen/qwen3-32b",
    "groq/compound",
    "groq/compound-mini",
]


async def _groq_llm_completion(
    *,
    system: str,
    user: str,
    input_schema: dict[str, Any],
    max_tokens: int,
    temperature: float = 0.15,
) -> dict[str, Any] | None:
    """Groq LLM via OpenAI-compatible /chat/completions with JSON mode.

    Tries the configured model first, then walks through the fallback list if
    the model is blocked at project level (Groq returns 403 with code
    'model_permission_blocked_project'). Schema is embedded in the system
    prompt for structural compliance.
    """
    api_key = settings.effective_groq_key
    if not api_key:
        return None

    schema_hint = _schema_to_prompt(input_schema)
    full_system = (
        f"{system}\n\n"
        "MUHIM: Javobni faqat quyidagi JSON sxemasiga mos tarzda qat'iy qaytaring. "
        "Hech qanday qo'shimcha matn yoki tushuntirish yozmang:\n"
        f"{schema_hint}"
    )

    primary = settings.groq_llm_model
    model_order = [primary] + [m for m in _GROQ_MODEL_FALLBACKS if m != primary]

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    }
    url = f"{settings.groq_base_url.rstrip('/')}/chat/completions"

    for model in model_order:
        payload: dict[str, Any] = {
            "model": model,
            "messages": [
                {"role": "system", "content": full_system},
                {"role": "user", "content": user},
            ],
            "response_format": {"type": "json_object"},
            "temperature": temperature,
            "max_tokens": max_tokens,
        }
        try:
            async with httpx.AsyncClient(timeout=45.0) as client:
                r = await client.post(url, json=payload, headers=headers)

            if r.status_code == 403:
                log.warning("ai.groq_model_blocked", model=model)
                continue  # try next fallback

            if r.status_code >= 400:
                log.error("ai.groq_llm_http_error", status=r.status_code,
                          model=model, body=r.text[:300])
                return None

            data = r.json()
            content = (
                (data.get("choices") or [{}])[0]
                .get("message", {})
                .get("content", "")
            )
            if not content:
                log.warning("ai.groq_llm_empty_content", model=model)
                return None

            if model != primary:
                log.info("ai.groq_fallback_used", model=model)
            return json.loads(content)

        except json.JSONDecodeError as exc:
            log.error("ai.groq_llm_json_error", model=model, error=str(exc))
            return None
        except Exception as exc:
            log.error("ai.groq_llm_failed", model=model, error=str(exc))
            return None

    log.error(
        "ai.groq_all_models_blocked",
        hint="Enable models at https://console.groq.com/settings/project/limits",
    )
    return None


# ──────────────────────────── Gemini ────────────────────────────────────────

async def _gemini_completion(
    *,
    system: str,
    user: str,
    input_schema: dict[str, Any],
    max_tokens: int,
    temperature: float = 0.3,
) -> dict[str, Any] | None:
    if not settings.gemini_api_key:
        return None
    base = settings.gemini_base_url.rstrip("/")
    url = f"{base}/models/{settings.gemini_model}:generateContent"
    payload: dict[str, Any] = {
        "systemInstruction": {"parts": [{"text": system}]},
        "contents": [{"role": "user", "parts": [{"text": user}]}],
        "generationConfig": {
            "temperature": temperature,
            "maxOutputTokens": max_tokens,
            "responseMimeType": "application/json",
            "responseSchema": input_schema,
        },
    }
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": settings.gemini_api_key,
    }
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            r = await client.post(url, json=payload, headers=headers)
        if r.status_code >= 400:
            log.error("ai.gemini_http_error", status=r.status_code, body=r.text[:400])
            return None
        data = r.json()
        candidates = data.get("candidates") or []
        if not candidates:
            log.warning("ai.gemini_no_candidates")
            return None
        parts = (candidates[0].get("content") or {}).get("parts") or []
        text = "".join(p.get("text", "") for p in parts if p.get("text"))
        if not text:
            log.warning("ai.gemini_empty_text")
            return None
        return json.loads(text)
    except json.JSONDecodeError as exc:
        log.error("ai.gemini_json_error", error=str(exc))
        return None
    except Exception as exc:
        log.error("ai.gemini_failed", error=str(exc))
        return None


# ──────────────────────────── Claude (legacy) ───────────────────────────────

def _get_claude() -> Any | None:
    global _claude_client
    if not settings.anthropic_api_key:
        return None
    if _claude_client is None:
        try:
            from anthropic import AsyncAnthropic
            _claude_client = AsyncAnthropic(api_key=settings.anthropic_api_key)
        except Exception as exc:
            log.warning("ai.claude_init_failed", error=str(exc))
            return None
    return _claude_client


async def _claude_completion(
    *,
    system: str,
    user: str,
    tool_name: str,
    tool_description: str,
    input_schema: dict[str, Any],
    max_tokens: int,
) -> dict[str, Any] | None:
    client = _get_claude()
    if client is None:
        return None
    try:
        resp = await client.messages.create(
            model=settings.ai_model,
            max_tokens=max_tokens,
            system=system,
            tools=[{"name": tool_name, "description": tool_description, "input_schema": input_schema}],
            tool_choice={"type": "tool", "name": tool_name},
            messages=[{"role": "user", "content": user}],
        )
        for block in resp.content:
            if getattr(block, "type", None) == "tool_use":
                return dict(block.input)
        return None
    except Exception as exc:
        log.error("ai.claude_failed", error=str(exc))
        return None


# ──────────────────────────── Dual ensemble ─────────────────────────────────

def _merge(groq_result: dict | None, gemini_result: dict | None) -> dict | None:
    """Merge Groq + Gemini outputs.

    Strategy:
    - Start with Groq result (faster, more factual for Uzbek word errors).
    - Overlay any NON-EMPTY fields from Gemini (richer coaching).
    - Fields that Gemini typically enriches: phoneme_tips, minimal_pairs,
      audio_exercise_text, tongue_position notes.
    - Fields Groq typically handles better: summary, phoneme_errors, word_feedback.
    """
    if groq_result is None and gemini_result is None:
        return None
    if groq_result is None:
        return gemini_result
    if gemini_result is None:
        return groq_result

    merged = dict(groq_result)
    for key, val in gemini_result.items():
        if key not in merged or not merged[key]:
            # Gemini has something Groq didn't produce
            merged[key] = val
        elif isinstance(val, list) and isinstance(merged.get(key), list):
            # Gemini list is richer (more tips, more pairs) → prefer longer
            if len(val) > len(merged[key]):
                merged[key] = val
        elif isinstance(val, str) and isinstance(merged.get(key), str):
            # Prefer longer text (more detail) from either provider
            if len(val) > len(merged.get(key, "")):
                merged[key] = val
    return merged


async def _dual_completion(
    *,
    system: str,
    user: str,
    input_schema: dict[str, Any],
    max_tokens: int,
    temperature: float = 0.2,
) -> dict[str, Any] | None:
    """Run Groq and Gemini concurrently and merge their outputs."""
    groq_task = _groq_llm_completion(
        system=system, user=user, input_schema=input_schema,
        max_tokens=max_tokens, temperature=temperature,
    )
    gemini_task = _gemini_completion(
        system=system, user=user, input_schema=input_schema,
        max_tokens=max_tokens, temperature=temperature,
    )
    groq_result, gemini_result = await asyncio.gather(
        groq_task, gemini_task, return_exceptions=False
    )
    result = _merge(groq_result, gemini_result)
    if result is not None:
        log.info(
            "ai.dual_merge",
            groq_ok=groq_result is not None,
            gemini_ok=gemini_result is not None,
        )
    return result


# ──────────────────────────── Public API ────────────────────────────────────

async def structured_completion(
    *,
    system: str,
    user: str,
    tool_name: str = "record_result",
    tool_description: str = "Return structured result.",
    input_schema: dict[str, Any],
    max_tokens: int = 2000,
    temperature: float = 0.2,
) -> dict[str, Any] | None:
    """Dispatch to the configured LLM provider and return structured JSON.

    Returns None when the provider is not configured or the call fails —
    callers fall back to their deterministic implementation.
    """
    provider = settings.ai_provider

    if provider == "dual":
        return await _dual_completion(
            system=system, user=user, input_schema=input_schema,
            max_tokens=max_tokens, temperature=temperature,
        )
    if provider == "groq":
        return await _groq_llm_completion(
            system=system, user=user, input_schema=input_schema,
            max_tokens=max_tokens, temperature=temperature,
        )
    if provider == "gemini":
        return await _gemini_completion(
            system=system, user=user, input_schema=input_schema,
            max_tokens=max_tokens, temperature=temperature,
        )
    if provider == "claude":
        return await _claude_completion(
            system=system, user=user,
            tool_name=tool_name, tool_description=tool_description,
            input_schema=input_schema, max_tokens=max_tokens,
        )
    return None


async def groq_completion(
    *,
    system: str,
    user: str,
    input_schema: dict[str, Any],
    max_tokens: int = 2000,
    temperature: float = 0.15,
) -> dict[str, Any] | None:
    """Direct Groq call — used in dual-pass analyzers for the fast path."""
    if not settings.effective_groq_key:
        return None
    return await _groq_llm_completion(
        system=system, user=user, input_schema=input_schema,
        max_tokens=max_tokens, temperature=temperature,
    )


async def gemini_completion(
    *,
    system: str,
    user: str,
    input_schema: dict[str, Any],
    max_tokens: int = 2000,
    temperature: float = 0.3,
) -> dict[str, Any] | None:
    """Direct Gemini call — used in dual-pass analyzers for the coaching path."""
    if not settings.gemini_api_key:
        return None
    return await _gemini_completion(
        system=system, user=user, input_schema=input_schema,
        max_tokens=max_tokens, temperature=temperature,
    )
