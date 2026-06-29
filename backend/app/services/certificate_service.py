"""Generate a PDF completion certificate using reportlab."""
from __future__ import annotations

import io
import secrets
from datetime import date

from app.core.logging import get_logger
from app.services.storage import save_bytes

log = get_logger("certificate")

WINE = (0.541, 0.082, 0.220)  # #8A1538


def generate_serial() -> str:
    return "NN-" + secrets.token_hex(4).upper()


async def build_certificate_pdf(
    *, full_name: str, course_title: str, serial: str, grade: int | None
) -> str:
    """Render a branded certificate and return its stored URL."""
    try:
        from reportlab.lib.pagesizes import landscape, A4
        from reportlab.pdfgen import canvas
    except Exception as exc:  # pragma: no cover
        log.error("certificate.reportlab_missing", error=str(exc))
        raise

    buf = io.BytesIO()
    width, height = landscape(A4)
    c = canvas.Canvas(buf, pagesize=landscape(A4))

    # Border
    c.setStrokeColorRGB(*WINE)
    c.setLineWidth(6)
    c.rect(30, 30, width - 60, height - 60)

    c.setFillColorRGB(*WINE)
    c.setFont("Helvetica-Bold", 34)
    c.drawCentredString(width / 2, height - 130, "SERTIFIKAT")

    c.setFont("Helvetica", 16)
    c.setFillColorRGB(0.2, 0.2, 0.2)
    c.drawCentredString(width / 2, height - 175, "Najot Nur — notiqlik mahorati markazi")

    c.setFont("Helvetica", 14)
    c.drawCentredString(width / 2, height - 240, "Ushbu sertifikat")
    c.setFont("Helvetica-Bold", 26)
    c.setFillColorRGB(*WINE)
    c.drawCentredString(width / 2, height - 280, full_name)

    c.setFont("Helvetica", 14)
    c.setFillColorRGB(0.2, 0.2, 0.2)
    c.drawCentredString(
        width / 2, height - 320, f'"{course_title}" kursini muvaffaqiyatli tamomladi'
    )
    if grade is not None:
        c.drawCentredString(width / 2, height - 348, f"Yakuniy baho: {grade}/100")

    c.setFont("Helvetica", 11)
    c.setFillColorRGB(0.4, 0.4, 0.4)
    c.drawString(60, 70, f"Seriya: {serial}")
    c.drawRightString(width - 60, 70, f"Sana: {date.today().isoformat()}")

    c.showPage()
    c.save()
    pdf_bytes = buf.getvalue()

    return await save_bytes(
        pdf_bytes,
        folder="certificates",
        filename=f"{serial}.pdf",
        content_type="application/pdf",
    )
