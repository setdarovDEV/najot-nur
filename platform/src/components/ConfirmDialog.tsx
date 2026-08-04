import { useEffect, type ReactNode } from "react";
import { X } from "lucide-react";
import type { ConfirmVariant } from "../lib/confirm";

interface ConfirmDialogProps {
  open: boolean;
  title: string;
  description?: ReactNode;
  confirmText?: string;
  cancelText?: string;
  variant?: ConfirmVariant;
  icon?: ReactNode;
  onConfirm: () => void;
  onClose: () => void;
}

const VARIANT_STYLES: Record<ConfirmVariant, { btn: string; iconWrap: string }> = {
  danger: {
    btn: "bg-danger hover:brightness-110",
    iconWrap: "bg-red-100 text-red-600 dark:bg-red-900/40 dark:text-red-400",
  },
  primary: {
    btn: "btn-primary",
    iconWrap: "bg-wine-100 text-wine dark:bg-wine/25 dark:text-wine-300",
  },
  warning: {
    btn: "bg-warning hover:brightness-105",
    iconWrap: "bg-amber-100 text-amber-600 dark:bg-amber-900/40 dark:text-amber-400",
  },
};

export function ConfirmDialog({
  open,
  title,
  description,
  confirmText = "Tasdiqlash",
  cancelText = "Bekor qilish",
  variant = "primary",
  icon,
  onConfirm,
  onClose,
}: ConfirmDialogProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;
  const s = VARIANT_STYLES[variant];

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 backdrop-blur-[18px]"
      style={{ background: "rgba(63,9,24,0.30)" }}
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="animate-sheet-in w-full max-w-md overflow-hidden rounded-3xl border border-line bg-card text-ink shadow-2xl">
        <div className="flex items-start justify-between gap-3 border-b border-line px-6 py-4">
          <div className="flex items-center gap-3">
            {icon ?? (
              <div className={`grid h-10 w-10 shrink-0 place-items-center rounded-2xl ${s.iconWrap}`}>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
                  <line x1="12" y1="9" x2="12" y2="13" />
                  <line x1="12" y1="17" x2="12.01" y2="17" />
                </svg>
              </div>
            )}
            <h2 className="text-lg font-extrabold text-ink">{title}</h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="press grid h-8 w-8 shrink-0 place-items-center rounded-full border border-line text-muted transition hover:border-wine/30 hover:text-wine"
            aria-label="Yopish"
          >
            <X size={16} />
          </button>
        </div>

        {description && (
          <div className="px-6 py-5 text-sm leading-relaxed text-muted">{description}</div>
        )}

        <div className="flex items-center justify-end gap-3 border-t border-line bg-surface/60 px-6 py-4">
          <button
            type="button"
            onClick={onClose}
            className="press rounded-full border border-line bg-card px-5 py-2.5 text-sm font-semibold text-ink transition hover:bg-surface"
          >
            {cancelText}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            className={`press flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-bold text-white transition ${s.btn}`}
          >
            {confirmText}
          </button>
        </div>
      </div>
    </div>
  );
}
