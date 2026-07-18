#!/usr/bin/env python3
"""Test Uzum Nasiya flow through the backend API (like the mobile app does).

This script mirrors the mobile app flow:
  1. Login with phone/password
  2. GET /payments/uzum-nasiya/availability
  3. POST /payments/uzum-nasiya/check-status
  4. POST /payments/uzum-nasiya/calculate
  5. POST /payments/initiate (provider=uzum_nasiya)
  6. Prompt user to open webview and enter sandbox OTP (usually 111111)
  7. POST /payments/uzum-nasiya/confirm
  8. Verify payment status

Run:
    python3 scripts/test_uzum_nasiya_backend_flow.py

Override user/URL via env vars:
    API_URL=https://api.notiqlik.uz/api/v1 \
    TEST_PHONE=+998953271309 \
    TEST_PASSWORD=abbos123 \
    TEST_AMOUNT=100000 \
    python3 scripts/test_uzum_nasiya_backend_flow.py
"""
from __future__ import annotations

import os
import sys
import time
import uuid
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


def login(api_url: str, phone: str, password: str) -> str:
    url = f"{api_url}/auth/phone/login"
    r = requests.post(url, json={"phone": phone, "password": password}, timeout=20)
    print(f"login status: {r.status_code}")
    if r.status_code != 200:
        print(f"login error: {r.text[:500]}")
        raise SystemExit("Login failed")
    data = r.json()
    return str(data["access_token"])


def _headers(token: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }


def availability(api_url: str, token: str) -> dict:
    url = f"{api_url}/payments/uzum-nasiya/availability"
    r = requests.get(url, headers=_headers(token), timeout=20)
    print(f"availability status: {r.status_code}")
    data = r.json()
    print(f"availability: {data}")
    if not data.get("available", True):
        raise SystemExit("Uzum Nasiya hozircha mavjud emas (circuit breaker ochiq)")
    return data


def check_status(api_url: str, token: str) -> dict:
    url = f"{api_url}/payments/uzum-nasiya/check-status"
    r = requests.post(url, headers=_headers(token), json={}, timeout=20)
    print(f"check-status status: {r.status_code}")
    data = r.json()
    print(f"check-status: {data}")
    if data.get("status") != 4 or not data.get("buyer_id") or not data.get("has_limit"):
        raise SystemExit("Foydalanuvchi Uzum Nasiya'da to'liq ro'yxatdan o'tmagan yoki limit yo'q")
    return data


def calculate(api_url: str, token: str, amount: float, reference_id: str | None) -> list[dict]:
    url = f"{api_url}/payments/uzum-nasiya/calculate"
    body: dict = {"amount": amount}
    if reference_id:
        body["reference_id"] = reference_id
    r = requests.post(url, headers=_headers(token), json=body, timeout=20)
    print(f"calculate status: {r.status_code}")
    data = r.json()
    print(f"calculate tariffs: {data}")
    tariffs = data.get("tariffs", [])
    if not tariffs:
        raise SystemExit("Mavjud tariff topilmadi")
    return tariffs


def initiate(
    api_url: str,
    token: str,
    amount: float,
    purpose: str,
    reference_id: str,
    period: str,
    return_url: str,
    product_name: str,
) -> dict:
    url = f"{api_url}/payments/initiate"
    body = {
        "provider": "uzum_nasiya",
        "amount": amount,
        "purpose": purpose,
        "reference_id": reference_id,
        "return_url": return_url,
        "period": period,
        "product_name": product_name,
    }
    r = requests.post(url, headers=_headers(token), json=body, timeout=20)
    print(f"initiate status: {r.status_code}")
    print(f"initiate response: {r.text[:1000]}")
    if r.status_code != 200:
        raise SystemExit("Initiate failed")
    return r.json()


def confirm(api_url: str, token: str, payment_id: str) -> dict:
    url = f"{api_url}/payments/uzum-nasiya/confirm"
    r = requests.post(url, headers=_headers(token), json={"payment_id": payment_id}, timeout=20)
    print(f"confirm status: {r.status_code}")
    print(f"confirm response: {r.text[:1000]}")
    return r.json()


def get_my_orders(api_url: str, token: str) -> dict:
    url = f"{api_url}/orders/my"
    r = requests.get(url, headers=_headers(token), timeout=20)
    print(f"get_my_orders status: {r.status_code}")
    return r.json()


def main() -> None:
    _load_env()

    api_url = os.environ.get("API_URL", "https://api.notiqlik.uz/api/v1").rstrip("/")
    phone = os.environ.get("TEST_PHONE", "+998909781663")
    password = os.environ.get("TEST_PASSWORD", "test12345")
    amount = float(os.environ.get("TEST_AMOUNT", "100000"))
    purpose = os.environ.get("TEST_PURPOSE", "course")
    reference_id = os.environ.get("TEST_REFERENCE_ID", str(uuid.uuid4()))
    return_url = os.environ.get("TEST_RETURN_URL", "https://notiqlik.uz/nasiya-return")
    product_name = os.environ.get("TEST_PRODUCT_NAME", "Test kurs")

    print(f"API URL: {api_url}")
    print(f"Phone: {phone}")
    print(f"Amount: {amount}")

    print("\n1. Login...")
    token = login(api_url, phone, password)
    print("   Login OK")

    print("\n2. Availability...")
    availability(api_url, token)

    print("\n3. Check status...")
    status = check_status(api_url, token)
    buyer_id = status["buyer_id"]
    print(f"   buyer_id={buyer_id}")

    print("\n4. Calculate tariffs...")
    tariffs = calculate(api_url, token, amount, reference_id)
    available = [t for t in tariffs if t.get("is_available", True)]
    if not available:
        raise SystemExit("Mavjud tariff yo'q")
    period = available[0]["tariff"]
    print(f"   Selected period: {period}")

    print("\n5. Initiate payment...")
    redirect = initiate(
        api_url, token, amount, purpose, reference_id, period, return_url, product_name
    )
    payment_id = redirect["payment_id"]
    webview_url = redirect["redirect_url"]
    requires_registration = redirect.get("requires_registration", False)
    print(f"   payment_id={payment_id}")
    print(f"   requires_registration={requires_registration}")
    print(f"   webview_url={webview_url}")

    print("\n6. Open the webview URL above in a browser.")
    print("   Sandbox OTP code is usually: 111111")
    print("   After entering OTP and the page redirects to the callback URL,")
    input("   press ENTER here to continue...")

    print("\n7. Confirm payment...")
    confirm_result = confirm(api_url, token, payment_id)
    print(f"   confirm result: {confirm_result}")

    # Give backend a moment to update DB
    time.sleep(1)

    print("\n8. Check my orders...")
    orders = get_my_orders(api_url, token)
    print(f"   orders: {orders}")


if __name__ == "__main__":
    main()
