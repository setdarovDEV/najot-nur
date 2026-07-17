import { useEffect, useState, type ReactNode } from "react";
import {
  AlertTriangle,
  CheckCircle2,
  Info,
  Loader2,
  X,
} from "lucide-react";
import type { ConfirmVariant } from "../lib/confirm";

interface Props {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  description?: ReactNode;
  confirmText?: string;
  cancelText?: string;
  variant?: ConfirmVariant;
  icon?: ReactNode;
}

const VARIANT_STYLES: Record<
  ConfirmVariant,
  { ring: string; bg: string; fg: string; btn: string; Icon: typeof AlertTriangle }
> = {
  danger: {
    ring: "border-danger/20",
    bg: "bg-danger/10",
    fg: "text-danger",
    btn: "bg-danger hover:brightness-110",
    Icon: AlertTriangle,
  },
  primary: {
    ring: "border-wine/20",
    bg: "bg-wine/10 dark:bg-wine/15",
    fg: "text-wine dark:text-wine-300",
    btn: "btn-primary",
    Icon: CheckCircle2,
  },
  warning: {
    ring: "border-warning/25",
    bg: "bg-warning/12",
    fg: "text-warning",
    btn: "bg-warning hover:brightness-105",
    Icon: Info,
  },
};

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  confirmText = "Tasdiqlash",
  cancelText = "Bekor qilish",
  variant = "primary",
  icon,
}: Props) {
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!open) setBusy(false);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (busy) return;
      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      } else if (e.key === "Enter") {
        e.preventDefault();
        handleConfirm();
      }
    };
    function handleConfirm() {
      if (busy) return;
      setBusy(true);
      onConfirm();
    }
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, busy, onClose, onConfirm]);

  if (!open) return null;

  const s = VARIANT_STYLES[variant];
  const Icon = icon ?? <s.Icon size={22} />;

  const handleConfirm = () => {
    if (busy) return;
    setBusy(true);
    onConfirm();
  };

  return (
    <div
      className="fixed inset-0 z-[100] flex items-center justify-center p-4 backdrop-blur-[18px] animate-[toast-in_180ms_ease-out]"
      style={{ background: "rgba(63,9,24,0.30)" }}
      onMouseDown={(e) => {
        if (e.target === e.currentTarget && !busy) onClose();
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        className={`animate-sheet-in w-full max-w-md overflow-hidden rounded-3xl border ${s.ring} bg-card shadow-2xl`}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <div className="flex items-start gap-4 p-5">
          <div
            className={`grid h-12 w-12 shrink-0 place-items-center rounded-full ${s.bg} ${s.fg}`}
          >
            {Icon}
          </div>
          <div className="min-w-0 flex-1 pt-0.5">
            <h3 className="text-base font-extrabold text-ink">{title}</h3>
            {description && (
              <div className="mt-1.5 text-sm leading-relaxed text-muted">
                {description}
              </div>
            )}
          </div>
          <button
            onClick={onClose}
            disabled={busy}
            className="press shrink-0 rounded-full p-1 text-muted hover:bg-surface disabled:opacity-50"
            aria-label="Yopish"
          >
            <X size={16} />
          </button>
        </div>
        <div className="flex items-center justify-end gap-2 border-t border-line bg-surface px-5 py-3">
          <button
            onClick={onClose}
            disabled={busy}
            className="press rounded-full border border-line px-4 py-2 text-sm font-semibold text-ink hover:bg-card disabled:opacity-50"
          >
            {cancelText}
          </button>
          <button
            onClick={handleConfirm}
            disabled={busy}
            className={`press flex items-center gap-2 rounded-full px-4 py-2 text-sm font-bold text-white ${s.btn} disabled:opacity-50`}
          >
            {busy && <Loader2 size={14} className="animate-spin" />}
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}
