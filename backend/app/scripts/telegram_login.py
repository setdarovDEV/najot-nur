"""One-time setup: authenticate a working Telegram account for the
"Verification Codes" service and persist its StringSession to `.env`.

Run from the backend directory:

    python -m app.scripts.telegram_login

You will be prompted for the `api_id` / `api_hash` (get them at
https://my.telegram.org → "API development tools") and the phone
number of the account you want to use as the verification worker.

After successful login, this script writes
``TELEGRAM_SESSION=<string>`` into the project-root ``.env`` (and prints
it to stdout so you can copy it manually if the file is read-only).
"""
from __future__ import annotations

import asyncio
import os
import sys
from pathlib import Path

from telethon import TelegramClient
from telethon.errors import SessionPasswordNeededError


def _read_api_credentials() -> tuple[int, str]:
    """Read api_id / api_hash from env or stdin."""
    api_id = os.environ.get("TELEGRAM_API_ID", "").strip()
    api_hash = os.environ.get("TELEGRAM_API_HASH", "").strip()
    if not api_id:
        api_id = input("Telegram api_id: ").strip()
    if not api_hash:
        api_hash = input("Telegram api_hash: ").strip()
    try:
        return int(api_id), api_hash
    except ValueError as exc:
        raise SystemExit(
            "api_id butun son bo'lishi kerak (my.telegram.org'dan olingan)."
        ) from exc


def _read_phone() -> str:
    phone = os.environ.get("TELEGRAM_LOGIN_PHONE", "").strip()
    if not phone:
        phone = input("Telefon raqamingiz (xalqaro formatda, masalan +998901234567): ").strip()
    if not phone.startswith("+"):
        phone = f"+{phone}"
    return phone


def _write_session_to_env(session: str) -> None:
    """Best-effort: write TELEGRAM_SESSION into the project-root .env."""
    env_path = Path(__file__).resolve().parents[3] / ".env"
    if not env_path.exists():
        print(f"\n.env topilmadi ({env_path}). Session ni qo'lda qo'ying:")
        print(f"TELEGRAM_SESSION={session}")
        return
    text = env_path.read_text(encoding="utf-8")
    key = "TELEGRAM_SESSION="
    if key in text:
        lines = text.splitlines()
        lines = [f"{key}{session}" if line.startswith(key) else line for line in lines]
        text = "\n".join(lines)
        if not text.endswith("\n"):
            text += "\n"
    else:
        if not text.endswith("\n"):
            text += "\n"
        text += f"\n# ───── Telegram Login (Verification Codes) ─────\n{key}{session}\n"
    env_path.write_text(text, encoding="utf-8")
    print(f"\n✅ TELEGRAM_SESSION {env_path} ga yozildi.")


async def _login(api_id: int, api_hash: str, phone: str) -> str:
    client = TelegramClient(
        # Persist to a file so the user can resume if they Ctrl-C between
        # the code prompt and 2FA.
        "telegram_login_session",
        api_id,
        api_hash,
    )
    await client.connect()
    try:
        if not await client.is_user_authorized():
            sent = await client.send_code_request(phone)
            code = input("Telegram yuborgan kodni kiriting: ").strip()
            try:
                await client.sign_in(phone, code, phone_code_hash=sent.phone_code_hash)
            except SessionPasswordNeededError:
                pwd = input("2FA parol: ")
                await client.sign_in(password=pwd)
        me = await client.get_me()
        print(
            f"\nTelegram akkauntga kirildi: "
            f"{me.first_name} {me.last_name or ''} (@{me.username or 'no-username'})"
        )
        return client.session.save()
    finally:
        await client.disconnect()


async def main() -> None:
    api_id, api_hash = _read_api_credentials()
    phone = _read_phone()
    session = await _login(api_id, api_hash, phone)
    print("\nSession string (nusxa oling, xavfsiz joyda saqlang):")
    print(session)
    _write_session_to_env(session)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        sys.exit("\nBekor qilindi.")
