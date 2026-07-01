"""Aggregate all v1 routers."""
from fastapi import APIRouter

from app.api.v1 import (
    admin,
    audiobooks,
    auth,
    certificates,
    courses,
    observation,
    orders,
    payments,
    practicums,
    quizzes,
    security,
    speech,
    support,
    users,
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(security.router, prefix="/security", tags=["security"])
api_router.include_router(speech.router, prefix="/speech", tags=["speech"])
api_router.include_router(
    observation.router, prefix="/observation", tags=["observation"]
)
api_router.include_router(courses.router, prefix="/courses", tags=["courses"])
api_router.include_router(
    audiobooks.router, prefix="/audiobooks", tags=["audiobooks"]
)
api_router.include_router(support.router, prefix="/support", tags=["support"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
# User-facing payment initiation + provider callbacks
api_router.include_router(payments.router, prefix="/payments", tags=["payments"])
# Admin payment reporting  →  GET /admin/payments, GET /admin/payments/{id}
api_router.include_router(payments.admin_router, prefix="/admin", tags=["admin"])
# Manual order (zayavka) flow — Click / Payme / Cash
api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
# Admin order management → GET /admin/orders, PATCH /admin/orders/{id}/approve|reject
api_router.include_router(orders.admin_router, prefix="/admin", tags=["admin"])
# Quizzes — curator creates, admin approves, users take on mobile
api_router.include_router(quizzes.router, prefix="/quizzes", tags=["quizzes"])
# Practicums — curator creates with expert audio, admin approves, users listen on mobile
api_router.include_router(practicums.router, prefix="/practicums", tags=["practicums"])
# Certificates — user requests, curator approves/rejects, PDF generated
api_router.include_router(certificates.router, prefix="/certificates", tags=["certificates"])
api_router.include_router(certificates.admin_router, prefix="/admin", tags=["admin"])
