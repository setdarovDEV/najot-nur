import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { Phone, Lock, ShieldCheck, AlertCircle, ArrowLeft } from "lucide-react";
import { AuthShell } from "./AuthShell";
import { GlassInput, PrimaryButton } from "../../components/glass";
import { useLang } from "../../lib/i18n";
import { api, apiError } from "../../lib/api";

type Step = "phone" | "code" | "newPassword";

export function ForgotPasswordPage() {
  const navigate = useNavigate();
  const { t } = useLang();

  const [step, setStep] = useState<Step>("phone");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function requestCode() {
    setError(null);
    if (!/^\+?\d{9,15}$/.test(phone.trim())) {
      setError(t.auth.invalidPhone);
      return;
    }
    setLoading(true);
    try {
      await api.post("/auth/otp/request", { phone: phone.trim(), purpose: "password_reset" });
      setStep("code");
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  async function verifyCode() {
    setError(null);
    if (!code.trim()) {
      setError(t.auth.invalidCode);
      return;
    }
    setLoading(true);
    try {
      await api.post("/auth/otp/check", { phone: phone.trim(), code: code.trim() });
      setStep("newPassword");
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  async function resetPassword(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (newPassword.length < 6) {
      setError(t.auth.shortPassword);
      return;
    }
    setLoading(true);
    try {
      await api.post("/auth/password/reset", {
        phone: phone.trim(),
        code: code.trim(),
        new_password: newPassword,
      });
      navigate("/login");
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthShell subtitle={t.auth.resetPassword}>
      {step !== "phone" && (
        <button
          type="button"
          onClick={() => {
            setStep(step === "code" ? "phone" : "code");
            setError(null);
          }}
          className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
        >
          <ArrowLeft size={14} /> {t.common.back}
        </button>
      )}

      {step === "phone" && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            void requestCode();
          }}
          className="space-y-4"
        >
          {error && <ErrorBanner message={error} />}
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.auth.phone}
            </label>
            <div className="relative">
              <Phone size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
              <GlassInput
                type="tel"
                inputMode="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder={t.auth.phonePlaceholder}
                className="pl-10"
                autoFocus
              />
            </div>
          </div>
          <PrimaryButton type="submit" loading={loading} className="w-full py-3 text-base">
            {t.auth.requestCode}
          </PrimaryButton>
        </form>
      )}

      {step === "code" && (
        <form
          onSubmit={(e) => {
            e.preventDefault();
            void verifyCode();
          }}
          className="space-y-4"
        >
          {error && <ErrorBanner message={error} />}
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.auth.code}
            </label>
            <div className="relative">
              <ShieldCheck size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
              <GlassInput
                type="text"
                inputMode="numeric"
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                placeholder="000000"
                className="pl-10 text-center text-lg font-bold tracking-[0.4em]"
                autoFocus
              />
            </div>
          </div>
          <PrimaryButton type="submit" loading={loading} className="w-full py-3 text-base">
            {t.auth.verifyBtn}
          </PrimaryButton>
          <button
            type="button"
            onClick={() => void requestCode()}
            className="w-full text-center text-xs font-bold text-wine hover:underline"
          >
            {t.auth.resendCode}
          </button>
        </form>
      )}

      {step === "newPassword" && (
        <form onSubmit={resetPassword} className="space-y-4">
          {error && <ErrorBanner message={error} />}
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.auth.newPassword}
            </label>
            <div className="relative">
              <Lock size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
              <GlassInput
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                placeholder={t.auth.newPasswordPlaceholder}
                className="pl-10"
                autoFocus
              />
            </div>
          </div>
          <PrimaryButton type="submit" loading={loading} className="w-full py-3 text-base">
            {t.auth.resetBtn}
          </PrimaryButton>
        </form>
      )}
    </AuthShell>
  );
}

function ErrorBanner({ message }: { message: string }) {
  return (
    <div className="flex items-start gap-2 rounded-2xl border border-red-200 bg-red-50 px-3.5 py-3 text-xs font-semibold text-red-600 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-400">
      <AlertCircle size={15} className="mt-0.5 shrink-0" />
      {message}
    </div>
  );
}
