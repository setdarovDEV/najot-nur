"""Payment orchestration service — Uzum Bank, Uzum Nasiya, ATMOS.

Real HTTP calls are made when API keys are present in settings.
In development (keys absent), a mock redirect URL is returned so the
rest of the flow (DB record, callbacks) can be exercised without live keys.
"""
from __future__ import annotations

import base64
import hashlib
import hmac
import time
import uuid
from collections import deque
from datetime import UTC, datetime
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import AppError, NotFoundError
from app.core.logging import get_logger
from app.models.audiobook import Audiobook, AudiobookAccess
from app.models.course import Course, Enrollment, Lesson
from app.models.enums import (
    EnrollmentStatus,
    HomeworkStatus,
    PaymentProvider,
    PaymentPurpose,
    PaymentStatus,
    PushAudience,
)
from app.models.grading import Homework
from app.models.notification import PushNotification, PushToken
from app.models.payment import Payment
from app.models.user import User
from app.services import fcm

log = get_logger("payment_service")

# ──────────────────────────────────────────────
#  Provider base URLs  (change to sandbox for testing)
# ──────────────────────────────────────────────

_UZUM_BASE = "https://api.paymart.uz"
_ATMOS_BASE = "https://partner.atmos.uz"
# Uzum Nasiya base URL is configurable (sandbox vs production) —
# see settings.uzum_nasiya_base_url.

_HTTP_TIMEOUT = 20.0  # seconds


# ──────────────────────────────────────────────
#  Internal DB helpers
# ──────────────────────────────────────────────


async def _create_payment(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None,
    purpose: PaymentPurpose,
    provider: PaymentProvider,
) -> Payment:
    payment = Payment(
        user_id=user_id,
        amount=amount,
        currency="UZS",
        provider=provider,
        status=PaymentStatus.pending,
        purpose=purpose,
        reference_id=reference_id,
    )
    db.add(payment)
    await db.flush()
    return payment


async def _get_payment_by_external_id(db: AsyncSession, external_id: str) -> Payment:
    row = (
        await db.execute(
            select(Payment).where(Payment.external_id == external_id)
        )
    ).scalar_one_or_none()
    if row is None:
        raise NotFoundError(f"To'lov topilmadi: external_id={external_id}")
    return row


# ──────────────────────────────────────────────
#  Uzum Bank  (paymart.uz)
# ──────────────────────────────────────────────
#
#  Docs: https://developer.paymart.uz
#  Auth: Basic  (merchantId:secretKey → base64)
#  POST /v1/payment
#    body  → { orderId, amount (tiyin), returnUrl, failedUrl, currency }
#    resp  → { paymentId, paymentUrl }
# ──────────────────────────────────────────────


async def initiate_uzum(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> tuple[Payment, str]:
    """Create a pending Payment record and initiate a Uzum Bank checkout.

    Returns (payment, redirect_url).
    """
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.uzum,
    )

    if settings.uzum_merchant_id and settings.uzum_secret_key:
        credentials = base64.b64encode(
            f"{settings.uzum_merchant_id}:{settings.uzum_secret_key}".encode()
        ).decode()

        try:
            async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
                resp = await client.post(
                    f"{_UZUM_BASE}/v1/payment",
                    headers={
                        "Authorization": f"Basic {credentials}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "orderId": str(payment.id),
                        "amount": int(amount * 100),   # tiyin
                        "currency": "UZS",
                        "returnUrl": return_url,
                        "failedUrl": return_url,
                        "merchantId": settings.uzum_merchant_id,
                    },
                )
                resp.raise_for_status()
                data: dict[str, Any] = resp.json()

            external_id = str(
                data.get("paymentId") or data.get("id") or payment.id
            )
            redirect_url: str = (
                data.get("paymentUrl") or data.get("url")
                or f"https://checkout.uzum.uz/pay/{external_id}"
            )
            payment.external_id = external_id
            log.info(
                "uzum.initiated",
                payment_id=str(payment.id),
                external_id=external_id,
                amount=amount,
            )

        except httpx.HTTPStatusError as exc:
            log.error(
                "uzum.api_error",
                status=exc.response.status_code,
                body=exc.response.text,
                payment_id=str(payment.id),
            )
            raise AppError(
                f"Uzum Bank xatoligi: {exc.response.status_code} — {exc.response.text}",
                status_code=502,
            ) from exc

        except httpx.RequestError as exc:
            log.error("uzum.network_error", error=str(exc), payment_id=str(payment.id))
            raise AppError("Uzum Bank bilan aloqa yo'q.", status_code=502) from exc

    else:
        # Development stub — no real API call
        mock_external_id = f"uzum_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.uzum.uz/pay?order_id={payment.id}"
        log.warning(
            "uzum.stub_mode",
            hint="UZUM_MERCHANT_ID va UZUM_SECRET_KEY o'rnatilmagan",
            payment_id=str(payment.id),
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="uzum",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
    )
    return payment, redirect_url


# ──────────────────────────────────────────────
#  Uzum Nasiya  (bo'lib-bo'lib to'lash)
# ──────────────────────────────────────────────
#
#  Docs: https://developer.uzumbank.uz/nasiya  (OpenAPI: "Uzum Nasiya Partner API")
#  Auth: Bearer {uzum_nasiya_api_key}
#  Base: settings.uzum_nasiya_base_url
#    sandbox → https://dev-merchants-api.uzumnasiya.uz
#    prod    → https://merchants-api.uzumnasiya.uz
#
#  Flow (see docs "Процесс оформления договора"):
#   1. POST /api/v1/buyers/check-status  {phone}
#        → {status, buyer_id, webview, available_periods, ...}
#        status == 4 means the buyer is verified and can take a contract;
#        any other status means the app must send the user to `webview`
#        to finish Uzum's own registration first.
#   2. (optional) POST /api/v1/orders/calculate {user_id, products[]}
#        → list of tariffs (period id, monthly payment, markup %)
#   3. POST /api/v1/orders {user_id, period, products[], callback, ext_order_id}
#        → {paymart_client: {order, contract_id, ...}, webview_path}
#        `webview_path` is opened in a WebView for the buyer to confirm the
#        SMS/OTP code (in sandbox: static code 111111).
#   4. The mobile app detects the WebView navigating back to the `callback`
#      URL it was given, closes the WebView, then calls our own
#      confirm/cancel endpoint (there is no server-to-server webhook in this
#      API — activation is driven by the partner app, not a callback).
#   5. POST /api/v1/contracts/confirm      {contract_id: <contract_id>} → activates.
#      POST /api/v1/contracts/check-status {contract_id: <contract_id>} → polls status.
#      POST /api/v1/contracts/cancel       {contract_id: <order>}       → cancels.
#      NOTE: despite the shared field name `contract_id` in all three request
#      bodies, confirm/check-status expect `paymart_client.contract_id` while
#      cancel expects `paymart_client.order` — verified empirically against
#      the sandbox (dev-merchants-api.uzumnasiya.uz), since the published
#      OpenAPI spec doesn't make this distinction. We store both, packed as
#      "<order>:<contract_id>" in Payment.external_id.
# ──────────────────────────────────────────────

_NASIYA_PENDING_PREFIX = "nasiya_pending_"
_NASIYA_MOCK_PREFIX = "nasiya_mock_"

# ──────────────────────────────────────────────
#  Circuit breaker — Uzum Nasiya's sandbox/prod API has a history of going
#  down for stretches (broken Keycloak DNS, order-creation 500s) rather than
#  failing one request at a time. Once we've seen enough consecutive upstream
#  failures, stop hammering it: fail fast with a friendly "texnik ishlar"
#  error and let the mobile app hide/disable the Nasiya option, instead of
#  every user's checkout individually timing out or 500ing.
# ──────────────────────────────────────────────

_NASIYA_BREAKER_THRESHOLD = 3  # failures within the window to trip
_NASIYA_BREAKER_WINDOW = 300.0  # seconds (5 min)
_NASIYA_BREAKER_COOLDOWN = 600.0  # seconds (10 min) before a retry is allowed

_nasiya_failure_times: deque[float] = deque()
_nasiya_breaker_opened_at: float | None = None

NASIYA_UNAVAILABLE_MESSAGE = (
    "Uzum Nasiya tizimida hozircha texnik ishlar olib borilmoqda. "
    "Birozdan so'ng qayta urinib ko'ring yoki boshqa to'lov usulini tanlang."
)


def _nasiya_breaker_is_open() -> bool:
    global _nasiya_breaker_opened_at
    if _nasiya_breaker_opened_at is None:
        return False
    if time.monotonic() - _nasiya_breaker_opened_at > _NASIYA_BREAKER_COOLDOWN:
        # Cooldown elapsed — allow one attempt through (half-open) to probe
        # whether Uzum has recovered.
        _nasiya_breaker_opened_at = None
        _nasiya_failure_times.clear()
        return False
    return True


def _nasiya_record_failure() -> None:
    global _nasiya_breaker_opened_at
    now = time.monotonic()
    _nasiya_failure_times.append(now)
    while _nasiya_failure_times and now - _nasiya_failure_times[0] > _NASIYA_BREAKER_WINDOW:
        _nasiya_failure_times.popleft()
    if len(_nasiya_failure_times) >= _NASIYA_BREAKER_THRESHOLD:
        _nasiya_breaker_opened_at = now
        log.error("uzum_nasiya.breaker_opened", failures=len(_nasiya_failure_times))


def _nasiya_record_success() -> None:
    _nasiya_failure_times.clear()


def uzum_nasiya_is_available() -> bool:
    """False while the circuit breaker is open — surfaced to the mobile app
    so it can disable the payment option instead of letting users hit it."""
    return not _nasiya_breaker_is_open()


def _nasiya_headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {settings.uzum_nasiya_api_key}",
        "Content-Type": "application/json",
    }


async def _nasiya_post(path: str, json_body: dict[str, Any]) -> dict[str, Any]:
    """POST to the Uzum Nasiya Partner API and return the parsed JSON body."""
    if _nasiya_breaker_is_open():
        raise AppError(NASIYA_UNAVAILABLE_MESSAGE, status_code=503)

    url = f"{settings.uzum_nasiya_base_url}{path}"
    try:
        async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
            resp = await client.post(url, headers=_nasiya_headers(), json=json_body)
            resp.raise_for_status()
            result: dict[str, Any] = resp.json()
        _nasiya_record_success()
        return result
    except httpx.HTTPStatusError as exc:
        # Uzum's sandbox sometimes returns a full HTML debug page (Laravel
        # Ignition, can be several hundred KB) instead of JSON on a 5xx.
        # Never forward that raw body to the client or dump it whole into
        # logs — extract a JSON error message when there is one, otherwise
        # log/report a short, fixed-size summary.
        content_type = exc.response.headers.get("content-type", "")
        detail: str
        if "json" in content_type:
            try:
                error_body = exc.response.json()
                detail = str(error_body.get("error") or error_body.get("message") or error_body)
            except ValueError:
                detail = exc.response.text[:500]
        else:
            detail = f"non-JSON response ({content_type or 'unknown content-type'})"
        log.error(
            "uzum_nasiya.api_error",
            status=exc.response.status_code,
            body=exc.response.text[:2000],
            path=path,
        )
        if exc.response.status_code >= 500:
            _nasiya_record_failure()
            # Known upstream failure mode: their order-creation handler
            # crashes with an unhandled TypeError (null PINFL in
            # ScoringService.getFreezeStatus) when the buyer's identification
            # is incomplete on Uzum's side, and returns an HTML debug page.
            # There is no Partner API field to submit PINFL, so the only
            # user-side remedy is finishing identification in Uzum's own app.
            raise AppError(
                "Uzum Nasiya tizimida ichki xatolik yuz berdi. Bu ko'pincha "
                "Uzum Nasiya'da identifikatsiya (pasport ma'lumotlari) to'liq "
                "yakunlanmagani bilan bog'liq. Uzum Nasiya ilovasida "
                "identifikatsiyadan o'ting yoki birozdan so'ng qayta urinib ko'ring.",
                status_code=502,
            ) from exc
        raise AppError(
            f"Uzum Nasiya xatoligi: {exc.response.status_code} — {detail}",
            status_code=502,
        ) from exc
    except httpx.RequestError as exc:
        _nasiya_record_failure()
        log.error("uzum_nasiya.network_error", error=str(exc), path=path)
        raise AppError("Uzum Nasiya bilan aloqa yo'q.", status_code=502) from exc


def _nasiya_normalize_phone(phone: str) -> str:
    """Uzum Nasiya expects a 12-digit phone: 998XXXXXXXXX (digits only)."""
    digits = "".join(ch for ch in phone if ch.isdigit())
    if len(digits) == 9:
        return f"998{digits}"
    return digits


def _nasiya_numeric_id(value: uuid.UUID | None) -> int:
    """Uzum Nasiya wants small integer ids (product_id, ext_order_id);
    derive one deterministically from a UUID."""
    return int(value.int % 2_147_483_647) if value else 1


def uzum_nasiya_requires_registration(payment: Payment) -> bool:
    """True when initiate returned Uzum's registration webview (no contract yet)."""
    return bool(
        payment.external_id and payment.external_id.startswith(_NASIYA_PENDING_PREFIX)
    )


def _nasiya_pack_ids(*, order: int, contract_id: int) -> str:
    return f"{order}:{contract_id}"


def _nasiya_unpack_ids(external_id: str) -> tuple[int, int]:
    """Returns (order, contract_id) — see module docstring above for why both are kept."""
    order_str, contract_str = external_id.split(":", 1)
    return int(order_str), int(contract_str)


async def uzum_nasiya_check_status(phone: str) -> dict[str, Any]:
    """Check a buyer's Uzum Nasiya registration status by phone.

    In stub mode (no API key configured) returns a synthetic "verified"
    buyer so the rest of the flow can be exercised without live credentials.
    """
    normalized = _nasiya_normalize_phone(phone)

    if not settings.uzum_nasiya_api_key:
        log.warning("uzum_nasiya.stub_mode", hint="UZUM_NASIYA_API_KEY o'rnatilmagan", phone=normalized)
        return {
            "status": 4,
            "buyer_id": 0,
            "has_limit": True,
            "is_in_black_list": False,
            "webview": "",
            "available_periods": [],
            "balance": "0.00",
        }

    data = await _nasiya_post("/api/v1/buyers/check-status", {"phone": int(normalized)})
    if data.get("status") != "success":
        raise AppError(
            f"Uzum Nasiya: foydalanuvchi holatini tekshirib bo'lmadi — {data.get('error')}",
            status_code=502,
        )
    return data["data"]  # type: ignore[no-any-return]


async def uzum_nasiya_calculate(
    *, buyer_id: int, amount: float, reference_id: uuid.UUID | None
) -> list[dict[str, Any]]:
    """Return available installment tariffs for a single-item cart of `amount` UZS."""
    if not settings.uzum_nasiya_api_key:
        return []

    data = await _nasiya_post(
        "/api/v1/orders/calculate",
        {
            "user_id": buyer_id,
            "products": [
                {"product_id": _nasiya_numeric_id(reference_id), "price": amount, "amount": 1}
            ],
        },
    )
    if data.get("status") != "success":
        raise AppError(
            f"Uzum Nasiya: tariflarni hisoblab bo'lmadi — {data.get('error')}",
            status_code=502,
        )
    return data["data"]  # type: ignore[no-any-return]


async def initiate_uzum_nasiya(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
    period: str = "6 Default",
    product_name: str = "Kurs",
) -> tuple[Payment, str]:
    """Create a pending Payment record and an Uzum Nasiya installment contract.

    `period` must be a tariff id the buyer already picked from
    `uzum_nasiya_check_status` / `uzum_nasiya_calculate` (e.g. "6 Default").
    Returns (payment, webview_url); the caller (mobile app) opens
    `webview_url` in a WebView for the buyer to confirm the SMS/OTP step.
    """
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.uzum_nasiya,
    )

    if settings.uzum_nasiya_api_key:
        user = await db.get(User, user_id)
        if user is None or not user.phone:
            raise AppError("Uzum Nasiya uchun telefon raqami talab qilinadi.", status_code=400)

        status_data = await uzum_nasiya_check_status(user.phone)
        buyer_id = status_data.get("buyer_id")
        log.info(
            "uzum_nasiya.buyer_status",
            payment_id=str(payment.id),
            buyer_id=buyer_id,
            status=status_data.get("status"),
            scoring_status=status_data.get("scoring_status"),
            has_limit=status_data.get("has_limit"),
            balance=status_data.get("balance"),
            verified_at=status_data.get("verified_at"),
            periods=len(status_data.get("available_periods") or []),
        )
        # status == 4 alone is not enough: verified empirically against the
        # sandbox (buyer 8899737, 2026-07-15) — a buyer can be status 4 with
        # verified_at set yet still have has_limit=false / null PINFL on
        # Uzum's side, and POST /api/v1/orders then crashes their scoring
        # with an unhandled 500 (getFreezeStatus(null)). Route such buyers
        # back through Uzum's registration webview instead of hitting the
        # crash: without a credit limit no contract can be created anyway.
        identification_incomplete = (
            status_data.get("has_limit") is False
            or ("verified_at" in status_data and status_data.get("verified_at") is None)
        )
        if status_data.get("status") != 4 or not buyer_id or identification_incomplete:
            # Buyer hasn't finished Uzum's own registration yet — hand the
            # webview URL back so the app can send them there first, then
            # retry /payments/initiate once registration completes.
            payment.external_id = f"{_NASIYA_PENDING_PREFIX}{payment.id.hex[:12]}"
            await db.flush()
            webview = status_data.get("webview") or ""
            log.info(
                "uzum_nasiya.registration_required",
                payment_id=str(payment.id),
                status=status_data.get("status"),
                identification_incomplete=identification_incomplete,
            )
            if not webview:
                raise AppError(
                    "Uzum Nasiya: foydalanuvchi hozircha rasmiylashtirish uchun mos emas.",
                    status_code=400,
                )
            return payment, webview

        callback_url = f"{return_url}{'&' if '?' in return_url else '?'}payment_id={payment.id}"
        data = await _nasiya_post(
            "/api/v1/orders",
            {
                "user_id": buyer_id,
                "period": period,
                "callback": callback_url,
                # The published OpenAPI spec types ext_order_id as a string
                # ("ORDER-454"), but the live API rejects non-numeric values
                # with 422 "должно быть целым числом" — keep sending an int.
                "ext_order_id": _nasiya_numeric_id(payment.id),
                "products": [
                    {
                        "product_id": _nasiya_numeric_id(reference_id),
                        "name": product_name,
                        "price": amount,
                        "category": 1,
                        "unit_id": 1,
                        "amount": 1,
                    }
                ],
            },
        )
        if data.get("status") != "success":
            raise AppError(f"Uzum Nasiya: shartnoma yaratilmadi — {data.get('error')}", status_code=502)

        inner = data["data"]
        contract = inner["paymart_client"]
        payment.external_id = _nasiya_pack_ids(
            order=int(contract["order"]), contract_id=int(contract["contract_id"])
        )
        redirect_url: str = inner["webview_path"]
        log.info(
            "uzum_nasiya.initiated",
            payment_id=str(payment.id),
            external_id=payment.external_id,
            amount=amount,
            period=period,
        )

    else:
        mock_external_id = f"{_NASIYA_MOCK_PREFIX}{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.nasiya.uzum.uz/pay?order_id={payment.id}"
        log.warning(
            "uzum_nasiya.stub_mode",
            hint="UZUM_NASIYA_API_KEY o'rnatilmagan",
            payment_id=str(payment.id),
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="uzum_nasiya",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
    )
    return payment, redirect_url


async def uzum_nasiya_confirm(db: AsyncSession, *, payment_id: uuid.UUID) -> Payment:
    """Activate an Uzum Nasiya contract after the buyer confirms OTP in the WebView.

    Called by the mobile client once it detects the WebView navigating back
    to the `return_url`/`callback` it was given at initiate time — this API
    has no server-to-server webhook, activation is partner-driven.
    """
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise NotFoundError("To'lov topilmadi.")
    if payment.provider != PaymentProvider.uzum_nasiya:
        raise AppError("Bu to'lov Uzum Nasiya orqali amalga oshirilmagan.", status_code=400)
    if payment.status == PaymentStatus.paid:
        return payment
    if not payment.external_id or payment.external_id.startswith(_NASIYA_PENDING_PREFIX):
        raise AppError("Shartnoma hali yaratilmagan.", status_code=400)

    if not settings.uzum_nasiya_api_key:
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
        await db.flush()
        return payment

    _order_id, contract_id = _nasiya_unpack_ids(payment.external_id)
    data = await _nasiya_post("/api/v1/contracts/confirm", {"contract_id": contract_id})
    response_code = data.get("response_code")
    if response_code in (0, 4010):  # 0 = success, 4010 = already activated
        payment.status = PaymentStatus.paid
        payment.paid_at = payment.paid_at or datetime.now(UTC)
        log.info("uzum_nasiya.confirmed", payment_id=str(payment.id), response_code=response_code)
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    else:
        log.warning(
            "uzum_nasiya.confirm_failed",
            payment_id=str(payment.id),
            response_code=response_code,
            errors=data.get("error"),
        )
        raise AppError(
            f"Uzum Nasiya: shartnomani tasdiqlab bo'lmadi (code={response_code}).",
            status_code=400,
        )

    await db.flush()
    return payment


async def uzum_nasiya_cancel(db: AsyncSession, *, payment_id: uuid.UUID) -> Payment:
    """Cancel a not-yet-activated Uzum Nasiya contract."""
    payment = await db.get(Payment, payment_id)
    if payment is None:
        raise NotFoundError("To'lov topilmadi.")
    if payment.provider != PaymentProvider.uzum_nasiya:
        raise AppError("Bu to'lov Uzum Nasiya orqali amalga oshirilmagan.", status_code=400)

    has_real_contract = payment.external_id and not payment.external_id.startswith(
        (_NASIYA_PENDING_PREFIX, _NASIYA_MOCK_PREFIX)
    )
    if settings.uzum_nasiya_api_key and has_real_contract:
        order_id, _contract_id = _nasiya_unpack_ids(payment.external_id)  # type: ignore[arg-type]
        data = await _nasiya_post("/api/v1/contracts/cancel", {"contract_id": order_id})
        response_code = data.get("response_code")
        if response_code not in (0, 4004, 4009):  # already-not-found / wrong-status are fine to ignore
            log.warning("uzum_nasiya.cancel_failed", payment_id=str(payment.id), response_code=response_code)
            raise AppError(
                f"Uzum Nasiya: shartnomani bekor qilib bo'lmadi (code={response_code}).",
                status_code=400,
            )

    payment.status = PaymentStatus.failed
    log.info("uzum_nasiya.cancelled", payment_id=str(payment.id))
    await db.flush()
    return payment


async def uzum_nasiya_contract_status(payment: Payment) -> dict[str, Any]:
    """Look up the live contract status from Uzum Nasiya for polling/reconciliation."""
    has_real_contract = payment.external_id and not payment.external_id.startswith(
        (_NASIYA_PENDING_PREFIX, _NASIYA_MOCK_PREFIX)
    )
    if not settings.uzum_nasiya_api_key or not has_real_contract:
        return {"contract_status": 1 if payment.status == PaymentStatus.paid else 0}

    _order_id, contract_id = _nasiya_unpack_ids(payment.external_id)  # type: ignore[arg-type]
    data = await _nasiya_post("/api/v1/contracts/check-status", {"contract_id": contract_id})
    if data.get("status") != "success":
        raise AppError(
            f"Uzum Nasiya: shartnoma holatini olib bo'lmadi — {data.get('error')}",
            status_code=502,
        )
    return data["data"]  # type: ignore[no-any-return]


# ──────────────────────────────────────────────
#  ATMOS  (oylik obuna / subscription)
# ──────────────────────────────────────────────
#
#  Docs: https://partner.atmos.uz/docs
#  Auth: OAuth2 client_credentials
#  Step 1 — GET token
#    POST /merchant/auth/token
#    body (form) → grant_type=client_credentials&consumer_key=…&consumer_secret=…
#    resp → { access_token, token_type, expires_in }
#  Step 2 — Create transaction
#    POST /merchant/pay/create
#    headers → Authorization: Bearer {token}
#    body  → { amount (tiyin), account (our orderId), store_id, lang }
#    resp  → { result: {code, description}, transaction_id, checkout_url }
# ──────────────────────────────────────────────


async def _atmos_get_token() -> str:
    """Fetch a short-lived ATMOS OAuth2 Bearer token."""
    async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
        resp = await client.post(
            f"{_ATMOS_BASE}/merchant/auth/token",
            data={
                "grant_type": "client_credentials",
                "consumer_key": settings.atmos_consumer_key,
                "consumer_secret": settings.atmos_consumer_secret,
            },
        )
        resp.raise_for_status()
        return str(resp.json()["access_token"])


async def initiate_atmos(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    amount: float,
    reference_id: uuid.UUID | None = None,
    purpose: PaymentPurpose,
    return_url: str,
) -> tuple[Payment, str]:
    """Create a pending Payment record and initiate an ATMOS checkout.

    Returns (payment, redirect_url).
    """
    payment = await _create_payment(
        db,
        user_id=user_id,
        amount=amount,
        reference_id=reference_id,
        purpose=purpose,
        provider=PaymentProvider.atmos,
    )

    if settings.atmos_store_id and settings.atmos_consumer_key and settings.atmos_consumer_secret:
        try:
            token = await _atmos_get_token()

            async with httpx.AsyncClient(timeout=_HTTP_TIMEOUT) as client:
                resp = await client.post(
                    f"{_ATMOS_BASE}/merchant/pay/create",
                    headers={
                        "Authorization": f"Bearer {token}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "amount": int(amount * 100),         # tiyin
                        "account": str(payment.id),          # our internal order id
                        "store_id": int(settings.atmos_store_id),
                        "lang": "ru",
                        "return_url": return_url,
                    },
                )
                resp.raise_for_status()
                data: dict[str, Any] = resp.json()

            result = data.get("result", {})
            code = str(result.get("code", "")) if isinstance(result, dict) else str(result)
            if code not in ("0", "200", "success", ""):
                raise AppError(
                    f"ATMOS xatoligi: {result}",
                    status_code=502,
                )

            external_id = str(
                data.get("transaction_id") or data.get("transactionId") or payment.id
            )
            redirect_url: str = (
                data.get("checkout_url") or data.get("checkoutUrl") or data.get("url")
                or f"{_ATMOS_BASE}/checkout/{external_id}"
            )
            payment.external_id = external_id
            log.info(
                "atmos.initiated",
                payment_id=str(payment.id),
                external_id=external_id,
                amount=amount,
            )

        except httpx.HTTPStatusError as exc:
            log.error(
                "atmos.api_error",
                status=exc.response.status_code,
                body=exc.response.text,
                payment_id=str(payment.id),
            )
            raise AppError(
                f"ATMOS xatoligi: {exc.response.status_code} — {exc.response.text}",
                status_code=502,
            ) from exc

        except httpx.RequestError as exc:
            log.error("atmos.network_error", error=str(exc), payment_id=str(payment.id))
            raise AppError("ATMOS bilan aloqa yo'q.", status_code=502) from exc

    else:
        mock_external_id = f"atmos_mock_{payment.id.hex[:12]}"
        payment.external_id = mock_external_id
        redirect_url = f"https://mock.atmos.uz/pay?order_id={payment.id}"
        log.warning(
            "atmos.stub_mode",
            hint="ATMOS_STORE_ID, ATMOS_CONSUMER_KEY yoki ATMOS_CONSUMER_SECRET o'rnatilmagan",
            payment_id=str(payment.id),
        )

    await db.flush()
    log.info(
        "payment.initiated",
        provider="atmos",
        payment_id=str(payment.id),
        user_id=str(user_id),
        amount=amount,
    )
    return payment, redirect_url


# ──────────────────────────────────────────────
#  Access-grant + homework helpers
# ──────────────────────────────────────────────


async def _ensure_homework_for_enrollment(
    db: AsyncSession,
    *,
    user_id: uuid.UUID,
    course_id: uuid.UUID,
) -> int:
    lesson_ids = (
        await db.execute(
            select(Lesson.id).where(Lesson.course_id == course_id)
        )
    ).scalars().all()
    if not lesson_ids:
        return 0

    existing_lesson_ids = set(
        (
            await db.execute(
                select(Homework.lesson_id).where(
                    Homework.user_id == user_id,
                    Homework.lesson_id.in_(lesson_ids),
                )
            )
        ).scalars().all()
    )

    created = 0
    for lid in lesson_ids:
        if lid in existing_lesson_ids:
            continue
        db.add(
            Homework(
                user_id=user_id,
                lesson_id=lid,
                status=HomeworkStatus.submitted,
            )
        )
        created += 1
    return created


async def _grant_access_for_payment(db: AsyncSession, payment: Payment) -> None:
    if payment.reference_id is None or payment.purpose is None:
        log.warning(
            "payment.grant_skipped",
            payment_id=str(payment.id),
            reason="missing reference_id or purpose",
        )
        return

    if payment.purpose == PaymentPurpose.course:
        existing = (
            await db.execute(
                select(Enrollment).where(
                    Enrollment.user_id == payment.user_id,
                    Enrollment.course_id == payment.reference_id,
                )
            )
        ).scalar_one_or_none()
        if existing:
            existing.status = EnrollmentStatus.active
        else:
            db.add(
                Enrollment(
                    user_id=payment.user_id,
                    course_id=payment.reference_id,
                    status=EnrollmentStatus.active,
                )
            )
        await _ensure_homework_for_enrollment(
            db,
            user_id=payment.user_id,
            course_id=payment.reference_id,
        )
    elif payment.purpose == PaymentPurpose.audiobook:
        stmt = (
            pg_insert(AudiobookAccess)
            .values(user_id=payment.user_id, audiobook_id=payment.reference_id)
            .on_conflict_do_nothing(constraint="user_audiobook_access")
        )
        await db.execute(stmt)


async def _notify_payment_success(db: AsyncSession, payment: Payment) -> None:
    title = "To'lov tasdiqlandi ✅"
    if payment.purpose == PaymentPurpose.course and payment.reference_id:
        course = await db.get(Course, payment.reference_id)
        body = (
            f'"{course.title if course else "kurs"}" uchun to\'lovingiz muvaffaqiyatli '
            f"amalga oshirildi. Kurs ochildi — o'rganishni boshlashingiz mumkin!"
        )
    elif payment.purpose == PaymentPurpose.audiobook and payment.reference_id:
        book = await db.get(Audiobook, payment.reference_id)
        body = (
            f'"{book.title if book else "audiokitob"}" uchun to\'lovingiz muvaffaqiyatli '
            f"amalga oshirildi. Audiokitob ochildi — tinglashni boshlashingiz mumkin!"
        )
    else:
        body = "To'lovingiz muvaffaqiyatli amalga oshirildi."

    try:
        tokens = (
            await db.execute(
                select(PushToken.token).where(PushToken.user_id == payment.user_id)
            )
        ).scalars().all()
        delivered_count = 0
        if tokens:
            fcm_result = await fcm.send_to_tokens(
                tokens,
                title=title,
                body=body,
                data={"kind": "order_status", "payment_id": str(payment.id)},
            )
            delivered_count = (
                fcm_result["success"]
                if (fcm_result["success"] or fcm_result["failure"])
                else len(tokens)
            )
        db.add(
            PushNotification(
                title=title,
                body=body,
                audience=PushAudience.user,
                target_id=payment.user_id,
                sent_at=datetime.now(UTC),
                delivered_count=delivered_count,
            )
        )
    except Exception as exc:  # noqa: BLE001
        log.error("payment.notify_failed", payment_id=str(payment.id), error=str(exc))


# ──────────────────────────────────────────────
#  Webhook / callback handlers
# ──────────────────────────────────────────────


def _verify_uzum_signature(payload: dict[str, Any]) -> bool:
    if not settings.uzum_secret_key:
        log.warning("uzum.signature_check_skipped", reason="no secret configured")
        return True
    received_sig = payload.get("signature", "")
    order_id = payload.get("order_id", "")
    amount = payload.get("amount", 0)
    expected = hmac.new(
        settings.uzum_secret_key.encode(),
        f"{order_id}:{amount}".encode(),
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(received_sig, expected)


async def handle_uzum_callback(db: AsyncSession, payload: dict[str, Any]) -> Payment:
    log.info("uzum.callback_received", payload_keys=list(payload.keys()))

    if not _verify_uzum_signature(payload):
        raise AppError("Uzum webhook imzosi yaroqsiz.", status_code=400)

    external_id = str(payload.get("transaction_id") or payload.get("order_id") or payload.get("paymentId") or "")
    if not external_id:
        raise AppError("Uzum callback: order_id yoki transaction_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    uzum_status = str(payload.get("status", "")).lower()
    if uzum_status in ("paid", "confirmed", "success", "succeeded"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("uzum.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif uzum_status in ("failed", "cancelled", "declined", "expired"):
        payment.status = PaymentStatus.failed
        log.info("uzum.payment_failed", payment_id=str(payment.id), status=uzum_status)
    else:
        log.warning("uzum.unknown_status", status=uzum_status, payment_id=str(payment.id))

    await db.flush()
    return payment


def _verify_atmos_signature(payload: dict[str, Any]) -> bool:
    if not settings.atmos_consumer_secret:
        log.warning("atmos.signature_check_skipped", reason="no secret configured")
        return True
    received_sig = payload.get("sign", "")
    transaction_id = payload.get("transaction_id", "")
    amount = payload.get("amount", 0)
    store_id = settings.atmos_store_id
    raw = f"{store_id}{transaction_id}{amount}"
    expected = hmac.new(
        settings.atmos_consumer_secret.encode(), raw.encode(), hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(received_sig, expected)


async def handle_atmos_callback(db: AsyncSession, payload: dict[str, Any]) -> Payment:
    log.info("atmos.callback_received", payload_keys=list(payload.keys()))

    if not _verify_atmos_signature(payload):
        raise AppError("ATMOS webhook imzosi yaroqsiz.", status_code=400)

    external_id = str(payload.get("transaction_id") or payload.get("transactionId") or payload.get("order_id") or "")
    if not external_id:
        raise AppError("ATMOS callback: transaction_id yo'q.", status_code=400)

    payment = await _get_payment_by_external_id(db, external_id)

    atmos_result = payload.get("result", {})
    code = str(atmos_result.get("code", "")) if isinstance(atmos_result, dict) else str(atmos_result)

    if code in ("0", "200", "success"):
        payment.status = PaymentStatus.paid
        payment.paid_at = datetime.now(UTC)
        log.info("atmos.payment_paid", payment_id=str(payment.id))
        await _grant_access_for_payment(db, payment)
        await _notify_payment_success(db, payment)
    elif code in ("1", "failed", "cancelled", "expired"):
        payment.status = PaymentStatus.failed
        log.info("atmos.payment_failed", payment_id=str(payment.id), code=code)
    else:
        log.warning("atmos.unknown_status", code=code, payment_id=str(payment.id))

    await db.flush()
    return payment
