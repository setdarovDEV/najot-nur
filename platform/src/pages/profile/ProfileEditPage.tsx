import { useState, type FormEvent } from "react";
import { useNavigate } from "react-router-dom";
import { ArrowLeft, Save } from "lucide-react";
import { api, apiError } from "../../lib/api";
import { useAuth } from "../../lib/auth";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, GlassInput, PrimaryButton, SecondaryButton } from "../../components/glass";

export function ProfileEditPage() {
  const navigate = useNavigate();
  const { user, refreshUser } = useAuth();
  const { t } = useLang();
  const toast = useToast();

  const [fullName, setFullName] = useState(user?.full_name ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [city, setCity] = useState(user?.city ?? "");
  const [saving, setSaving] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    try {
      const payload: Record<string, string> = { full_name: fullName.trim() };
      if (email.trim()) payload.email = email.trim();
      if (city.trim()) payload.city = city.trim();
      await api.patch("/users/me", payload);
      await refreshUser();
      toast.success(t.common.save);
      navigate("/profile");
    } catch (err) {
      toast.error(apiError(err));
      setSaving(false);
    }
  }

  return (
    <div className="mx-auto max-w-xl">
      <button
        type="button"
        onClick={() => navigate("/profile")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      <GlassCard className="p-6">
        <h1 className="text-xl font-black text-ink">{t.profile.edit}</h1>
        <form onSubmit={submit} className="mt-5 space-y-4">
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">
              {t.profile.fullName}
            </label>
            <GlassInput value={fullName} onChange={(e) => setFullName(e.target.value)} />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">{t.profile.email}</label>
            <GlassInput type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
          </div>
          <div>
            <label className="mb-1.5 block text-xs font-bold text-muted">{t.profile.city}</label>
            <GlassInput value={city} onChange={(e) => setCity(e.target.value)} />
          </div>
          <div className="flex gap-3 pt-2">
            <SecondaryButton type="button" onClick={() => navigate("/profile")}>
              {t.common.cancel}
            </SecondaryButton>
            <PrimaryButton type="submit" loading={saving}>
              <Save size={15} /> {saving ? t.common.saving : t.common.save}
            </PrimaryButton>
          </div>
        </form>
      </GlassCard>
    </div>
  );
}
