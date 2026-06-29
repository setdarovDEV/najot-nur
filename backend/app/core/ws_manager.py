"""WebSocket connection manager for the support chat.

Holds the set of currently connected clients, partitioned by *side*:

* ``user_connections[user_id]``  → admin/curator-facing WebSocket for a
  specific mobile user. Mobile apps connect to ``/ws/support`` and
  register their ``user_id``.
* ``admin_connections``           → set of WebSockets belonging to
  curators/admins. They connect to ``/ws/admin`` and receive a
  notification for **every** support event (new user message, new
  admin reply, read receipt).
"""
from __future__ import annotations

import asyncio
import uuid
from collections import defaultdict
from typing import Any

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._user_connections: dict[uuid.UUID, set[WebSocket]] = defaultdict(set)
        self._admin_connections: set[WebSocket] = set()

    # ───────────────────── registration ─────────────────────
    async def connect_user(self, user_id: uuid.UUID, ws: WebSocket) -> None:
        await ws.accept()
        async with self._lock:
            self._user_connections[user_id].add(ws)

    async def connect_admin(self, ws: WebSocket) -> None:
        await ws.accept()
        async with self._lock:
            self._admin_connections.add(ws)

    async def disconnect(self, ws: WebSocket, *, user_id: uuid.UUID | None = None) -> None:
        async with self._lock:
            self._admin_connections.discard(ws)
            if user_id is not None:
                self._user_connections.get(user_id, set()).discard(ws)
                if not self._user_connections.get(user_id):
                    self._user_connections.pop(user_id, None)

    # ───────────────────── broadcasting ─────────────────────
    async def send_to_user(self, user_id: uuid.UUID, payload: dict[str, Any]) -> None:
        async with self._lock:
            targets = list(self._user_connections.get(user_id, ()))
        await self._fan_out(targets, payload)

    async def send_to_admins(self, payload: dict[str, Any]) -> None:
        async with self._lock:
            targets = list(self._admin_connections)
        await self._fan_out(targets, payload)

    @staticmethod
    async def _fan_out(targets: list[WebSocket], payload: dict[str, Any]) -> None:
        dead: list[WebSocket] = []
        for ws in targets:
            try:
                await ws.send_json(payload)
            except Exception:
                dead.append(ws)
        for ws in dead:
            try:
                await ws.close()
            except Exception:
                pass


connection_manager = ConnectionManager()
