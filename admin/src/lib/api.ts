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
      | { error?: { code?: string; message?: string; details?: unknown } }
      | undefined;
    const error = data?.error;
    if (error?.message) {
      // Pydantic 422 validation errors: surface the first field-level message
      // so the user sees "Parol kamida 6 ta belgidan iborat bo'lishi kerak"
      // instead of a generic "Validation failed".
      if (error.code === "validation_error" && Array.isArray(error.details)) {
        const first = (error.details as Array<{ msg?: string; loc?: unknown[] }>)[0];
        const field = Array.isArray(first?.loc)
          ? String((first!.loc as unknown[]).slice(-1)[0] ?? "")
          : "";
        const msg = first?.msg ? translateValidationMsg(first.msg) : null;
        if (msg) {
          return field ? `${humanField(field)}: ${msg}` : msg;
        }
      }
      return error.message;
    }
    // Network / CORS / no response.
    if (err.code === "ERR_NETWORK") return "Server bilan bogʻlanib boʻlmadi.";
    if (err.code === "ECONNABORTED") return "Soʻrov vaqti tugadi.";
    return err.message || "Kutilmagan xatolik";
  }
  if (err instanceof Error && err.message) return err.message;
  return "Kutilmagan xatolik";
}

function humanField(name: string): string {
  const map: Record<string, string> = {
    email: "Email",
    password: "Parol",
    phone: "Telefon",
    code: "Kod",
    full_name: "Ism",
  };
  return map[name] ?? name;
}

function translateValidationMsg(msg: string): string | null {
  const m = msg.toLowerCase();
  if (m.includes("at least 6 characters")) return "kamida 6 ta belgidan iborat boʻlishi kerak";
  if (m.includes("at least")) return `kamida ${(m.match(/at least (\d+)/)?.[1] ?? "0")} ta belgi kerak`;
  if (m.includes("at most")) return `koʻpi bilan ${(m.match(/at most (\d+)/)?.[1] ?? "0")} ta belgi`;
  if (m.includes("value is not a valid email")) return "toʻgʻri email formatida emas";
  if (m.includes("field required")) return "toʻldirilishi shart";
  return null;
}
