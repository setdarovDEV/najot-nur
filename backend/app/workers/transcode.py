"""Lesson video transcoding — MP4 source → HLS adaptive-bitrate ladder.

Runs in the arq worker, never in the API process: a 2GB source takes minutes
of CPU and would otherwise block request handling.

Pipeline per lesson:

1. download the uploaded MP4 from object storage to a temp dir
2. ffprobe it for dimensions, duration and whether it has an audio track
3. ffmpeg it into 360p/720p/1080p HLS renditions + a master playlist
   (rungs above the source height are skipped — never upscale)
4. remux the source to a faststart MP4 so the non-HLS fallback also starts
   without downloading the whole file first
5. extract a poster frame
6. upload everything under ``videos/{lesson_id}/`` and mark the lesson ready

The lesson row carries ``video_status`` (pending → processing → ready/failed)
so the admin UI and the mobile player can show progress instead of a broken
video element.
"""
from __future__ import annotations

import asyncio
import json
import shutil
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy import update

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.core.logging import get_logger
from app.models.course import Lesson
from app.services import storage

log = get_logger("transcode")


@dataclass(frozen=True)
class Rung:
    height: int
    video_kbps: int
    audio_kbps: int


def parse_ladder(spec: str) -> list[Rung]:
    """Parse ``"360:800:96,720:2500:128"`` into rungs, ordered low → high."""
    rungs: list[Rung] = []
    for item in spec.split(","):
        item = item.strip()
        if not item:
            continue
        height, video_kbps, audio_kbps = item.split(":")
        rungs.append(Rung(int(height), int(video_kbps), int(audio_kbps)))
    return sorted(rungs, key=lambda r: r.height)


async def _run(*args: str, cwd: Path | None = None) -> str:
    """Run a subprocess, raising with captured stderr when it fails."""
    proc = await asyncio.create_subprocess_exec(
        *args,
        cwd=str(cwd) if cwd else None,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(
            f"{args[0]} exited {proc.returncode}: {stderr.decode(errors='replace')[-2000:]}"
        )
    return stdout.decode(errors="replace")


async def _probe(path: Path) -> dict:
    """Return ``{width, height, duration, has_audio}`` for a media file."""
    raw = await _run(
        settings.ffprobe_binary,
        "-v", "error",
        "-print_format", "json",
        "-show_streams",
        "-show_format",
        str(path),
    )
    data = json.loads(raw)
    streams = data.get("streams", [])
    video = next((s for s in streams if s.get("codec_type") == "video"), None)
    has_audio = any(s.get("codec_type") == "audio" for s in streams)
    duration = float(data.get("format", {}).get("duration") or 0)
    if video is None:
        raise RuntimeError("source has no video stream")
    # Rotated phone footage reports raw dimensions; the display height is what
    # the ladder must be compared against.
    width = int(video.get("width") or 0)
    height = int(video.get("height") or 0)
    rotation = 0
    for entry in video.get("side_data_list") or []:
        if "rotation" in entry:
            rotation = abs(int(entry["rotation"])) % 180
    if rotation == 90:
        width, height = height, width
    return {"width": width, "height": height, "duration": duration, "has_audio": has_audio}


def _build_hls_args(rungs: list[Rung], out_dir: Path, has_audio: bool) -> list[str]:
    """Assemble the single-pass ffmpeg command that emits the whole ladder."""
    n = len(rungs)
    # One decode, split N ways — far cheaper than N separate ffmpeg runs.
    split = f"[0:v]split={n}" + "".join(f"[v{i}]" for i in range(n)) + ";"
    scales = ";".join(
        # -2 keeps the width even (H.264 requirement) while preserving aspect.
        # format=yuv420p is not optional: sources that arrive as 4:2:2 or 4:4:4
        # (ProRes exports, some screen recorders) cannot be encoded in the main
        # profile at all, and HLS on iOS only decodes 4:2:0.
        f"[v{i}]scale=w=-2:h={r.height},format=yuv420p[v{i}out]"
        for i, r in enumerate(rungs)
    )
    args: list[str] = ["-filter_complex", split + scales]

    for i, rung in enumerate(rungs):
        args += [
            "-map", f"[v{i}out]",
            f"-c:v:{i}", "libx264",
            f"-b:v:{i}", f"{rung.video_kbps}k",
            f"-maxrate:v:{i}", f"{int(rung.video_kbps * 1.2)}k",
            f"-bufsize:v:{i}", f"{rung.video_kbps * 2}k",
        ]
    if has_audio:
        for i, rung in enumerate(rungs):
            args += ["-map", "a:0", f"-c:a:{i}", "aac", f"-b:a:{i}", f"{rung.audio_kbps}k"]
        args += ["-ac", "2"]

    var_map = " ".join(
        f"v:{i},a:{i}" if has_audio else f"v:{i}" for i in range(n)
    )
    args += [
        "-preset", "veryfast",
        "-profile:v", "main",
        "-sc_threshold", "0",
        # Keyframes forced exactly on segment boundaries, expressed in seconds
        # rather than frames so the alignment holds for any source frame rate.
        # Renditions therefore cut at identical timestamps, which is what makes
        # mid-stream bitrate switching seamless.
        "-force_key_frames", f"expr:gte(t,n_forced*{settings.video_hls_segment_sec})",
        "-f", "hls",
        "-hls_time", str(settings.video_hls_segment_sec),
        "-hls_playlist_type", "vod",
        "-hls_flags", "independent_segments",
        "-hls_segment_filename", str(out_dir / "v%v" / "seg_%04d.ts"),
        "-master_pl_name", "master.m3u8",
        "-var_stream_map", var_map,
        str(out_dir / "v%v" / "index.m3u8"),
    ]
    return args


async def _upload_dir(local: Path, key_prefix: str) -> None:
    """Upload a rendered HLS tree, playlists last.

    Segments go up first so a player that fetches a playlist the moment it
    appears never references a segment that is not there yet.
    """
    files = sorted(
        (p for p in local.rglob("*") if p.is_file()),
        key=lambda p: p.suffix == ".m3u8",
    )
    sem = asyncio.Semaphore(8)

    async def put(path: Path) -> None:
        rel = path.relative_to(local).as_posix()
        ctype = (
            "application/vnd.apple.mpegurl"
            if path.suffix == ".m3u8"
            else "video/mp2t"
        )
        async with sem:
            await storage.upload_file(path, f"{key_prefix}/{rel}", content_type=ctype)

    # Playlists are uploaded only after every segment has landed.
    segments = [p for p in files if p.suffix != ".m3u8"]
    playlists = [p for p in files if p.suffix == ".m3u8"]
    await asyncio.gather(*(put(p) for p in segments))
    await asyncio.gather(*(put(p) for p in playlists))


async def _set_status(lesson_id: uuid.UUID, **values: object) -> None:
    async with AsyncSessionLocal() as db:
        await db.execute(update(Lesson).where(Lesson.id == lesson_id).values(**values))
        await db.commit()


async def transcode_lesson_video(ctx: dict, lesson_id: str, source_key: str) -> dict:
    """arq job: build the HLS ladder for one lesson video."""
    lid = uuid.UUID(lesson_id)
    log.info("transcode.start", lesson_id=lesson_id, source_key=source_key)
    await _set_status(lid, video_status="processing")

    tmp = Path(tempfile.mkdtemp(prefix=f"transcode_{lesson_id}_"))
    try:
        source = tmp / "source.mp4"
        await storage.download_file(source_key, source)

        info = await _probe(source)
        rungs = [r for r in parse_ladder(settings.video_hls_ladder) if r.height <= info["height"]]
        if not rungs:
            # Source is smaller than the lowest rung — encode it at its own
            # height rather than skipping HLS entirely.
            lowest = parse_ladder(settings.video_hls_ladder)[0]
            rungs = [Rung(info["height"], lowest.video_kbps, lowest.audio_kbps)]

        out_dir = tmp / "hls"
        for i in range(len(rungs)):
            (out_dir / f"v{i}").mkdir(parents=True, exist_ok=True)

        await _run(
            settings.ffmpeg_binary, "-y", "-i", str(source),
            *_build_hls_args(rungs, out_dir, info["has_audio"]),
        )

        # Poster frame — 10% in, so it isn't a black fade-in title card.
        poster = tmp / "poster.jpg"
        await _run(
            settings.ffmpeg_binary, "-y",
            "-ss", str(max(1.0, info["duration"] * 0.1)),
            "-i", str(source), "-frames:v", "1", "-q:v", "3",
            "-vf", "scale=-2:720", str(poster),
        )

        # Faststart remux (stream copy — no re-encode) so the MP4 fallback
        # also starts playing before the whole file has downloaded.
        fast = tmp / "faststart.mp4"
        await _run(
            settings.ffmpeg_binary, "-y", "-i", str(source),
            "-c", "copy", "-movflags", "+faststart", str(fast),
        )

        prefix = f"videos/{lesson_id}"
        await _upload_dir(out_dir, f"{prefix}/hls")
        poster_url = await storage.upload_file(
            poster, f"{prefix}/poster.jpg", content_type="image/jpeg"
        )
        mp4_url = await storage.upload_file(
            fast, f"{prefix}/video.mp4", content_type="video/mp4"
        )
        hls_url = storage.object_url(f"{prefix}/hls/master.m3u8")

        await _set_status(
            lid,
            hls_url=hls_url,
            poster_url=poster_url,
            video_url=mp4_url,
            duration_sec=int(info["duration"]),
            video_status="ready",
        )
        log.info(
            "transcode.done",
            lesson_id=lesson_id,
            renditions=[r.height for r in rungs],
            duration=int(info["duration"]),
        )
        # The raw upload is superseded by the faststart remux.
        if source_key != f"{prefix}/video.mp4":
            await storage.delete_prefix(source_key)
        return {"hls_url": hls_url, "renditions": [r.height for r in rungs]}

    except Exception as exc:
        log.error("transcode.failed", lesson_id=lesson_id, error=str(exc))
        await _set_status(lid, video_status="failed")
        raise
    finally:
        await asyncio.to_thread(shutil.rmtree, tmp, True)
