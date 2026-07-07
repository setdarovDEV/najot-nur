"""Shared enumerations used across models and schemas."""
from __future__ import annotations

import enum


class Role(str, enum.Enum):
    user = "user"
    curator = "curator"
    admin = "admin"


class AuthProvider(str, enum.Enum):
    phone = "phone"
    google = "google"
    telegram = "telegram"
    password = "password"  # email+password (admin/curator)


class AnalysisStatus(str, enum.Enum):
    pending = "pending"
    processing = "processing"
    done = "done"
    failed = "failed"


class EnrollmentStatus(str, enum.Enum):
    active = "active"
    completed = "completed"
    cancelled = "cancelled"


class ObservationCategory(str, enum.Enum):
    psychology = "psychology"
    body_language = "body_language"
    observation = "observation"


class MediaType(str, enum.Enum):
    image = "image"
    video = "video"


class HomeworkStatus(str, enum.Enum):
    submitted = "submitted"
    reviewed = "reviewed"
    returned = "returned"


class PushAudience(str, enum.Enum):
    all = "all"
    course = "course"
    user = "user"
    city = "city"


class PaymentProvider(str, enum.Enum):
    uzum = "uzum"
    uzum_nasiya = "uzum_nasiya"
    atmos = "atmos"


class OrderPaymentMethod(str, enum.Enum):
    uzum = "uzum"
    uzum_nasiya = "uzum_nasiya"
    cash = "cash"
    gift = "gift"


class OrderStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class OrderPurpose(str, enum.Enum):
    course = "course"
    audiobook = "audiobook"


class PaymentStatus(str, enum.Enum):
    pending = "pending"
    paid = "paid"
    failed = "failed"
    refunded = "refunded"


class PaymentPurpose(str, enum.Enum):
    course = "course"
    audiobook = "audiobook"
    subscription = "subscription"


class Platform(str, enum.Enum):
    ios = "ios"
    android = "android"
    web = "web"


class CertificateRequestStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"
