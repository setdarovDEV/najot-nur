import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { CheckCircle2, AlertCircle, Info, X } from "lucide-react";

export type ToastKind = "success" | "error" | "info";

interface ToastItem {
  id: number;
  kind: ToastKind;
  message: string;
}

interface ToastContextValue {
  show: (message: string, kind?: ToastKind) => void;
  success: (message: string) => void;
  error: (message: string) => void;
  info: (message: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<ToastItem[]>([]);
  const seq = useRef(0);

  const remove = useCallback((id: number) => {
    setItems((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const show = useCallback(
    (message: string, kind: ToastKind = "success") => {
      const id = ++seq.current;
      setItems((prev) => [...prev, { id, kind, message }]);
      window.setTimeout(() => remove(id), 3200);
    },
    [remove]
  );

  const value = useMemo<ToastContextValue>(
    () => ({
      show,
      success: (m) => show(m, "success"),
      error: (m) => show(m, "error"),
      info: (m) => show(m, "info"),
    }),
    [show]
  );

  return (
    <ToastContext.Provider value={value}>
      {children}
      <div className="pointer-events-none fixed top-5 right-5 z-50 flex w-full max-w-sm flex-col gap-2">
        {items.map((t) => (
          <ToastView key={t.id} item={t} onClose={() => remove(t.id)} />
        ))}
      </div>
    </ToastContext.Provider>
  );
}

function ToastView({
  item,
  onClose,
}: {
  item: ToastItem;
  onClose: () => void;
}) {
  const styles: Record<ToastKind, { ring: string; bg: string; fg: string; Icon: typeof CheckCircle2 }> = {
    success: { ring: "border-green-200", bg: "bg-green-50", fg: "text-green-700", Icon: CheckCircle2 },
    error: { ring: "border-red-200", bg: "bg-red-50", fg: "text-red-700", Icon: AlertCircle },
    info: { ring: "border-sky-200", bg: "bg-sky-50", fg: "text-sky-700", Icon: Info },
  };
  const s = styles[item.kind];
  const Icon = s.Icon;
  return (
    <div
      role="status"
      className={`pointer-events-auto flex animate-[toast-in_220ms_ease-out] items-start gap-3 rounded-xl border ${s.ring} ${s.bg} px-4 py-3 shadow-lg`}
    >
      <Icon size={18} className={`mt-0.5 shrink-0 ${s.fg}`} />
      <p className={`flex-1 text-sm font-semibold ${s.fg}`}>{item.message}</p>
      <button
        onClick={onClose}
        className={`shrink-0 rounded-md p-0.5 ${s.fg} opacity-60 hover:opacity-100`}
        aria-label="Yopish"
      >
        <X size={14} />
      </button>
    </div>
  );
}

export function useToast(): ToastContextValue {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error("useToast must be used within ToastProvider");
  return ctx;
}
