import { useEffect, useRef, useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import {
  AlertCircle,
  Eye,
  EyeOff,
  Loader2,
  Lock,
  Mail,
} from "lucide-react";
import { useAuth } from "../lib/auth";
import { apiError } from "../lib/api";
import { useLang } from "../lib/i18n";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const { t } = useLang();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const emailRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    emailRef.current?.focus();
  }, []);

  function classifyError(err: unknown): string {
    if (err && typeof err === "object" && "code" in err) {
      const code = (err as { code?: string }).code;
      if (code === "ERR_NETWORK" || code === "ECONNABORTED") {
        return "Server bilan bog'lanib bo'lmadi. Backend ishlab turganini tekshiring.";
      }
    }
    if (err && typeof err === "object" && "response" in err) {
      const status = (err as { response?: { status?: number } }).response?.status;
      if (status === 405) {
        return "Soʻrov usuli qoʻllab-quvvatlanmaydi (405). API manzili notoʻgʻri boʻlishi mumkin.";
      }
      if (status === 404) {
        return "API topilmadi (404). VITE_API_URL toʻgʻri sozlanganini tekshiring.";
      }
      if (status === 502 || status === 503) {
        return "Backend serveriga ulanib boʻlmadi. Birozdan soʻng qayta urinib koʻring.";
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
    <div className="grid min-h-screen place-items-center bg-gradient-to-br from-skyblue via-skyblue/80 to-wine-deep p-4 sm:p-6">
      <div className="w-full max-w-sm">
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
                  name="curator_login_email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="off"
                  data-lpignore="true"
                  data-1p-ignore="true"
                  data-form-type="other"
                  spellCheck={false}
                  disabled={loading}
                  className="w-full rounded-xl border border-line bg-card py-3 pl-10 pr-4 text-ink outline-none transition focus:border-wine focus:ring-2 focus:ring-wine/20 disabled:opacity-60 dark:bg-[#1a2a37]"
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
                  name="curator_login_password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  disabled={loading}
                  className="w-full rounded-xl border border-line bg-card py-3 pl-10 pr-12 text-ink outline-none transition focus:border-wine focus:ring-2 focus:ring-wine/20 disabled:opacity-60 dark:bg-[#1a2a37]"
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
        </div>
      </div>
    </div>
  );
}
