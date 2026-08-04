import { useState } from "react";
import { CheckCircle2 } from "lucide-react";
import { Modal } from "./Modal";
import { GlassSelect, PrimaryButton } from "./glass";
import { useLang } from "../lib/i18n";
import { api, apiError } from "../lib/api";
import { useToast } from "../lib/toast";
import type { OrderPaymentMethod, OrderPurpose } from "../lib/types";

interface OrderModalProps {
  open: boolean;
  onClose: () => void;
  purpose: OrderPurpose;
  amount: number | string;
  courseId?: string | null;
  audiobookId?: string | null;
  onSuccess?: () => void;
}

const METHODS: { value: OrderPaymentMethod; labelKey: "methodUzum" | "methodNasiya" | "methodCash" }[] = [
  { value: "uzum", labelKey: "methodUzum" },
  { value: "uzum_nasiya", labelKey: "methodNasiya" },
  { value: "cash", labelKey: "methodCash" },
];

export function OrderModal({
  open,
  onClose,
  purpose,
  amount,
  courseId,
  audiobookId,
  onSuccess,
}: OrderModalProps) {
  const { t } = useLang();
  const toast = useToast();
  const [method, setMethod] = useState<OrderPaymentMethod>("uzum");
  const [submitting, setSubmitting] = useState(false);

  async function submit() {
    setSubmitting(true);
    try {
      await api.post("/orders", {
        purpose,
        course_id: purpose === "course" ? courseId : null,
        audiobook_id: purpose === "audiobook" ? audiobookId : null,
        amount: Number(amount),
        payment_method: method,
      });
      toast.success(t.orders.requestSent);
      onClose();
      onSuccess?.();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t.orders.requestTitle}
      subtitle={t.orders.requestDesc}
    >
      <div className="space-y-4">
        <div className="rounded-2xl border border-wine/20 bg-wine-50 px-4 py-3 dark:bg-wine/15">
          <div className="flex items-center justify-between text-sm">
            <span className="font-bold text-wine">
              {purpose === "course" ? t.orders.course : t.orders.audiobook}
            </span>
            <span className="font-black text-ink">
              {Number(amount).toLocaleString("uz-UZ")} so'm
            </span>
          </div>
        </div>

        <div>
          <label className="mb-1.5 block text-xs font-bold text-muted">
            {t.orders.selectMethod}
          </label>
          <GlassSelect value={method} onChange={(e) => setMethod(e.target.value as OrderPaymentMethod)}>
            {METHODS.map((m) => (
              <option key={m.value} value={m.value}>
                {t.orders[m.labelKey]}
              </option>
            ))}
          </GlassSelect>
        </div>

        <div className="flex items-start gap-2 rounded-2xl border border-line bg-surface px-3.5 py-3 text-xs leading-relaxed text-muted">
          <CheckCircle2 size={15} className="mt-0.5 shrink-0 text-success" />
          {t.orders.requestDesc}
        </div>

        <PrimaryButton onClick={submit} loading={submitting} className="w-full py-3">
          {submitting ? t.orders.sending : t.orders.sendRequest}
        </PrimaryButton>
      </div>
    </Modal>
  );
}
