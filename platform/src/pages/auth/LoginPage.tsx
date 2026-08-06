import { useState, type FormEvent } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Lock, LogIn, AlertCircle } from "lucide-react";
import { AuthShell } from "./AuthShell";
import { GlassInput, PrimaryButton } from "../../components/glass";
import { PhoneInput, isCompleteUzPhone } from "../../components/PhoneInput";
import { useAuth } from "../../lib/auth";
import { useLang } from "../../lib/i18n";
import { apiError } from "../../lib/api";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const { t } = useLang();

  const [phone, setPhone] = useState("+998");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const from = (location.state as { from?: string } | null)?.from ?? "/";

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!isCompleteUzPhone(phone)) {
      setError(t.auth.invalidPhone);
      return;
    }
    if (password.length < 6) {
      setError(t.auth.shortPassword);
      return;
    }
    setLoading(true);
    try {
      await login(phone.trim(), password);
      navigate(from, { replace: true });
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthShell>
      <form onSubmit={onSubmit} className="space-y-4">
        {error && (
          <div className="flex items-start gap-2 rounded-2xl border border-red-200 bg-red-50 px-3.5 py-3 text-xs font-semibold text-red-600 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-400">
            <AlertCircle size={15} className="mt-0.5 shrink-0" />
            {error}
          </div>
        )}

        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted">
            {t.auth.phone}
          </label>
          <PhoneInput value={phone} onChange={setPhone} autoFocus />
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted">
            {t.auth.password}
          </label>
          <div className="relative">
            <Lock size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
            <GlassInput
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder={t.auth.passwordPlaceholder}
              className="pl-10"
            />
          </div>
        </div>

        <div className="flex justify-end">
          <Link
            to="/forgot-password"
            className="text-xs font-bold text-wine hover:underline"
          >
            {t.auth.forgotPassword}
          </Link>
        </div>

        <PrimaryButton
          type="submit"
          loading={loading}
          className="w-full py-3 text-base"
        >
          {loading ? t.auth.loggingIn : <LogIn size={17} />}
          {loading ? null : t.auth.loginBtn}
        </PrimaryButton>
      </form>

      <div className="mt-6 flex items-center gap-3 text-xs text-muted">
        <span className="h-px flex-1 bg-line" />
        {t.auth.noAccount}
        <span className="h-px flex-1 bg-line" />
      </div>

      <Link
        to="/register"
        className="press mt-4 flex w-full items-center justify-center gap-2 rounded-full border border-wine/30 bg-wine-50 px-5 py-3 text-sm font-bold text-wine transition hover:bg-wine-100 dark:bg-wine/15 dark:hover:bg-wine/25"
      >
        {t.auth.registerBtn}
      </Link>
    </AuthShell>
  );
}
