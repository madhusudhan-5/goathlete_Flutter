import hashlib
import hmac
import json
from decimal import Decimal
from unittest.mock import patch

from django.contrib.auth.models import User
from django.test import TestCase, override_settings
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from bookings.models import Booking, Payment
from venues.models import Venue


@override_settings(
    RAZORPAY_KEY_ID="rzp_test_goathlete123",
    RAZORPAY_KEY_SECRET="test_secret_key_xyz",
    RAZORPAY_WEBHOOK_SECRET="test_webhook_secret_abc",
)
class RazorpayPaymentTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            username="athlete_rzp",
            email="athlete@goathelet.org.in",
            password="password123",
            first_name="Aarav",
        )
        token = str(RefreshToken.for_user(self.user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        self.venue = Venue.objects.create(
            name="GoAthlete Arena",
            description="5v5 turf",
            location="Bengaluru",
            price_per_hour=Decimal("1000.00"),
        )

    @patch("bookings.views.create_razorpay_order")
    def test_create_order_and_verify_signature_confirm(self, mock_create_order):
        mock_create_order.return_value = {"id": "order_RzpTest001", "amount": 120000, "currency": "INR"}

        res = self.client.post(
            "/api/bookings/payments/create-intent/",
            {
                "venue_id": self.venue.id,
                "date": "2026-12-01",
                "start_time": "10:00:00",
                "end_time": "11:00:00",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["provider"], "RAZORPAY")
        self.assertEqual(res.data["order_id"], "order_RzpTest001")
        self.assertEqual(res.data["key_id"], "rzp_test_goathlete123")
        # 1000 + 20 platform fee + 180 GST = 1200.00 INR = 120000 paise
        self.assertEqual(res.data["amount_paise"], 120000)

        payment_id = res.data["payment_id"]

        # Tampered signature must fail
        bad_confirm = self.client.post(
            "/api/bookings/payments/confirm/",
            {
                "payment_id": payment_id,
                "razorpay_order_id": "order_RzpTest001",
                "razorpay_payment_id": "pay_RzpTest999",
                "razorpay_signature": "invalid_signature",
            },
            format="json",
        )
        self.assertEqual(bad_confirm.status_code, 400)
        payment = Payment.objects.get(id=payment_id)
        self.assertEqual(payment.status, "failed")
        self.assertEqual(payment.booking.status, "pending")

        # Valid HMAC-SHA256 signature must confirm booking
        payment.status = "pending"
        payment.save()
        valid_sig = hmac.new(
            b"test_secret_key_xyz",
            b"order_RzpTest001|pay_RzpTest999",
            hashlib.sha256,
        ).hexdigest()

        ok_confirm = self.client.post(
            "/api/bookings/payments/confirm/",
            {
                "payment_id": payment_id,
                "razorpay_order_id": "order_RzpTest001",
                "razorpay_payment_id": "pay_RzpTest999",
                "razorpay_signature": valid_sig,
            },
            format="json",
        )
        self.assertEqual(ok_confirm.status_code, 200)
        payment.refresh_from_db()
        self.assertEqual(payment.status, "completed")
        self.assertEqual(payment.transaction_id, "pay_RzpTest999")
        self.assertEqual(payment.booking.status, "confirmed")

    def test_razorpay_webhook_verifies_and_confirms(self):
        booking = Booking.objects.create(
            user=self.user,
            venue=self.venue,
            date="2026-12-02",
            start_time="14:00:00",
            end_time="15:00:00",
            total_price=Decimal("1200.00"),
            status="pending",
        )
        payment = Payment.objects.create(
            booking=booking,
            amount=Decimal("1200.00"),
            currency="INR",
            provider="RAZORPAY",
            razorpay_order_id="order_Webhook001",
            status="pending",
        )

        body = json.dumps({
            "event": "payment.captured",
            "payload": {
                "payment": {
                    "entity": {
                        "id": "pay_Webhook999",
                        "order_id": "order_Webhook001",
                    }
                }
            },
        }).encode("utf-8")

        # Bad webhook signature rejected
        bad_res = self.client.post(
            "/api/bookings/payments/razorpay-webhook/",
            data=body,
            content_type="application/json",
            HTTP_X_RAZORPAY_SIGNATURE="bad_sig",
        )
        self.assertEqual(bad_res.status_code, 400)

        # Valid webhook signature confirms booking
        valid_sig = hmac.new(b"test_webhook_secret_abc", body, hashlib.sha256).hexdigest()
        ok_res = self.client.post(
            "/api/bookings/payments/razorpay-webhook/",
            data=body,
            content_type="application/json",
            HTTP_X_RAZORPAY_SIGNATURE=valid_sig,
        )
        self.assertEqual(ok_res.status_code, 200)
        payment.refresh_from_db()
        booking.refresh_from_db()
        self.assertEqual(payment.status, "completed")
        self.assertEqual(payment.transaction_id, "pay_Webhook999")
        self.assertEqual(booking.status, "confirmed")
