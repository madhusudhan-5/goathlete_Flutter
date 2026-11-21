import base64
import csv
import io
from urllib.parse import urlencode

from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.validators import validate_email
from django.http import HttpResponse
from django.shortcuts import render
from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import BetaTester


def _build_qr_data_uri(target_url: str) -> str:
    """Returns a base64 PNG data URI when `qrcode` is installed, else empty string."""
    try:
        import qrcode  # type: ignore

        qr = qrcode.QRCode(
            version=None,
            error_correction=qrcode.constants.ERROR_CORRECT_M,
            box_size=12,
            border=3,
        )
        qr.add_data(target_url)
        qr.make(fit=True)
        img = qr.make_image(fill_color="#030929", back_color="#FFFFFF")
        buffer = io.BytesIO()
        img.save(buffer, format="PNG")
        encoded = base64.b64encode(buffer.getvalue()).decode("ascii")
        return f"data:image/png;base64,{encoded}"
    except Exception:
        return ""


def _resolve_beta_target_url(request) -> str:
    custom_url = request.GET.get("url", "").strip()
    if custom_url:
        base_url = custom_url
    elif getattr(settings, "ANDROID_BETA_PUBLIC_URL", "").strip():
        base_url = settings.ANDROID_BETA_PUBLIC_URL.strip()
    else:
        base_url = request.build_absolute_uri("/android-beta/")

    ref = request.GET.get("ref", "").strip()
    if ref:
        sep = "&" if "?" in base_url else "?"
        return f"{base_url}{sep}{urlencode({'ref': ref})}"
    return base_url


def android_beta_portal(request):
    ref_source = request.GET.get("ref", "").strip()[:80] or "qr_portal"
    context = {
        "google_group_url": settings.ANDROID_TESTER_GOOGLE_GROUP_URL,
        "play_testing_url": settings.ANDROID_PLAY_TESTING_URL,
        "play_store_url": settings.ANDROID_PLAY_STORE_URL,
        "ios_web_app_url": settings.IOS_WEB_APP_URL,
        "package_name": settings.ANDROID_PACKAGE_NAME,
        "ref_source": ref_source,
        "tester_count": BetaTester.objects.count(),
    }
    return render(request, "users/android_beta.html", context)


def android_beta_qr_poster(request):
    target_url = _resolve_beta_target_url(request)
    tester_count = BetaTester.objects.count()
    goal_count = 12
    progress_pct = min(100, int((tester_count / goal_count) * 100)) if goal_count else 100

    context = {
        "target_url": target_url,
        "qr_data_uri": _build_qr_data_uri(target_url),
        "google_group_url": settings.ANDROID_TESTER_GOOGLE_GROUP_URL,
        "play_testing_url": settings.ANDROID_PLAY_TESTING_URL,
        "tester_count": tester_count,
        "goal_count": goal_count,
        "progress_pct": progress_pct,
        "ref_source": request.GET.get("ref", "").strip(),
    }
    return render(request, "users/android_beta_qr.html", context)


class BetaTesterRegisterView(APIView):
    permission_classes = (permissions.AllowAny,)
    authentication_classes = ()

    def post(self, request):
        raw_email = (request.data.get("email") or "").strip().lower()
        full_name = (request.data.get("full_name") or "").strip()[:120]
        phone_number = (request.data.get("phone_number") or "").strip()[:20]
        source = (request.data.get("source") or "qr_portal").strip()[:80] or "qr_portal"

        if not raw_email:
            return Response(
                {"error": "Please enter your Google Play email address."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            validate_email(raw_email)
        except ValidationError:
            return Response(
                {"error": "Please enter a valid email address (e.g. yourname@gmail.com)."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user_agent = (request.META.get("HTTP_USER_AGENT") or "")[:300]

        tester, created = BetaTester.objects.get_or_create(
            email=raw_email,
            defaults={
                "full_name": full_name,
                "phone_number": phone_number,
                "source": source,
                "user_agent": user_agent,
            },
        )

        if not created:
            changed = False
            if full_name and not tester.full_name:
                tester.full_name = full_name
                changed = True
            if phone_number and not tester.phone_number:
                tester.phone_number = phone_number
                changed = True
            if user_agent and not tester.user_agent:
                tester.user_agent = user_agent
                changed = True
            if changed:
                tester.save()

        return Response(
            {
                "email": tester.email,
                "status": tester.status,
                "is_new": created,
                "google_group_url": settings.ANDROID_TESTER_GOOGLE_GROUP_URL,
                "play_testing_url": settings.ANDROID_PLAY_TESTING_URL,
                "play_store_url": settings.ANDROID_PLAY_STORE_URL,
                "total_testers": BetaTester.objects.count(),
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class BetaTesterTrackView(APIView):
    permission_classes = (permissions.AllowAny,)
    authentication_classes = ()

    def post(self, request):
        raw_email = (request.data.get("email") or "").strip().lower()
        event = (request.data.get("event") or "").strip().lower()

        if not raw_email or event not in ("group_joined", "play_opened"):
            return Response(
                {"error": "Valid email and event ('group_joined' or 'play_opened') are required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        tester = BetaTester.objects.filter(email=raw_email).first()
        if not tester:
            return Response({"error": "Tester not found."}, status=status.HTTP_404_NOT_FOUND)

        now = timezone.now()
        if event == "group_joined":
            tester.group_joined_at = now
            if tester.status == "REGISTERED":
                tester.status = "GROUP_JOINED"
        elif event == "play_opened":
            tester.play_opened_at = now
            if tester.status in ("REGISTERED", "GROUP_JOINED"):
                tester.status = "PLAY_OPENED"

        tester.save()
        return Response({"email": tester.email, "status": tester.status}, status=status.HTTP_200_OK)


class BetaTesterExportCSVView(APIView):
    permission_classes = (permissions.IsAdminUser,)

    def get(self, request):
        response = HttpResponse(content_type="text/csv")
        response["Content-Disposition"] = 'attachment; filename="goathlete_android_testers.csv"'
        writer = csv.writer(response)
        writer.writerow(["Email", "Full Name", "Phone", "Status", "Source", "Registered At"])
        for tester in BetaTester.objects.all():
            writer.writerow([
                tester.email,
                tester.full_name,
                tester.phone_number,
                tester.status,
                tester.source,
                tester.created_at.isoformat(),
            ])
        return response
