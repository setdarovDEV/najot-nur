"""JWT token blacklist backed by Redis.

Tokens are blacklisted on logout or when explicitly revoked. The TTL matches
the remaining lifetime of the token so entries expire automatically.
"""
from __future__ import annotations

from datetime import UTC, datetime

from app.core.logging import get_logger
from app.core.redis_client import get_redis

log = get_logger("auth.blacklist")


async def blacklist_token(jti: str, exp_timestamp: float) -> bool:
    """Add a token to the blacklist. Returns True on success."""
    r = get_redis()
    if r is None:
        return False

    now = datetime.now(UTC).timestamp()
    ttl = max(int(exp_timestamp - now), 1)
    key = f"token_blacklist:{jti}"

    try:
        await r.set(key, "1", ex=ttl)
        log.info("token.blacklisted", jti=jti, ttl=ttl)
        return True
    except Exception as exc:
        log.warning("token.blacklist_failed", jti=jti, error=str(exc))
        return False


async def is_token_blacklisted(jti: str) -> bool:
    """Check if a token has been revoked."""
    r = get_redis()
    if r is None:
        return False

    try:
        return bool(await r.exists(f"token_blacklist:{jti}"))
    except Exception as exc:
        log.warning("token.blacklist_check_failed", jti=jti, error=str(exc))
        return False


async def remove_from_blacklist(jti: str) -> None:
    """Remove a token from the blacklist (e.g. admin re-activation)."""
    r = get_redis()
    if r is None:
        return

    try:
        await r.delete(f"token_blacklist:{jti}")
    except Exception:
        pass
