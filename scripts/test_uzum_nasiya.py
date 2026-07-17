#!/usr/bin/env python3
"""Test Uzum Nasiya sandbox flow end-to-end.

Run:
    python3 scripts/test_uzum_nasiya.py

Reads UZUM_NASIYA_API_KEY and UZUM_NASIYA_BASE_URL from the repo-root .env.
Creates a test contract in the Uzum Nasiya sandbox (no real money).
"""
from __future__ import annotations

import os
import random
from pathlib import Path

import requests


def _load_env() -> None:
    env_path = Path(__file__).resolve().parent.parent / ".env"
    if not env_path.exists():
        return
    with env_path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                os.environ.setdefault(k, v)


def _headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {os.environ['UZUM_NASIYA_API_KEY']}",
        "Content-Type": "application/json",
    }


def check_status(phone: int) -> dict:
    url = f"{os.environ['UZUM_NASIYA_BASE_URL']}/api/v1/buyers/check-status"
    r = requests.post(url, headers=_headers(), json={"phone": phone}, timeout=20)
    r.raise_for_status()
    return r.json()["data"]


def calculate(buyer_id: int, amount: int) -> list[dict]:
    url = f"{os.environ['UZUM_NASIYA_BASE_URL']}/api/v1/orders/calculate"
    body = {
        "user_id": buyer_id,
        "products": [{"product_id": random.randint(1, 2_000_000_000), "price": amount, "amount": 1}],
    }
    r = requests.post(url, headers=_headers(), json=body, timeout=20)
    r.raise_for_status()
    return r.json()["data"]


def create_order(
    buyer_id: int,
    period: str,
    amount: int,
    product_name: str,
    callback: str,
) -> dict:
    url = f"{os.environ['UZUM_NASIYA_BASE_URL']}/api/v1/orders"
    body = {
        "user_id": buyer_id,
        "period": period,
        "callback": callback,
        "ext_order_id": random.randint(1, 2_000_000_000),
        "products": [
            {
                "product_id": random.randint(1, 2_000_000_000),
                "name": product_name,
                "price": amount,
                "category": 1,
                "unit_id": 1,
                "amount": 1,
            }
        ],
    }
    r = requests.post(url, headers=_headers(), json=body, timeout=20)
    print(f"create_order status: {r.status_code}")
    print(f"create_order body: {r.text[:500]}")
    r.raise_for_status()
    return r.json()["data"]


def confirm_contract(contract_id: int) -> dict:
    url = f"{os.environ['UZUM_NASIYA_BASE_URL']}/api/v1/contracts/confirm"
    r = requests.post(url, headers=_headers(), json={"contract_id": contract_id}, timeout=20)
    print(f"confirm_contract status: {r.status_code}")
    print(f"confirm_contract body: {r.text[:500]}")
    return r.json()


def cancel_contract(order_id: int) -> dict:
    url = f"{os.environ['UZUM_NASIYA_BASE_URL']}/api/v1/contracts/cancel"
    r = requests.post(url, headers=_headers(), json={"contract_id": order_id}, timeout=20)
    print(f"cancel_contract status: {r.status_code}")
    print(f"cancel_contract body: {r.text[:500]}")
    return r.json()


def main() -> None:
    _load_env()
    base_url = os.environ.get("UZUM_NASIYA_BASE_URL", "")
    api_key = os.environ.get("UZUM_NASIYA_API_KEY", "")
    if not base_url or not api_key:
        print("UZUM_NASIYA_BASE_URL yoki UZUM_NASIYA_API_KEY topilmadi.")
        return

    print(f"Base URL: {base_url}")
    print(f"API key: {api_key[:4]}...{api_key[-4:]} ({len(api_key)} ta belgi)")

    # Test phone that is known to work in sandbox (status=4, has_limit=true)
    phone = 998_971_234_567
    amount = 100_000
    product_name = "Test kurs"
    callback = "https://notiqlik.uz/nasiya-return?payment_id=test"

    print(f"\n1. check-status: {phone}")
    status = check_status(phone)
    print(f"   status={status['status']}, buyer_id={status.get('buyer_id')}, has_limit={status.get('has_limit')}")
    if status.get("status") != 4 or not status.get("buyer_id") or not status.get("has_limit"):
        print("   Bu telefon Uzum Nasiya'da to'liq ro'yxatdan o'tmagan yoki limit yo'q.")
        return

    buyer_id = status["buyer_id"]

    print(f"\n2. calculate: buyer_id={buyer_id}, amount={amount}")
    tariffs = calculate(buyer_id, amount)
    available = [t for t in tariffs if t.get("is_available")]
    if not available:
        print("   Mavjud tariff topilmadi.")
        return
    for t in available:
        print(f"   tariff={t['tariff']}, title_uz={t.get('title_uz')}, month={t.get('month')}, total={t.get('total')}")

    period = available[0]["tariff"]

    print(f"\n3. create_order: period={period}")
    order = create_order(buyer_id, period, amount, product_name, callback)
    print(f"   order={order['paymart_client']['order']}")
    print(f"   contract_id={order['paymart_client']['contract_id']}")
    print(f"   webview_path={order['webview_path']}")
    print(f"   client_act_pdf={order.get('client_act_pdf', '')}")

    contract_id = order["paymart_client"]["contract_id"]
    order_id = order["paymart_client"]["order"]

    print("\n4. Open webview_path in a browser/WebView.")
    print("   Sandbox SMS/OTP kodi odatda: 111111")

    print("\n   Keyingi qadam: WebView'da OTP kodini kiritish.")
    print("   Sandbox uchun statik kod odatda: 111111")
    print("   WebView callback'ga qaytganidan so'ng backend /payments/uzum-nasiya/confirm chaqiradi.")
    print("\n   Test confirm/cancel qilish uchun quyidagi funksiyalarni chaqiring:")
    print(f"   confirm_contract({contract_id})")
    print(f"   cancel_contract({order_id})")


if __name__ == "__main__":
    main()
