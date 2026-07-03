"""Generate a PDF certificate by overlaying student data onto the official template."""
from __future__ import annotations

import io
import secrets
from datetime import date
from pathlib import Path

from app.core.logging import get_logger
from app.services.storage import save_bytes

log = get_logger("certificate")

WINE = (0.541, 0.082, 0.220)
PAGE_W = 841.89
PAGE_H = 1190.55

# Template lives next to source so it's always inside the Docker build context
_TEMPLATE = Path(__file__).resolve().parent / "resources" / "certificate_template.pdf"


def generate_serial() -> str:
    return "NN-" + secrets.token_hex(4).upper()


async def build_certificate_pdf(
    *, full_name: str, course_title: str, serial: str, grade: int | None
) -> str:
    """Overlay student name and today's date onto the official certificate template."""
    try:
        from reportlab.pdfgen import canvas as rl_canvas
        from pypdf import PdfReader, PdfWriter
    except Exception as exc:
        log.error("certificate.missing_deps", error=str(exc))
        raise

    if not _TEMPLATE.exists():
        raise FileNotFoundError(f"Certificate template not found: {_TEMPLATE}")

    today = date.today().strftime("%d.%m.%Y")

    # ── 1. Build overlay ──────────────────────────────────────────────────────
    overlay_buf = io.BytesIO()
    c = rl_canvas.Canvas(overlay_buf, pagesize=(PAGE_W, PAGE_H))

    # Cover the original name with white
    c.setFillColorRGB(1, 1, 1)
    c.setStrokeColorRGB(1, 1, 1)
    c.rect(170, 600, 510, 75, fill=1, stroke=0)

    # Draw new name — reduce font size for long names
    font_size = 48.0
    while (
        c.stringWidth(full_name, "Helvetica-Bold", font_size) > 490
        and font_size >= 24
    ):
        font_size -= 2
    c.setFont("Helvetica-Bold", font_size)
    c.setFillColorRGB(*WINE)
    # Keep baseline vertically centred in the original slot when font is smaller
    name_y = 612.15 + (48 - font_size) / 2
    c.drawCentredString(PAGE_W / 2, name_y, full_name)

    # Cover the original date with white
    c.setFillColorRGB(1, 1, 1)
    c.setStrokeColorRGB(1, 1, 1)
    c.rect(130, 305, 235, 28, fill=1, stroke=0)

    # Draw today's date at the original position (x=171.11, y=313.58)
    c.setFont("Helvetica", 16)
    c.setFillColorRGB(0, 0, 0)
    c.drawString(171.11, 313.58, today)

    c.showPage()
    c.save()

    # ── 2. Merge overlay onto template ────────────────────────────────────────
    template_reader = PdfReader(str(_TEMPLATE))
    overlay_reader = PdfReader(io.BytesIO(overlay_buf.getvalue()))

    writer = PdfWriter()
    page = template_reader.pages[0]
    page.merge_page(overlay_reader.pages[0])
    writer.add_page(page)

    out_buf = io.BytesIO()
    writer.write(out_buf)

    log.info("certificate.generated", name=full_name, serial=serial)
    return await save_bytes(
        out_buf.getvalue(),
        folder="certificates",
        filename=f"{serial}.pdf",
        content_type="application/pdf",
    )
