import { X } from "lucide-react";
import { useEffect, type ReactNode } from "react";

interface ModalProps {
  open: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  size?: "sm" | "md" | "lg" | "xl";
  children: ReactNode;
  footer?: ReactNode;
}

const SIZE_CLASS: Record<NonNullable<ModalProps["size"]>, string> = {
  sm: "max-w-md",
  md: "max-w-xl",
  lg: "max-w-2xl",
  xl: "max-w-4xl",
};

export function Modal({
  open,
  onClose,
  title,
  subtitle,
  size = "md",
  children,
  footer,
}: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    document.addEventListener("keydown", onKey);
    document.body.style.overflow = "hidden";
    return () => {
      document.removeEventListener("keydown", onKey);
      document.body.style.overflow = "";
    };
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 pt-10 backdrop-blur-[18px] sm:pt-16"
      style={{ background: "rgba(63,9,24,0.30)" }}
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        className={`animate-sheet-in w-full ${SIZE_CLASS[size]} overflow-hidden rounded-3xl border border-line bg-card text-ink shadow-2xl`}
      >
        <div className="flex items-start justify-between gap-3 border-b border-line px-6 py-4">
          <div className="min-w-0">
            <h2 className="truncate text-lg font-extrabold text-ink">{title}</h2>
            {subtitle && (
              <p className="mt-0.5 text-xs text-muted">{subtitle}</p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="press grid h-9 w-9 shrink-0 place-items-center rounded-full border border-line text-muted transition hover:border-wine/30 hover:text-wine"
            aria-label="Yopish"
          >
            <X size={17} />
          </button>
        </div>

        <div className="max-h-[calc(100vh-12rem)] overflow-y-auto px-6 py-5">
          {children}
        </div>

        {footer && (
          <div className="flex items-center justify-end gap-3 border-t border-line bg-surface/60 px-6 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

export function ModalFooter({
  onClose,
  onSubmit,
  saving,
  submitLabel,
  submitDisabled,
  variant = "wine",
}: {
  onClose: () => void;
  onSubmit?: () => void;
  saving?: boolean;
  submitLabel: string;
  submitDisabled?: boolean;
  variant?: "wine" | "danger";
}) {
  const submitColor =
    variant === "danger"
      ? "bg-danger hover:brightness-110"
      : "btn-primary";
  return (
    <>
      <button
        type="button"
        onClick={onClose}
        className="press rounded-full border border-line bg-card px-5 py-2.5 text-sm font-semibold text-ink transition hover:bg-surface"
      >
        Bekor qilish
      </button>
      {onSubmit && (
        <button
          type="button"
          onClick={onSubmit}
          disabled={saving || submitDisabled}
          className={`press flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-bold text-white transition disabled:opacity-60 ${submitColor}`}
        >
          {saving ? "Saqlanmoqda…" : submitLabel}
        </button>
      )}
    </>
  );
}
