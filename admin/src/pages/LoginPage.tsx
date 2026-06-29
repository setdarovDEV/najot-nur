import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../lib/auth";
import { apiError } from "../lib/api";
import { useLang } from "../lib/i18n";
import { detectSite, emailErrorForSite } from "../lib/subdomain";

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const { t } = useLang();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);

    const site = detectSite();
    const emailErr = emailErrorForSite(email, site);
    if (emailErr) {
      setError(emailErr);
      return;
    }

    setLoading(true);
    try {
      await login(email, password);
      navigate("/");
    } catch (err) {
      setError(apiError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="grid min-h-screen place-items-center bg-gradient-to-br from-wine to-wine-deep p-6">
      <div className="w-full max-w-md rounded-3xl bg-card p-8 shadow-2xl">
        <div className="mb-6 flex items-center gap-3">
          <div className="grid h-12 w-12 place-items-center rounded-2xl bg-wine text-lg font-black text-white">
            NN
          </div>
          <div>
            <div className="text-xl font-extrabold text-ink">{t.login.title}</div>
            <div className="text-sm text-muted">{t.login.subtitle}</div>
          </div>
        </div>

        <form onSubmit={onSubmit} className="space-y-4" autoComplete="off">
          <div>
            <label className="mb-1 block text-sm font-semibold text-ink">
              {t.login.email}
            </label>
            <input
              type="email"
              name="user_login_email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              autoComplete="off"
              data-lpignore="true"
              data-1p-ignore="true"
              data-form-type="other"
              spellCheck={false}
              className="w-full rounded-xl border border-line bg-card px-4 py-3 text-ink outline-none focus:border-wine dark:bg-[#251d20]"
              placeholder="name@example.com"
              required
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-semibold text-ink">
              {t.login.password}
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full rounded-xl border border-line bg-card px-4 py-3 text-ink outline-none focus:border-wine dark:bg-[#251d20]"
              placeholder="••••••••"
              required
            />
          </div>

          {error && <p className="text-sm text-red-500">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-wine py-3 font-bold text-white transition hover:bg-wine-dark disabled:opacity-60"
          >
            {loading ? t.login.loggingIn : t.login.loginBtn}
          </button>
        </form>

      </div>
    </div>
  );
}
