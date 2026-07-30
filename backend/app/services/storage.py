"""File storage abstraction — S3/R2 when configured, local disk otherwise.

Used for audio recordings, lesson/audiobook media and generated certificates.

Two access patterns live here:

* ``save_bytes`` / ``load_bytes`` — small files the backend itself handles
  (covers, certificates, short audio).
* the ``multipart_*`` / ``presign_*`` helpers — large files (lesson videos)
  that must never pass through the API process. The browser uploads parts
  straight to the bucket with presigned PUT URLs and the backend only brokers
  the handshake.
"""
from __future__ import annotations

import asyncio
import uuid
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from pathlib import Path
from typing import Any
from urllib.parse import quote

from app.core.config import settings
from app.core.logging import get_logger

log = get_logger("storage")


def _safe_name(filename: str) -> str:
    suffix = Path(filename).suffix
    return f"{uuid.uuid4().hex}{suffix}"


def s3_enabled() -> bool:
    """True when object storage is configured; otherwise local disk is used."""
    return bool(settings.s3_bucket and settings.s3_access_key and settings.s3_secret_key)


def _client_cm() -> Any:
    """Build an aioboto3 S3 client context manager for the configured bucket.

    R2 requires SigV4 and rejects the checksum trailers boto3 started sending
    by default in 2025, so both are pinned explicitly here.
    """
    import aioboto3  # imported lazily — only needed when S3 is configured
    from botocore.config import Config

    session = aioboto3.Session()
    return session.client(
        "s3",
        endpoint_url=settings.s3_endpoint or None,
        region_name=settings.s3_region,
        aws_access_key_id=settings.s3_access_key,
        aws_secret_access_key=settings.s3_secret_key,
        config=Config(
            signature_version="s3v4",
            request_checksum_calculation="when_required",
            response_checksum_validation="when_required",
            # Playlist rewriting presigns hundreds of segment URLs per request;
            # the pool must not become the bottleneck.
            max_pool_connections=50,
        ),
    )


# Building a botocore client parses the S3 service model — tens of
# milliseconds. Presigning a variant playlist does that hundreds of times, so
# the client is created once and reused for the process lifetime.
_shared: Any = None
_shared_cm: Any = None
_shared_lock = asyncio.Lock()


@asynccontextmanager
async def _client() -> AsyncIterator[Any]:
    """Yield the shared S3 client. Exiting the block does not close it."""
    global _shared, _shared_cm
    if _shared is None:
        async with _shared_lock:
            if _shared is None:
                _shared_cm = _client_cm()
                _shared = await _shared_cm.__aenter__()
    yield _shared


async def close_client() -> None:
    """Release the shared S3 client (called on app/worker shutdown)."""
    global _shared, _shared_cm
    if _shared_cm is not None:
        await _shared_cm.__aexit__(None, None, None)
        _shared, _shared_cm = None, None


# ───────────────────────── simple object put/get ─────────────────────────


async def save_bytes(
    data: bytes, *, folder: str, filename: str, content_type: str | None = None
) -> str:
    """Persist bytes and return a retrievable URL/path."""
    name = _safe_name(filename)

    if s3_enabled():
        key = f"{folder}/{name}"
        async with _client() as s3:
            await s3.put_object(
                Bucket=settings.s3_bucket,
                Key=key,
                Body=data,
                ContentType=content_type or "application/octet-stream",
            )
        log.info("storage.saved_s3", key=key, size=len(data))
        return object_url(key)

    # Local fallback — file IO off the event loop (uploads reach 64MB)
    base = Path(settings.local_media_dir) / folder
    base.mkdir(parents=True, exist_ok=True)
    path = base / name
    await asyncio.to_thread(path.write_bytes, data)
    url = f"/media/{folder}/{name}"
    log.info("storage.saved_local", path=str(path))
    return url


async def save_stream(
    upload: Any, *, folder: str, filename: str, content_type: str | None = None
) -> tuple[str, int]:
    """Stream a Starlette ``UploadFile`` to storage without buffering it in RAM.

    Returns ``(url, bytes_written)``. Used by the local-dev video upload path
    and by any large upload that still goes through the API.
    """
    name = _safe_name(filename)
    chunk_size = 1024 * 1024

    if s3_enabled():
        key = f"{folder}/{name}"
        async with _client() as s3:
            created = await s3.create_multipart_upload(
                Bucket=settings.s3_bucket,
                Key=key,
                ContentType=content_type or "application/octet-stream",
            )
            upload_id = created["UploadId"]
            parts: list[dict] = []
            total = 0
            # S3 requires every part but the last to be >= 5MiB, so chunks are
            # accumulated into a buffer before being flushed as a part.
            buf = bytearray()
            part_no = 1
            try:
                while True:
                    chunk = await upload.read(chunk_size)
                    if not chunk:
                        break
                    buf.extend(chunk)
                    total += len(chunk)
                    if len(buf) >= settings.video_upload_part_size_mb * 1024 * 1024:
                        res = await s3.upload_part(
                            Bucket=settings.s3_bucket, Key=key,
                            UploadId=upload_id, PartNumber=part_no, Body=bytes(buf),
                        )
                        parts.append({"ETag": res["ETag"], "PartNumber": part_no})
                        part_no += 1
                        buf.clear()
                if buf or not parts:
                    res = await s3.upload_part(
                        Bucket=settings.s3_bucket, Key=key,
                        UploadId=upload_id, PartNumber=part_no, Body=bytes(buf),
                    )
                    parts.append({"ETag": res["ETag"], "PartNumber": part_no})
                await s3.complete_multipart_upload(
                    Bucket=settings.s3_bucket, Key=key,
                    UploadId=upload_id, MultipartUpload={"Parts": parts},
                )
            except Exception:
                await s3.abort_multipart_upload(
                    Bucket=settings.s3_bucket, Key=key, UploadId=upload_id
                )
                raise
        log.info("storage.streamed_s3", key=key, size=total)
        return object_url(key), total

    base = Path(settings.local_media_dir) / folder
    base.mkdir(parents=True, exist_ok=True)
    path = base / name
    total = 0
    handle = await asyncio.to_thread(path.open, "wb")
    try:
        while True:
            chunk = await upload.read(chunk_size)
            if not chunk:
                break
            total += len(chunk)
            await asyncio.to_thread(handle.write, chunk)
    finally:
        await asyncio.to_thread(handle.close)
    log.info("storage.streamed_local", path=str(path), size=total)
    return f"/media/{folder}/{name}", total


async def load_bytes(url: str) -> bytes | None:
    """Load bytes back from a URL previously returned by ``save_bytes``.

    Local ``/media/...`` paths are read from disk; S3/R2 objects are fetched
    from the bucket. Unrecognised external URLs return None.
    """
    if not url:
        return None
    if url.startswith("/media/"):
        rel = url[len("/media/"):]
        path = Path(settings.local_media_dir) / rel
        if path.exists():
            return await asyncio.to_thread(path.read_bytes)
        log.warning("storage.load_bytes_missing", url=url)
        return None

    key = key_from_url(url)
    if key is None or not s3_enabled():
        return None
    try:
        async with _client() as s3:
            res = await s3.get_object(Bucket=settings.s3_bucket, Key=key)
            return await res["Body"].read()
    except Exception as exc:  # object missing / access denied
        log.warning("storage.load_bytes_failed", url=url, error=str(exc))
        return None


async def delete_prefix(prefix: str) -> None:
    """Delete every object under ``prefix`` (used when a video is replaced)."""
    if not s3_enabled():
        base = Path(settings.local_media_dir) / prefix
        if base.exists():
            import shutil

            await asyncio.to_thread(shutil.rmtree, base, True)
        return

    async with _client() as s3:
        token: str | None = None
        while True:
            kwargs = {"Bucket": settings.s3_bucket, "Prefix": prefix}
            if token:
                kwargs["ContinuationToken"] = token
            listing = await s3.list_objects_v2(**kwargs)
            objects = [{"Key": o["Key"]} for o in listing.get("Contents", [])]
            if objects:
                await s3.delete_objects(
                    Bucket=settings.s3_bucket, Delete={"Objects": objects}
                )
            if not listing.get("IsTruncated"):
                break
            token = listing.get("NextContinuationToken")
    log.info("storage.deleted_prefix", prefix=prefix)


# ───────────────────────── URL helpers ─────────────────────────


def object_url(key: str) -> str:
    """Canonical stored URL for an object key.

    Prefers the CDN origin so the API host never serves media bytes.
    """
    if settings.s3_public_base_url:
        return f"{settings.s3_public_base_url.rstrip('/')}/{quote(key)}"
    if settings.s3_endpoint:
        return f"{settings.s3_endpoint.rstrip('/')}/{settings.s3_bucket}/{quote(key)}"
    return f"https://{settings.s3_bucket}.s3.amazonaws.com/{quote(key)}"


def key_from_url(url: str) -> str | None:
    """Inverse of :func:`object_url` — recover the object key from a stored URL.

    Returns None for local ``/media/...`` paths and unrecognised hosts.
    """
    from urllib.parse import unquote, urlparse

    if not url or url.startswith("/media/"):
        return None
    # (base, bucket is part of the path) — the raw endpoint form includes the
    # bucket as the first path segment, a CDN custom domain does not.
    for base, bucket_prefixed in (
        (settings.s3_public_base_url, False),
        (settings.s3_endpoint, True),
    ):
        if base and url.startswith(base.rstrip("/") + "/"):
            rest = url[len(base.rstrip("/")) + 1:]
            if bucket_prefixed and rest.startswith(settings.s3_bucket + "/"):
                rest = rest[len(settings.s3_bucket) + 1:]
            return unquote(rest)
    parsed = urlparse(url)
    if not parsed.netloc:
        return None
    path = unquote(parsed.path.lstrip("/"))
    if path.startswith(settings.s3_bucket + "/"):
        path = path[len(settings.s3_bucket) + 1:]
    return path or None


async def presign_get(key: str, *, ttl: int | None = None) -> str:
    """Presigned GET URL for a private object.

    Falls back to the plain object URL when S3 is not configured (local dev),
    where nginx serves ``/media`` directly.
    """
    if not s3_enabled():
        return f"/media/{key}"
    async with _client() as s3:
        return await s3.generate_presigned_url(
            "get_object",
            Params={"Bucket": settings.s3_bucket, "Key": key},
            ExpiresIn=ttl or settings.media_signed_url_ttl_sec,
        )


# ───────────────────── browser → storage multipart ─────────────────────


async def multipart_create(
    key: str, *, content_type: str, part_count: int
) -> tuple[str, list[str]]:
    """Open a multipart upload and presign a PUT URL for every part.

    Returns ``(upload_id, part_urls)`` where ``part_urls[i]`` uploads part
    ``i + 1``. The browser PUTs the parts in parallel and reports back the
    ETags to :func:`multipart_complete`.
    """
    async with _client() as s3:
        created = await s3.create_multipart_upload(
            Bucket=settings.s3_bucket, Key=key, ContentType=content_type
        )
        upload_id = created["UploadId"]
        urls = []
        for part_no in range(1, part_count + 1):
            urls.append(
                await s3.generate_presigned_url(
                    "upload_part",
                    Params={
                        "Bucket": settings.s3_bucket,
                        "Key": key,
                        "UploadId": upload_id,
                        "PartNumber": part_no,
                    },
                    ExpiresIn=settings.video_upload_url_ttl_sec,
                )
            )
    log.info("storage.multipart_created", key=key, parts=part_count)
    return upload_id, urls


async def multipart_complete(
    key: str, upload_id: str, parts: list[dict[str, Any]]
) -> str:
    """Finalise a multipart upload. ``parts`` is ``[{PartNumber, ETag}, ...]``."""
    ordered = sorted(parts, key=lambda p: p["PartNumber"])
    async with _client() as s3:
        await s3.complete_multipart_upload(
            Bucket=settings.s3_bucket,
            Key=key,
            UploadId=upload_id,
            MultipartUpload={"Parts": ordered},
        )
    log.info("storage.multipart_completed", key=key, parts=len(ordered))
    return object_url(key)


async def multipart_abort(key: str, upload_id: str) -> None:
    """Discard an incomplete multipart upload so its parts stop being billed."""
    try:
        async with _client() as s3:
            await s3.abort_multipart_upload(
                Bucket=settings.s3_bucket, Key=key, UploadId=upload_id
            )
        log.info("storage.multipart_aborted", key=key)
    except Exception as exc:
        log.warning("storage.multipart_abort_failed", key=key, error=str(exc))


async def upload_file(
    path: Path, key: str, *, content_type: str | None = None
) -> str:
    """Upload a local file to object storage (used by the transcode worker)."""
    if not s3_enabled():
        dest = Path(settings.local_media_dir) / key
        dest.parent.mkdir(parents=True, exist_ok=True)
        await asyncio.to_thread(dest.write_bytes, path.read_bytes())
        return f"/media/{key}"
    async with _client() as s3:
        await s3.upload_file(
            str(path),
            settings.s3_bucket,
            key,
            ExtraArgs={"ContentType": content_type} if content_type else None,
        )
    return object_url(key)


async def download_file(key: str, dest: Path) -> None:
    """Download an object to a local path (used by the transcode worker)."""
    if not s3_enabled():
        src = Path(settings.local_media_dir) / key
        await asyncio.to_thread(dest.write_bytes, src.read_bytes())
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    async with _client() as s3:
        await s3.download_file(settings.s3_bucket, key, str(dest))
