import { useEffect, type ReactNode } from "react";
import { X } from "lucide-react";

interface ModalProps {
  open: boolean;
  onClose: () => void;
  children: ReactNode;
  size?: "sm" | "md" | "lg" | "xl";
}

const SIZE_CLASSES: Record<NonNullable<ModalProps["size"]>, string> = {
  sm: "max-w-sm",
  md: "max-w-md",
  lg: "max-w-xl",
  xl: "max-w-2xl",
};

export function Modal({ open, onClose, children, size = "lg" }: ModalProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.preventDefault();
        onClose();
      }
    };
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 pt-10 backdrop-blur-[18px]"
      style={{ background: "rgba(63,9,24,0.30)" }}
      onMouseDown={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div
        role="dialog"
        aria-modal="true"
        className={`animate-sheet-in w-full ${SIZE_CLASSES[size]} rounded-3xl border border-line bg-card shadow-2xl`}
        onMouseDown={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </div>
  );
}

export function ModalHeader({
  title,
  onClose,
}: {
  title: ReactNode;
  onClose?: () => void;
}) {
  return (
    <div className="flex items-center justify-between border-b border-line px-6 py-4">
      <h2 className="text-lg font-extrabold text-ink">{title}</h2>
      {onClose && (
        <button
          onClick={onClose}
          className="press rounded-full p-1 text-muted transition hover:bg-surface hover:text-wine"
          aria-label="Yopish"
        >
          <X size={20} />
        </button>
      )}
    </div>
  );
}

export function ModalBody({ children }: { children: ReactNode }) {
  return <div className="p-6">{children}</div>;
}

export function ModalFooter({
  children,
}: {
  children: ReactNode;
}) {
  return (
    <div className="flex items-center justify-end gap-3 border-t border-line px-6 py-4">
      {children}
    </div>
  );
}

export function ModalCancelButton({
  onClick,
  children,
}: {
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="press rounded-full border border-line px-5 py-2.5 text-sm font-semibold text-ink transition hover:bg-surface"
    >
      {children}
    </button>
  );
}

export function ModalSubmitButton({
  onClick,
  disabled,
  loading,
  children,
}: {
  onClick?: () => void;
  disabled?: boolean;
  loading?: boolean;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled || loading}
      className="btn-primary press flex items-center gap-2 rounded-full px-5 py-2.5 text-sm font-bold disabled:opacity-60"
    >
      {loading && (
        <span className="h-3.5 w-3.5 animate-spin rounded-full border-2 border-white border-t-transparent" />
      )}
      {children}
    </button>
  );
}
