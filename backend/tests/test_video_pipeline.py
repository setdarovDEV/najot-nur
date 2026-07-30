"""Tests for the lesson-video pipeline: storage URL mapping, playback tokens
and the ffmpeg HLS ladder.

These are the pure pieces of the pipeline. The parts that need real infra
(R2 multipart, ffmpeg execution) are exercised by the integration flow, not
here — what these guard is the logic that silently breaks playback if it
regresses: a key that no longer round-trips means presigning the wrong object,
and a token that verifies loosely means paid videos leak.
"""
from __future__ import annotations

import time
import uuid

import pytest

from app.api.v1.courses import _playback_token, _playback_token_valid
from app.core.config import settings
from app.services import storage
from app.workers.transcode import Rung, _build_hls_args, parse_ladder


# ───────────────────────── storage URL mapping ─────────────────────────


def test_object_url_prefers_cdn(monkeypatch: pytest.MonkeyPatch) -> None:
    """Playback must go through the CDN host, not the S3 API endpoint."""
    monkeypatch.setattr(settings, "s3_public_base_url", "https://cdn.notiqlik.uz")
    monkeypatch.setattr(settings, "s3_endpoint", "https://acct.r2.cloudflarestorage.com")
    monkeypatch.setattr(settings, "s3_bucket", "notiqai-media")

    assert storage.object_url("videos/a/hls/master.m3u8") == (
        "https://cdn.notiqlik.uz/videos/a/hls/master.m3u8"
    )


def test_key_round_trips_through_cdn_url(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "s3_public_base_url", "https://cdn.notiqlik.uz")
    monkeypatch.setattr(settings, "s3_bucket", "notiqai-media")

    key = "videos/abc/video.mp4"
    assert storage.key_from_url(storage.object_url(key)) == key


def test_key_round_trips_through_endpoint_url(monkeypatch: pytest.MonkeyPatch) -> None:
    """Without a CDN domain the bucket is part of the path and must be stripped."""
    monkeypatch.setattr(settings, "s3_public_base_url", "")
    monkeypatch.setattr(settings, "s3_endpoint", "https://acct.r2.cloudflarestorage.com")
    monkeypatch.setattr(settings, "s3_bucket", "notiqai-media")

    key = "videos/abc/video.mp4"
    assert storage.key_from_url(storage.object_url(key)) == key


def test_local_media_path_has_no_key() -> None:
    """Local dev paths are served by nginx and must never be presigned."""
    assert storage.key_from_url("/media/videos/x.mp4") is None


# ───────────────────────── playback tokens ─────────────────────────


def test_playback_token_validates_for_its_own_lesson() -> None:
    lesson_id = uuid.uuid4()
    assert _playback_token_valid(lesson_id, _playback_token(lesson_id))


def test_playback_token_rejected_for_another_lesson() -> None:
    """A token for a demo lesson must not unlock a paid one."""
    token = _playback_token(uuid.uuid4())
    assert not _playback_token_valid(uuid.uuid4(), token)


def test_expired_playback_token_is_rejected() -> None:
    lesson_id = uuid.uuid4()
    token = _playback_token(lesson_id)
    exp, _, sig = token.partition(".")
    stale = f"{int(time.time()) - 10}.{sig}"
    assert not _playback_token_valid(lesson_id, stale)


@pytest.mark.parametrize("bad", [None, "", "nonsense", "abc.def", "123"])
def test_malformed_playback_tokens_are_rejected(bad: str | None) -> None:
    assert not _playback_token_valid(uuid.uuid4(), bad)


# ───────────────────────── HLS ladder ─────────────────────────


def test_ladder_parses_and_sorts_ascending() -> None:
    rungs = parse_ladder("1080:5000:192,360:800:96,720:2500:128")
    assert [r.height for r in rungs] == [360, 720, 1080]
    assert rungs[0] == Rung(360, 800, 96)


def test_hls_args_map_every_rendition_with_audio(tmp_path) -> None:
    args = _build_hls_args([Rung(360, 800, 96), Rung(720, 2500, 128)], tmp_path, True)
    var_map = args[args.index("-var_stream_map") + 1]
    assert var_map == "v:0,a:0 v:1,a:1"
    assert "-b:v:0" in args and "800k" in args
    assert "-b:a:1" in args and "128k" in args


def test_hls_args_omit_audio_for_silent_sources(tmp_path) -> None:
    """A source with no audio track must not get audio entries in the map —
    ffmpeg fails outright if the stream map references a stream it lacks."""
    args = _build_hls_args([Rung(360, 800, 96), Rung(720, 2500, 128)], tmp_path, False)
    var_map = args[args.index("-var_stream_map") + 1]
    assert var_map == "v:0 v:1"
    assert not any(a.startswith("-c:a") for a in args)


def test_hls_keyframes_align_to_segment_boundaries(tmp_path) -> None:
    """Renditions must cut at identical timestamps or bitrate switching stalls."""
    args = _build_hls_args([Rung(360, 800, 96)], tmp_path, True)
    expr = args[args.index("-force_key_frames") + 1]
    assert expr == f"expr:gte(t,n_forced*{settings.video_hls_segment_sec})"
