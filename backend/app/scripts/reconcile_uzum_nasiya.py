"""Reconcile pending Uzum Nasiya contracts.

Run manually:

    docker compose exec backend python -m app.scripts.reconcile_uzum_nasiya

Or add to crontab (host/scheduler) every 2 minutes:

    */2 * * * * docker compose exec -T backend python -m app.scripts.reconcile_uzum_nasiya

The script polls Uzum Nasiya for pending contracts. If the buyer has already
signed the contract in the WebView, the partner confirm call is made
automatically so the payment does not get stuck. Contracts that stay unsigned
for too long are cancelled to free the buyer's limit.
"""
from __future__ import annotations

import asyncio
import os
import sys

# Allow running both as `python -m app.scripts.reconcile_uzum_nasiya` and from
# the repo root as `python backend/app/scripts/reconcile_uzum_nasiya.py`.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from app.core.database import AsyncSessionLocal
from app.core.logging import configure_logging, get_logger
from app.services import payment_service

log = get_logger("reconcile_uzum_nasiya")


async def main() -> None:
    configure_logging()
    async with AsyncSessionLocal() as db:
        summary = await payment_service.auto_reconcile_uzum_nasiya(db)
        await db.commit()
    log.info("reconcile_uzum_nasiya.done", summary=summary)
    print(
        f"Reconcile done: "
        f"confirmed={summary['confirmed']}, "
        f"cancelled={summary['cancelled']}, "
        f"already_paid={summary['already_paid']}, "
        f"errors={summary['errors']}"
    )
    # Exit non-zero only on hard errors so cron/scheduler can alert.
    if summary["errors"]:
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
