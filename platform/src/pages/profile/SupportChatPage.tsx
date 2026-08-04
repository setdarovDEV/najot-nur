import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, Send } from "lucide-react";
import { WS_URL, api, apiError, TOKEN_KEY } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { useToast } from "../../lib/toast";
import { GlassCard, Spinner } from "../../components/glass";
import type { SupportMessage } from "../../lib/types";

export function SupportChatPage() {
  const navigate = useNavigate();
  const { t } = useLang();
  const toast = useToast();
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const [connected, setConnected] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const messagesQ = useQuery({
    queryKey: ["support-messages"],
    queryFn: async () => (await api.get<SupportMessage[]>("/support/messages")).data,
    refetchInterval: connected ? false : 8000,
  });

  const messages = messagesQ.data ?? [];

  useEffect(() => {
    scrollRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages.length]);

  useEffect(() => {
    let ws: WebSocket | null = null;
    try {
      const token = localStorage.getItem(TOKEN_KEY);
      const url = `${WS_URL}/support/ws?token=${encodeURIComponent(token ?? "")}`;
      ws = new WebSocket(url);
      ws.onopen = () => setConnected(true);
      ws.onmessage = () => messagesQ.refetch();
      ws.onclose = () => setConnected(false);
      ws.onerror = () => setConnected(false);
    } catch {
      setConnected(false);
    }
    return () => ws?.close();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function send() {
    if (!text.trim()) return;
    setSending(true);
    try {
      await api.post("/support/messages", { text: text.trim() });
      setText("");
      messagesQ.refetch();
    } catch (err) {
      toast.error(apiError(err));
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="mx-auto flex h-[calc(100dvh-8rem)] max-w-2xl flex-col">
      <div className="mb-3 flex items-center justify-between">
        <button
          type="button"
          onClick={() => navigate("/profile")}
          className="flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
        >
          <ArrowLeft size={14} /> {t.common.back}
        </button>
        <span
          className={`flex items-center gap-1.5 rounded-full px-3 py-1 text-[11px] font-bold ${
            connected
              ? "bg-success/10 text-success"
              : "bg-warning/10 text-warning"
          }`}
        >
          <span className={`h-1.5 w-1.5 rounded-full ${connected ? "bg-success" : "bg-warning"}`} />
          {connected ? t.support.connected : t.support.disconnected}
        </span>
      </div>

      <div className="flex items-center gap-2">
        <h1 className="text-xl font-black text-ink">{t.support.chatTitle}</h1>
        <span className="text-xs text-muted">{t.support.chatSubtitle}</span>
      </div>

      <GlassCard className="mt-4 flex min-h-0 flex-1 flex-col p-4">
        {messagesQ.isLoading ? (
          <div className="grid flex-1 place-items-center"><Spinner /></div>
        ) : messages.length === 0 ? (
          <div className="grid flex-1 place-items-center text-center text-sm text-muted">
            {t.support.noMessages}
          </div>
        ) : (
          <div className="min-h-0 flex-1 space-y-2 overflow-y-auto pr-1">
            {messages.map((m) => (
              <div key={m.id} className={`flex ${m.is_from_user ? "justify-end" : "justify-start"}`}>
                <div
                  className={`max-w-[80%] rounded-3xl px-4 py-2.5 text-sm leading-relaxed ${
                    m.is_from_user
                      ? "rounded-br-md bg-gradient-to-br from-wine to-wine-dark text-white"
                      : "rounded-bl-md border border-line bg-surface text-ink"
                  }`}
                >
                  {m.text}
                  <div
                    className={`mt-1 text-[10px] ${m.is_from_user ? "text-white/60" : "text-muted"}`}
                  >
                    {new Date(m.created_at).toLocaleTimeString([], {
                      hour: "2-digit",
                      minute: "2-digit",
                    })}
                  </div>
                </div>
              </div>
            ))}
            <div ref={scrollRef} />
          </div>
        )}

        <div className="mt-3 flex items-end gap-2 border-t border-line pt-3">
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter" && !e.shiftKey) {
                e.preventDefault();
                void send();
              }
            }}
            rows={1}
            placeholder={t.support.typeMessage}
            className="glass-input min-h-[44px] flex-1 resize-none px-4 py-2.5 text-sm text-ink"
          />
          <button
            type="button"
            onClick={send}
            disabled={sending || !text.trim()}
            className="press btn-primary grid h-11 w-11 shrink-0 place-items-center rounded-full disabled:cursor-not-allowed disabled:opacity-50"
            aria-label={t.support.send}
          >
            <Send size={17} />
          </button>
        </div>
      </GlassCard>
    </div>
  );
}
