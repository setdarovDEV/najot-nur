import { useEffect, useRef, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import {
  AlertCircle,
  ChevronDown,
  ChevronUp,
  Eye,
  EyeOff,
  Info,
  Loader2,
  Lock,
  Mail,
  Wifi,
  WifiOff,
} from "lucide-react";
import { useAuth } from "../lib/auth";
import { apiError } from "../lib/api";
import { useLang } from "../lib/i18n";

interface DemoCreds {
  email: string;
  password: string;
  label: string;
}

const DEMO_CREDS: DemoCreds[] = [
  { email: "admin@najotnur.uz", password: "admin123", label: "Administrator" },
];

const API_URL: string =
  (import.meta.env.VITE_API_URL as string | undefined) ?? "http://localhost:8000/api/v1";
const HEALTH_URL = API_URL.replace(/\/api\/v1\/?$/, "") + "/health";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const { t } = useLang();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [demoOpen, setDemoOpen] = useState(true);
  const [troubleOpen, setTroubleOpen] = useState(false);
  const [apiStatus, setApiStatus] = useState<"checking" | "online" | "offline">("checking");
  const emailRef = useRef<HTMLInputElement>(null);

  // Probe backend /health on mount so the user can see at-a-glance whether the
  // server is reachable. Catches the most common "I can't log in" cause.
  useEffect(() => {
    let cancelled = false;
    const ac = new AbortController();
    const timeout = setTimeout(() => ac.abort(), 5000);
    fetch(HEALTH_URL, { signal: ac.signal, mode: "cors" })
      .then((r) => {
        if (cancelled) return;
        setApiStatus(r.ok ? "online" : "offline");
      })
      .catch(() => {
        if (!cancelled) setApiStatus("offline");
      })
      .finally(() => clearTimeout(timeout));
    return () => {
      cancelled = true;
      ac.abort();
    };
  }, []);

  // Auto-focus the email field on mount.
  useEffect(() => {
    emailRef.current?.focus();
  }, []);

  function fillDemo(creds: DemoCreds) {
    setEmail(creds.email);
    setPassword(creds.password);
    setError(null);
  }

  function classifyError(err: unknown): string {
    // Pulls the actual API error message when possible, otherwise maps
    // known network/CORS failures to a friendly hint.
    if (err && typeof err === "object" && "code" in err) {
      const code = (err as { code?: string }).code;
      if (code === "ERR_NETWORK" || code === "ECONNABORTED") {
        return `Backend bilan bog'lanib bo'lmadi (${HEALTH_URL}). Server ishlab turganini tekshiring.`;
      }
    }
    const raw = apiError(err);
    if (!raw) return "Nomaʼlum xatolik. Qaytadan urinib koʻring.";
    if (raw.toLowerCase().includes("email yoki parol")) {
      return "Email yoki parol notoʻgʻri. Iltimos, qaytadan urinib koʻring.";
    }
    return raw;
  }

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (loading) return;
    setError(null);

    const trimmedEmail = email.trim().toLowerCase();
    if (!trimmedEmail || !password) {
      setError("Email va parolni toʻldiring.");
      return;
    }
    if (password.length < 6) {
      setError("Parol kamida 6 ta belgidan iborat boʻlishi kerak.");
      return;
    }

    setLoading(true);
    try {
      await login(trimmedEmail, password);
      navigate("/");
    } catch (err) {
      setError(classifyError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen place-items-center bg-gradient-to-br from-wine via-wine-dark to-wine-deep p-4 sm:p-6">
      <div className="w-full max-w-md">
        {/* Brand */}
        <div className="mb-6 flex items-center gap-3 text-white">
          <div className="grid h-12 w-12 place-items-center rounded-2xl bg-white/15 text-lg font-black shadow-inner">
            NN
          </div>
          <div>
            <div className="text-xl font-extrabold leading-none">{t.login.title}</div>
            <div className="mt-1 text-sm text-white/70">{t.login.subtitle}</div>
          </div>
        </div>

        <div className="rounded-3xl bg-card p-6 shadow-2xl sm:p-8">
          {/* Backend status pill */}
          <div className="mb-4">
            <ApiStatusPill status={apiStatus} url={HEALTH_URL} />
          </div>

          <form onSubmit={onSubmit} className="space-y-4" autoComplete="off" noValidate>
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-ink">
                {t.login.email}
              </label>
              <div className="relative">
                <Mail
                  size={16}
                  className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
                />
                <input
                  ref={emailRef}
                  type="email"
                  name="user_login_email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="off"
                  data-lpignore="true"
                  data-1p-ignore="true"
                  data-form-type="other"
                  spellCheck={false}
                  disabled={loading}
                  className="w-full rounded-xl border border-line bg-card py-3 pl-10 pr-4 text-ink outline-none transition focus:border-wine focus:ring-2 focus:ring-wine/20 disabled:opacity-60 dark:bg-[#251d20]"
                  placeholder="name@example.com"
                />
              </div>
            </div>

            <div>
              <label className="mb-1.5 block text-sm font-semibold text-ink">
                {t.login.password}
              </label>
              <div className="relative">
                <Lock
                  size={16}
                  className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
                />
                <input
                  type={showPassword ? "text" : "password"}
                  name="user_login_password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  disabled={loading}
                  className="w-full rounded-xl border border-line bg-card py-3 pl-10 pr-12 text-ink outline-none transition focus:border-wine focus:ring-2 focus:ring-wine/20 disabled:opacity-60 dark:bg-[#251d20]"
                  placeholder="••••••••"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((s) => !s)}
                  disabled={loading}
                  className="absolute right-2 top-1/2 grid h-8 w-8 -translate-y-1/2 place-items-center rounded-lg text-muted transition hover:bg-surface hover:text-ink disabled:opacity-50"
                  title={showPassword ? t.login.hidePassword : t.login.showPassword}
                  aria-label={showPassword ? t.login.hidePassword : t.login.showPassword}
                >
                  {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                </button>
              </div>
            </div>

            {error && (
              <div className="flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 px-3 py-2.5 text-sm text-red-700">
                <AlertCircle size={15} className="mt-0.5 shrink-0" />
                <span className="flex-1 break-words">{error}</span>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="flex w-full items-center justify-center gap-2 rounded-xl bg-wine py-3 font-bold text-white transition hover:bg-wine-dark disabled:cursor-not-allowed disabled:opacity-60"
            >
              {loading && <Loader2 size={16} className="animate-spin" />}
              {loading ? t.login.loggingIn : t.login.loginBtn}
            </button>
          </form>

          {/* Demo credentials */}
          <div className="mt-5 overflow-hidden rounded-2xl border border-line">
            <button
              type="button"
              onClick={() => setDemoOpen((v) => !v)}
              className="flex w-full items-center justify-between bg-wine/5 px-4 py-2.5 text-left text-sm font-bold text-ink transition hover:bg-wine/10"
            >
              <span className="flex items-center gap-2">
                <Info size={14} className="text-wine" />
                {t.login.demoTitle}
              </span>
              {demoOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            </button>
            {demoOpen && (
              <div className="space-y-2 p-3">
                <p className="px-1 text-xs text-muted">{t.login.demoHint}</p>
                {DEMO_CREDS.map((c) => (
                  <div
                    key={c.email}
                    className="flex items-center justify-between gap-2 rounded-xl border border-line bg-card px-3 py-2"
                  >
                    <div className="min-w-0 flex-1">
                      <div className="text-xs font-bold text-ink">{c.label}</div>
                      <div className="truncate font-mono text-[11px] text-muted">
                        {c.email}
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => fillDemo(c)}
                      disabled={loading}
                      className="shrink-0 rounded-lg bg-wine px-3 py-1.5 text-xs font-bold text-white transition hover:bg-wine-dark disabled:opacity-50"
                    >
                      {t.login.fill}
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Troubleshooting hint */}
          <div className="mt-4 overflow-hidden rounded-2xl border border-line">
            <button
              type="button"
              onClick={() => setTroubleOpen((v) => !v)}
              className="flex w-full items-center justify-between px-4 py-2.5 text-left text-sm font-semibold text-muted transition hover:bg-surface"
            >
              <span>{t.login.troubleshooting}</span>
              {troubleOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
            </button>
            {troubleOpen && (
              <div className="space-y-1.5 border-t border-line bg-surface px-4 py-3 text-xs text-muted">
                <p className="font-semibold text-ink">{t.login.troubleshootingHint}</p>
                {t.login.troubleshootingItems.map((line) => (
                  <p key={line} className="leading-relaxed">
                    {line}
                  </p>
                ))}
                <p className="mt-2 border-t border-line pt-2 font-mono text-[10px]">
                  API: {API_URL}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function ApiStatusPill({ status, url }: { status: "checking" | "online" | "offline"; url: string }) {
  const { t } = useLang();
  if (status === "checking") {
    return (
      <div className="flex items-center gap-2 rounded-xl bg-surface px-3 py-2 text-xs text-muted">
        <Loader2 size={13} className="animate-spin" />
        {t.login.apiChecking}
      </div>
    );
  }
  if (status === "online") {
    return (
      <div className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-3 py-2 text-xs text-green-700">
        <Wifi size={13} />
        <span className="font-semibold">{t.login.apiOnline}</span>
        <span className="ml-auto font-mono text-[10px] text-green-700/70">{url}</span>
      </div>
    );
  }
  return (
    <div className="flex items-start gap-2 rounded-xl border border-amber-200 bg-amber-50 px-3 py-2 text-xs text-amber-800">
      <WifiOff size={13} className="mt-0.5 shrink-0" />
      <div className="flex-1">
        <p className="font-semibold">{t.login.apiOffline}</p>
        <p className="mt-0.5 break-all font-mono text-[10px] text-amber-700/80">{url}</p>
      </div>
    </div>
  );
}
