import axios from "axios";

const API_URL =
  import.meta.env.VITE_API_URL ?? "http://localhost:8000/api/v1";

export const WS_URL: string = (() => {
  const explicit = (import.meta.env.VITE_WS_URL as string | undefined)?.trim();
  if (explicit) return explicit.replace(/\/+$/, "");
  return API_URL.replace(/^http/, "ws");
})();

export const TOKEN_KEY = "notiq_curator_token";

// 30s default so a hung backend can't spin the UI forever; uploads
// (FormData bodies — up to 200MB quiz videos) get 10 minutes instead.
export const api = axios.create({ baseURL: API_URL, timeout: 30_000 });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem(TOKEN_KEY);
  if (token) config.headers.Authorization = `Bearer ${token}`;
  if (typeof FormData !== "undefined" && config.data instanceof FormData) {
    config.timeout = 600_000;
  }
  return config;
});

let onUnauthorized: (() => void) | null = null;

export function setUnauthorizedHandler(fn: (() => void) | null): void {
  onUnauthorized = fn;
}

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (axios.isAxiosError(err) && err.response?.status === 401) {
      const url = err.config?.url ?? "";
      if (!url.includes("/auth/login")) {
        localStorage.removeItem(TOKEN_KEY);
        onUnauthorized?.();
      }
    }
    return Promise.reject(err);
  },
);

export function isTokenExpired(token: string): boolean {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    if (typeof payload.exp !== "number") return false;
    return payload.exp * 1000 <= Date.now();
  } catch {
    return true;
  }
}

export function mediaUrl(path: string | null | undefined): string | null {
  if (!path) return null;
  if (path.startsWith("http")) return path;
  const base = (import.meta.env.VITE_API_URL ?? "http://localhost:8000/api/v1").replace(/\/api\/v1\/?$/, "");
  return `${base}${path}`;
}

export function apiError(err: unknown): string {
  if (axios.isAxiosError(err)) {
    const data = err.response?.data as
      | { error?: { code?: string; message?: string; details?: unknown } }
      | undefined;
    const error = data?.error;
    if (error?.message) {
      if (error.code === "validation_error" && Array.isArray(error.details)) {
        const first = (error.details as Array<{ msg?: string; loc?: unknown[] }>)[0];
        const field = Array.isArray(first?.loc)
          ? String((first!.loc as unknown[]).slice(-1)[0] ?? "")
          : "";
        const msg = first?.msg ? translateValidationMsg(first.msg) : null;
        if (msg) return field ? `${humanField(field)}: ${msg}` : msg;
      }
      return error.message;
    }
    const status = err.response?.status;
    if (status === 405) {
      return "Soʻrov usuli qoʻllab-quvvatlanmaydi (405). API manzili notoʻgʻri boʻlishi mumkin.";
    }
    if (status === 404) {
      return "API topilmadi (404). VITE_API_URL toʻgʻri sozlanganini tekshiring.";
    }
    if (status === 502 || status === 503) {
      return "Backend serveriga ulanib boʻlmadi. Birozdan soʻng qayta urinib koʻring.";
    }
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
