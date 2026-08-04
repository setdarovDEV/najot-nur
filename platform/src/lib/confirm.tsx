import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { ConfirmDialog } from "../components/ConfirmDialog";

export type ConfirmVariant = "danger" | "primary" | "warning";

export interface ConfirmOptions {
  title: string;
  description?: ReactNode;
  confirmText?: string;
  cancelText?: string;
  variant?: ConfirmVariant;
  icon?: ReactNode;
}

interface ConfirmState {
  open: boolean;
  title: string;
  description?: ReactNode;
  confirmText?: string;
  cancelText?: string;
  variant?: ConfirmVariant;
  icon?: ReactNode;
}

interface ConfirmContextValue {
  confirm: (opts: ConfirmOptions) => Promise<boolean>;
}

const Ctx = createContext<ConfirmContextValue | null>(null);

export function ConfirmProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<ConfirmState>({
    open: false,
    title: "",
  });
  const resolveRef = useRef<((v: boolean) => void) | null>(null);

  const close = useCallback((value: boolean) => {
    setState((prev) => ({ ...prev, open: false }));
    const r = resolveRef.current;
    resolveRef.current = null;
    if (r) r(value);
  }, []);

  const confirm = useCallback(
    (opts: ConfirmOptions) =>
      new Promise<boolean>((resolve) => {
        resolveRef.current = resolve;
        setState({
          open: true,
          title: opts.title,
          description: opts.description,
          confirmText: opts.confirmText,
          cancelText: opts.cancelText,
          variant: opts.variant,
          icon: opts.icon,
        });
      }),
    [],
  );

  const value = useMemo<ConfirmContextValue>(() => ({ confirm }), [confirm]);

  return (
    <Ctx.Provider value={value}>
      {children}
      <ConfirmDialog
        open={state.open}
        title={state.title}
        description={state.description}
        confirmText={state.confirmText}
        cancelText={state.cancelText}
        variant={state.variant}
        icon={state.icon}
        onConfirm={() => close(true)}
        onClose={() => close(false)}
      />
    </Ctx.Provider>
  );
}

export function useConfirm(): (opts: ConfirmOptions) => Promise<boolean> {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error("useConfirm must be used within ConfirmProvider");
  return ctx.confirm;
}
