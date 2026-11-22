import hashlib
import hmac
from typing import Any, Dict, Optional

import requests
from django.conf import settings

RAZORPAY_ORDERS_URL = "https://api.razorpay.com/v1/orders"


class RazorpayError(Exception):
    """Raised when Razorpay API communication or validation fails."""


def is_razorpay_configured() -> bool:
    key_id = (getattr(settings, "RAZORPAY_KEY_ID", "") or "").strip()
    key_secret = (getattr(settings, "RAZORPAY_KEY_SECRET", "") or "").strip()
    return bool(key_id and key_secret)


def create_razorpay_order(
    amount_paise: int,
    receipt: str,
    currency: str = "INR",
    notes: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Creates a Razorpay order via the Orders REST API."""
    if not is_razorpay_configured():
        raise RazorpayError("Razorpay API keys are not configured.")

    if amount_paise < 100:
        raise RazorpayError("Order amount must be at least ₹1.00 (100 paise).")

    payload: Dict[str, Any] = {
        "amount": int(amount_paise),
        "currency": currency,
        "receipt": receipt[:40],
        "payment_capture": 1,
    }
    if notes:
        payload["notes"] = notes

    try:
        response = requests.post(
            RAZORPAY_ORDERS_URL,
            auth=(settings.RAZORPAY_KEY_ID.strip(), settings.RAZORPAY_KEY_SECRET.strip()),
            json=payload,
            timeout=15,
        )
    except requests.RequestException as exc:
        raise RazorpayError(f"Could not reach Razorpay: {exc}") from exc

    if response.status_code not in (200, 201):
        try:
            err_msg = response.json().get("error", {}).get("description") or response.text
        except Exception:
            err_msg = response.text
        raise RazorpayError(f"Razorpay order creation failed: {err_msg}")

    return response.json()


def verify_payment_signature(
    razorpay_order_id: str,
    razorpay_payment_id: str,
    razorpay_signature: str,
) -> bool:
    """Verifies Razorpay checkout HMAC-SHA256 signature."""
    secret = (getattr(settings, "RAZORPAY_KEY_SECRET", "") or "").strip()
    if not secret or not razorpay_order_id or not razorpay_payment_id or not razorpay_signature:
        return False

    message = f"{razorpay_order_id}|{razorpay_payment_id}".encode("utf-8")
    expected = hmac.new(secret.encode("utf-8"), message, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, razorpay_signature.strip())


def verify_webhook_signature(raw_body: bytes, received_signature: str) -> bool:
    """Verifies Razorpay webhook `X-Razorpay-Signature` header."""
    secret = (getattr(settings, "RAZORPAY_WEBHOOK_SECRET", "") or "").strip()
    if not secret or not received_signature:
        return False

    expected = hmac.new(secret.encode("utf-8"), raw_body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, received_signature.strip())
