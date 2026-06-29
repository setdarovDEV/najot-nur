import axios from "axios";

const API_URL =
  import.meta.env.VITE_API_URL ?? "http://localhost:8000/api/v1";

/** WebSocket base URL (same prefix as API_URL but with ``ws`` scheme). */
export const WS_URL: string = (() => {
  const explicit = (import.meta.env.VITE_WS_URL as string | undefined)?.trim();
  if (explicit) return explicit.replace(/\/+$/, "");
  return API_URL.replace(/^http/, "ws");
})();

export const TOKEN_KEY = "notiq_admin_token";

export const api = axios.create({ baseURL: API_URL });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

/**
 * Handler invoked when the server rejects a request with 401 (token expired or
 * invalid). Registered by the auth provider so it can clear React state and
 * redirect to the login page. Defined outside React because interceptors run
 * outside the component tree.
 */
let onUnauthorized: (() => void) | null = null;

export function setUnauthorizedHandler(fn: (() => void) | null): void {
  onUnauthorized = fn;
}

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (axios.isAxiosError(err) && err.response?.status === 401) {
      const url = err.config?.url ?? "";
      // A failed login also returns 401 — don't treat that as a session expiry.
      if (!url.includes("/auth/login")) {
        localStorage.removeItem(TOKEN_KEY);
        onUnauthorized?.();
      }
    }
    return Promise.reject(err);
  },
);

/** Returns true if a JWT's `exp` claim is in the past (or it can't be parsed). */
export function isTokenExpired(token: string): boolean {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    if (typeof payload.exp !== "number") return false;
    return payload.exp * 1000 <= Date.now();
  } catch {
    return true;
  }
}

/** Convert a relative /media/... path from the backend to a full URL. */
export function mediaUrl(path: string | null | undefined): string | null {
  if (!path) return null;
  if (path.startsWith("http")) return path;
  const base = (import.meta.env.VITE_API_URL ?? "http://localhost:8000/api/v1").replace(/\/api\/v1\/?$/, "");
  return `${base}${path}`;
}

/** Extract a human-friendly message from the API error envelope. */
export function apiError(err: unknown): string {
  if (axios.isAxiosError(err)) {
    const data = err.response?.data as
      | { error?: { message?: string } }
      | undefined;
    return data?.error?.message ?? err.message;
  }
  return "Kutilmagan xatolik";
}
