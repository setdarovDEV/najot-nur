"""Idempotent seed data for local development / demos.

Run with:  python -m app.seeds.seed
"""
from __future__ import annotations

import asyncio

from slugify import slugify
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import AsyncSessionLocal
from app.core.logging import configure_logging, get_logger
from app.core.security import hash_password
from app.models.analysis import PronunciationReference
from app.models.audiobook import Audiobook, AudiobookPage
from app.models.course import Course, Lesson, LessonQuestion
from app.models.enums import AuthProvider, MediaType, ObservationCategory, Role
from app.models.observation import ObservationTest
from app.models.user import AuthIdentity, User

log = get_logger("seed")


async def _staff(db: AsyncSession, email: str, name: str, role: Role, password: str) -> None:
    exists = (
        await db.execute(
            select(AuthIdentity).where(
                AuthIdentity.provider == AuthProvider.password,
                AuthIdentity.provider_uid == email,
            )
        )
    ).scalar_one_or_none()
    if exists:
        return
    user = User(full_name=name, email=email, role=role, is_verified=True)
    db.add(user)
    await db.flush()
    db.add(
        AuthIdentity(
            user_id=user.id,
            provider=AuthProvider.password,
            provider_uid=email,
            password_hash=hash_password(password),
        )
    )
    log.info("seed.staff_created", email=email, role=role.value)


async def _references(db: AsyncSession) -> None:
    if (await db.execute(select(PronunciationReference).limit(1))).scalar_one_or_none():
        return
    texts = [
        (
            "Notiqlik san'ati",
            "Notiqlik san'ati miloddan avvalgi beshinchi asrda Yunonistonda "
            "shakllangan. Aristotel, Demosfen va Sitseron ritorikani yuksak "
            "cho'qqilarga olib chiqishgan.",
            "easy",
        ),
        (
            "Ishonchli ovoz",
            "Yaxshi notiq o'z ovozini boshqaradi. U pauzalardan to'g'ri "
            "foydalanadi, har bir so'zni aniq talaffuz qiladi va tinglovchini "
            "o'ziga jalb etadi.",
            "medium",
        ),
    ]
    for title, text, diff in texts:
        db.add(
            PronunciationReference(title=title, text=text, language="uz", difficulty=diff)
        )
    log.info("seed.references_created")


async def _observation_tests(db: AsyncSession) -> None:
    if (await db.execute(select(ObservationTest).limit(1))).scalar_one_or_none():
        return

    # 10 distinct, hand-written tests covering the three categories. The
    # `correct_option` index is 0-based; None means "open-ended" (no single
    # right answer — useful for AI-evaluated image interpretations).
    tests: list[ObservationTest] = [
        ObservationTest(
            order_index=1,
            title="Ishonchli qiyofa",
            prompt=(
                "Tasvirda notiq sahna ustida turibdi. Uning qo'l holati va "
                "ko'z qarashiga qarab, u auditoriyaga nisbatan qanday munosabat "
                "namoyish qilmoqda?"
            ),
            category=ObservationCategory.body_language,
            options=[
                "Ishonchli va ochiq",
                "Xavotirlangan",
                "Befarq",
                "Jiddiy va tarang",
            ],
            correct_option=0,
        ),
        ObservationTest(
            order_index=2,
            title="Yuz ifodasi",
            prompt=(
                "Kishining yuzida tabassum bor, lekin ko'zlari jiddiy. Bu qanday "
                "hisni anglatadi?"
            ),
            category=ObservationCategory.psychology,
            options=[
                "Samimiy quvonch",
                "Iltimos — emotsional masofa bilan",
                "Yashirin g'azab",
                "Oddiy xushmuomelalik",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=3,
            title="Qo'llar holati",
            prompt=(
                "Notiq qo'llarini ko'kragi oldida chalishtirib turibdi. Bu nima "
                "haqida signal beradi?"
            ),
            category=ObservationCategory.body_language,
            options=[
                "Himmat va qat'iyat",
                "O'zini himoya qilish, yopiq pozitsiya",
                "Fikr yuritish",
                "Sabrsizlik",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=4,
            title="Ko'z kontakti",
            prompt=(
                "Suhbatdosh ko'zini pastga qaratib, lekin sizga qarab boshini "
                "qiyshaytirib turibdi. Bu odatda nimani anglatadi?"
            ),
            category=ObservationCategory.psychology,
            options=[
                "Tinglamaslik",
                "Chuqur fikr yuritish yoki e'tibor",
                "Yolg'on gapirish",
                "Uyalish",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=5,
            title="Oyoq holati",
            prompt=(
                "Odam oyoqlarini chalishtirib o'tiribdi va tanasi suhbatdoshga "
                "qaratilgan. Bu nima haqida gapiradi?"
            ),
            category=ObservationCategory.body_language,
            options=[
                "Qochmoqchi",
                "Qiziqish va e'tibor",
                "Zerikish",
                "Tinchlik",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=6,
            title="Bosh harakati",
            prompt=(
                "Notiq har gapirganda boshi bilan bir oz pastga egiladi. Bu "
                "qanday taassurot qoldiradi?"
            ),
            category=ObservationCategory.observation,
            options=[
                "Ishonchli va hokim",
                "Iltimoskor va kamtar",
                "Tajovuzkor",
                "Befarq",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=7,
            title="Ovoz ohangi",
            prompt=(
                "Gapiruvchining ovozi past, sekin va bir xil ohangda. Tinglovchi "
                "bunga qanday munosabatda bo'ladi?"
            ),
            category=ObservationCategory.psychology,
            options=[
                "Diqqatni kuchaytiradi",
                "Zeriktiradi, e'tibor pasayadi",
                "Qo'rqitadi",
                "Iltimos qiladi",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=8,
            title="Yuz mimikasi",
            prompt=(
                "Kishi tez-tez qoshlarini chimirib, lablarini yalayapti. Bu "
                "odatda qanday holat?"
            ),
            category=ObservationCategory.body_language,
            options=[
                "Quvonch",
                "Xavotir yoki noqulaylik",
                "Jahl",
                "Befarqlik",
            ],
            correct_option=1,
        ),
        ObservationTest(
            order_index=9,
            title="Tana oriyentatsiyasi",
            prompt=(
                "Ikki kishi gaplashmoqda: birining tanasi to'liq suhbatdoshga "
                "qaratilgan, ikkinchisi yoni bilan turibdi. Kim ko'proq "
                "qiziqmoqda?"
            ),
            category=ObservationCategory.observation,
            options=[
                "Tana bilan qaratilgan",
                "Yoni bilan turgan",
                "Ikkalasi teng",
                "Hech qaysi",
            ],
            correct_option=0,
        ),
        ObservationTest(
            order_index=10,
            title="Ko'z qisish",
            prompt=(
                "Suhbatdosh ko'zini qisib, tez boshini boshqa tomonga burib "
                "yubordi. Bu ko'pincha nimani anglatadi?"
            ),
            category=ObservationCategory.psychology,
            options=[
                "Rozilik",
                "Ishonchsizlik yoki norozilik",
                "Qiziqish",
                "Charchoq",
            ],
            correct_option=1,
        ),
    ]

    # No media assets yet — questions describe hypothetical/typical scenes.
    for t in tests:
        t.media_type = MediaType.image
        t.media_url = None
        db.add(t)
    log.info("seed.observation_tests_created", count=len(tests))


async def _course(db: AsyncSession) -> None:
    slug = "notiqlik-asoslari"
    if (
        await db.execute(select(Course).where(Course.slug == slug))
    ).scalar_one_or_none():
        return
    course = Course(
        title="Notiqlik asoslari",
        slug=slug,
        description="Notiqlik mahoratining asosiy ko'nikmalari: ovoz, nutq, ishonch.",
        price=499000,
        level="beginner",
        is_published=True,
    )
    db.add(course)
    await db.flush()

    lessons = [
        ("Kirish: notiqlik nima?", False),
        ("Ovoz mashqlari", True),
        ("Nutq tuzilishi", False),
    ]
    for idx, (title, is_voice) in enumerate(lessons):
        lesson = Lesson(
            course_id=course.id,
            title=title,
            order_index=idx,
            duration_sec=600,
            is_voice_exercise=is_voice,
            voice_exercise_prompt=(
                "Diafragmadan nafas oling va 'a' tovushini 10 soniya cho'zing."
                if is_voice
                else None
            ),
        )
        db.add(lesson)
        await db.flush()
        db.add(
            LessonQuestion(
                lesson_id=lesson.id,
                question="Yaxshi notiq uchun eng muhim narsa nima?",
                options=["Tez gapirish", "Ishonch va aniqlik", "Baland ovoz", "Uzun gaplar"],
                correct_index=1,
                order_index=0,
            )
        )
    log.info("seed.course_created")


async def _audiobook(db: AsyncSession) -> None:
    slug = "notiqlik-sirlari"
    if (
        await db.execute(select(Audiobook).where(Audiobook.slug == slug))
    ).scalar_one_or_none():
        return
    book = Audiobook(
        title="Notiqlik sirlari",
        author="Najot Nur",
        slug=slug,
        description="Notiqlik bo'yicha bepul audiokitob.",
        category="Notiqlik",
        is_free=True,
        is_published=True,
    )
    db.add(book)
    await db.flush()
    for n in range(1, 4):
        db.add(
            AudiobookPage(
                audiobook_id=book.id,
                page_number=n,
                content=f"Bu {n}-sahifa matni. Notiqlik mashqlari va maslahatlar.",
            )
        )
    book.total_pages = 3
    log.info("seed.audiobook_created")


async def main() -> None:
    configure_logging()
    async with AsyncSessionLocal() as db:
        await _staff(db, "admin@najotnur.uz", "Bosh administrator", Role.admin, "admin123")
        await _staff(db, "curator@najotnur.uz", "Kurator", Role.curator, "curator123")
        await _references(db)
        await _observation_tests(db)
        await _course(db)
        await _audiobook(db)
        await db.commit()
    log.info("seed.done")


if __name__ == "__main__":
    asyncio.run(main())
