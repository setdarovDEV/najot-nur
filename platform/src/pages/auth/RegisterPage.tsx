import { useState, type FormEvent } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Lock, User, ShieldCheck, AlertCircle, ArrowLeft } from "lucide-react";
import { AuthShell } from "./AuthShell";
import { GlassInput, PrimaryButton } from "../../components/glass";
import { PhoneInput, isCompleteUzPhone } from "../../components/PhoneInput";
import { useAuth } from "../../lib/auth";
import { useLang } from "../../lib/i18n";
import { api, apiError } from "../../lib/api";

type Step = "phone" | "code" | "details";

export function RegisterPage() {
  const { saveTokens } = useAuth();
  const navigate = useNavigate();
  const { t } = useLang();

  const [step, setStep] = useState<Step>("phone");
  const [phone, setPhone] = useState("+998");
  const [code, setCode] = useState("");
  const [fullName, setFullName] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function requestCode() {
    setError(null);
    if (!isCompleteUzPhone(phone)) {
      setError(t.auth.invalidPhone);
      return;
    }
    setLoading(true);
    try {
      await api.post("/auth/otp/request", { phone: phone.trim(), purpose: "registration" });
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
      setStep("details");
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  async function submitDetails(e: FormEvent) {
    e.preventDefault();
    setError(null);
    if (!fullName.trim()) {
      setError(t.auth.invalidName);
      return;
    }
    if (password.length < 6) {
      setError(t.auth.shortPassword);
      return;
    }
    setLoading(true);
    try {
      const res = await api.post("/auth/otp/verify", {
        phone: phone.trim(),
        code: code.trim(),
        full_name: fullName.trim(),
        password,
        offer_accepted: true,
      });
      saveTokens(res.data.access_token, res.data.refresh_token);
      navigate("/", { replace: true });
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <AuthShell subtitle={t.auth.subtitle}>
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
            <PhoneInput value={phone} onChange={setPhone} autoFocus />
          </div>
          <PrimaryButton type="submit" loading={loading} className="w-full py-3 text-base">
            {t.auth.requestCode}
          </PrimaryButton>
          <p className="text-center text-[11px] leading-relaxed text-muted">
            {t.auth.codeSentHint}
          </p>
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
            <p className="mt-2 text-xs text-muted">{t.auth.codeSent(phone)}</p>
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

      {step === "details" && (
        <form onSubmit={submitDetails} className="space-y-4">
          {error && <ErrorBanner message={error} />}
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.auth.fullName}
            </label>
            <div className="relative">
              <User size={16} className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-muted" />
              <GlassInput
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder={t.auth.fullNamePlaceholder}
                className="pl-10"
                autoFocus
              />
            </div>
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
          <PrimaryButton type="submit" loading={loading} className="w-full py-3 text-base">
            {t.auth.createAccount}
          </PrimaryButton>
        </form>
      )}

      <div className="mt-6 flex items-center justify-center gap-1.5 text-xs text-muted">
        {t.auth.haveAccount}
        <Link to="/login" className="font-bold text-wine hover:underline">
          {t.auth.loginBtn}
        </Link>
      </div>
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
