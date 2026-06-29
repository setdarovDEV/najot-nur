"""Import all models so `Base.metadata` is complete for Alembic autogenerate."""
from app.models.analysis import (
    PronunciationReference,
    SpeechAnalysis,
    VoiceAnalysis,
)
from app.models.audiobook import (
    Audiobook,
    AudiobookAccess,
    AudiobookPage,
    AudiobookProgress,
)
from app.models.base import Base
from app.models.certificate import Certificate
from app.models.certificate_request import CertificateRequest
from app.models.course import (
    Course,
    Enrollment,
    Lesson,
    LessonProgress,
    LessonQuestion,
)
from app.models.grading import Homework
from app.models.notification import PushNotification, PushToken
from app.models.observation import (
    ObservationAnswer,
    ObservationAttempt,
    ObservationTest,
)
from app.models.order import Order
from app.models.payment import Payment
from app.models.practicum import Practicum
from app.models.practicum_submission import PracticumSubmission
from app.models.support import SupportMessage
from app.models.user import AuthIdentity, User

__all__ = [
    "Base",
    "User",
    "AuthIdentity",
    "Course",
    "Lesson",
    "LessonQuestion",
    "Enrollment",
    "LessonProgress",
    "ObservationTest",
    "ObservationAttempt",
    "ObservationAnswer",
    "PronunciationReference",
    "SpeechAnalysis",
    "VoiceAnalysis",
    "Audiobook",
    "AudiobookPage",
    "AudiobookProgress",
    "AudiobookAccess",
    "Certificate",
    "CertificateRequest",
    "PushToken",
    "PushNotification",
    "Order",
    "Payment",
    "Practicum",
    "PracticumSubmission",
    "Homework",
    "SupportMessage",
]
