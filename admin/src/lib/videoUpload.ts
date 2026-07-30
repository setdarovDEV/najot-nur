/**
 * Direct-to-storage video upload.
 *
 * The file never touches the API: the backend hands out presigned part URLs,
 * the browser PUTs the parts straight to object storage — several at once —
 * and then asks the backend to finalise. That removes three copies of every
 * byte (nginx buffer → API memory → disk) and lets slow parts be retried
 * individually instead of restarting a 2GB upload from zero.
 *
 * Falls back to the legacy single-request endpoint when object storage is not
 * configured (local dev), which the init call reports as HTTP 409.
 */
import axios from "axios";

import { api } from "./api";

/** How many parts are in flight at once. */
const CONCURRENCY = 4;
/** Attempts per part before the whole upload is failed. */
const MAX_PART_RETRIES = 3;

export type UploadPhase = "uploading" | "finalizing";

export interface UploadProgress {
  /** 0–100 across the whole file. */
  percent: number;
  phase: UploadPhase;
  /** Bytes per second, averaged over the upload so far. */
  bytesPerSecond: number;
  /** Seconds remaining at the current rate, or null before a rate is known. */
  etaSeconds: number | null;
}

export interface UploadResult {
  video_url: string;
  video_status: string | null;
}

interface InitResponse {
  key: string;
  upload_id: string;
  part_size: number;
  part_urls: string[];
}

/** Raised when the caller aborts; lets the UI stay silent instead of erroring. */
export class UploadCancelled extends Error {
  constructor() {
    super("cancelled");
    this.name = "UploadCancelled";
  }
}

export interface UploadHandle {
  promise: Promise<UploadResult>;
  cancel: () => void;
}

export function uploadLessonVideo(
  lessonId: string,
  file: File,
  onProgress: (p: UploadProgress) => void,
): UploadHandle {
  const controller = new AbortController();
  const promise = run(lessonId, file, onProgress, controller.signal);
  return { promise, cancel: () => controller.abort() };
}

async function run(
  lessonId: string,
  file: File,
  onProgress: (p: UploadProgress) => void,
  signal: AbortSignal,
): Promise<UploadResult> {
  let init: InitResponse;
  try {
    const res = await api.post<InitResponse>(
      `/admin/lessons/${lessonId}/video/init`,
      {
        filename: file.name,
        content_type: file.type || "video/mp4",
        size: file.size,
      },
      { signal },
    );
    init = res.data;
  } catch (err) {
    // 409 = storage not configured; fall back to the direct upload endpoint.
    if (axios.isAxiosError(err) && err.response?.status === 409) {
      return legacyUpload(lessonId, file, onProgress, signal);
    }
    throw err;
  }

  const started = Date.now();
  // Per-part byte counters, so a retried part cannot double-count progress.
  const loaded = new Array<number>(init.part_urls.length).fill(0);

  const report = (phase: UploadPhase) => {
    const total = loaded.reduce((a, b) => a + b, 0);
    const elapsed = (Date.now() - started) / 1000;
    const rate = elapsed > 0 ? total / elapsed : 0;
    onProgress({
      // The last 2% is reserved for finalizing so the bar never sits at 100%
      // while the backend is still completing the upload.
      percent: phase === "finalizing" ? 99 : Math.round((total / file.size) * 98),
      phase,
      bytesPerSecond: rate,
      etaSeconds: rate > 0 ? Math.max(0, (file.size - total) / rate) : null,
    });
  };
  report("uploading");

  const etags = new Array<string>(init.part_urls.length);
  let nextPart = 0;

  const worker = async (): Promise<void> => {
    for (;;) {
      const index = nextPart++;
      if (index >= init.part_urls.length) return;
      if (signal.aborted) throw new UploadCancelled();

      const start = index * init.part_size;
      const blob = file.slice(start, Math.min(start + init.part_size, file.size));

      let lastError: unknown;
      for (let attempt = 0; attempt < MAX_PART_RETRIES; attempt++) {
        try {
          const res = await axios.put(init.part_urls[index], blob, {
            // Bare axios, not the `api` instance: the presigned URL carries
            // its own auth and an Authorization header would break signature
            // validation on some S3 implementations.
            signal,
            onUploadProgress: (evt) => {
              loaded[index] = evt.loaded;
              report("uploading");
            },
          });
          const etag = res.headers.etag ?? res.headers.ETag;
          if (!etag) throw new Error("Storage ETag qaytarmadi");
          etags[index] = String(etag);
          loaded[index] = blob.size;
          report("uploading");
          lastError = undefined;
          break;
        } catch (err) {
          if (signal.aborted) throw new UploadCancelled();
          lastError = err;
          loaded[index] = 0;
          // Exponential backoff — a transient 5xx or dropped connection
          // usually clears within a couple of seconds.
          await new Promise((r) => setTimeout(r, 500 * 2 ** attempt));
        }
      }
      if (lastError) throw lastError;
    }
  };

  try {
    await Promise.all(
      Array.from({ length: Math.min(CONCURRENCY, init.part_urls.length) }, worker),
    );
  } catch (err) {
    // Abandoned parts are billed until the multipart upload is aborted.
    void api
      .post(`/admin/lessons/${lessonId}/video/abort`, {
        key: init.key,
        upload_id: init.upload_id,
      })
      .catch(() => undefined);
    throw err;
  }

  report("finalizing");
  const done = await api.post<UploadResult>(
    `/admin/lessons/${lessonId}/video/complete`,
    {
      key: init.key,
      upload_id: init.upload_id,
      parts: etags.map((etag, i) => ({ part_number: i + 1, etag })),
    },
    // Assembling a few hundred parts server-side takes longer than the
    // client's 30s JSON default.
    { timeout: 300_000 },
  );
  onProgress({ percent: 100, phase: "finalizing", bytesPerSecond: 0, etaSeconds: 0 });
  return done.data;
}

/** Single-request upload through the API — local dev only. */
async function legacyUpload(
  lessonId: string,
  file: File,
  onProgress: (p: UploadProgress) => void,
  signal: AbortSignal,
): Promise<UploadResult> {
  const started = Date.now();
  const fd = new FormData();
  fd.append("file", file);
  const res = await api.post<UploadResult>(`/admin/lessons/${lessonId}/video`, fd, {
    signal,
    headers: { "Content-Type": "multipart/form-data" },
    onUploadProgress: (evt) => {
      const elapsed = (Date.now() - started) / 1000;
      const rate = elapsed > 0 ? evt.loaded / elapsed : 0;
      onProgress({
        percent: evt.total ? Math.round((evt.loaded / evt.total) * 100) : 0,
        phase: "uploading",
        bytesPerSecond: rate,
        etaSeconds: rate > 0 && evt.total ? (evt.total - evt.loaded) / rate : null,
      });
    },
  });
  return res.data;
}

/** "12.4 MB/s" */
export function formatRate(bytesPerSecond: number): string {
  if (bytesPerSecond <= 0) return "";
  const mb = bytesPerSecond / (1024 * 1024);
  return mb >= 1 ? `${mb.toFixed(1)} MB/s` : `${(bytesPerSecond / 1024).toFixed(0)} KB/s`;
}

/** "2 daq 15 s" */
export function formatEta(seconds: number | null): string {
  if (seconds === null || !isFinite(seconds) || seconds <= 0) return "";
  const total = Math.round(seconds);
  const min = Math.floor(total / 60);
  const sec = total % 60;
  return min > 0 ? `${min} daq ${sec} s` : `${sec} s`;
}
