import { useEffect, useRef, useState } from "react";
import {
  useMutation,
  useQuery,
  useQueryClient,
} from "@tanstack/react-query";
import { ArrowLeft, MessageCircle, Send, User } from "lucide-react";
import { api, apiError, TOKEN_KEY, WS_URL } from "../lib/api";
import type {
  SupportChatSummary,
  SupportMessage,
  WsChatUpdated,
  WsNewMessage,
} from "../lib/types";
import { PageHeader } from "../components/Layout";
import { useLang } from "../lib/i18n";
import { useToast } from "../lib/toast";

function mapMessage(raw: WsNewMessage["message"]): SupportMessage {
  return {
    id: raw.id,
    user_id: raw.user_id,
    text: raw.text,
    is_from_user: raw.is_from_user,
    sent_by: raw.sent_by,
    created_at: raw.created_at,
  };
}

export function SupportChatsPage() {
  const { t } = useLang();
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [reply, setReply] = useState("");
  const qc = useQueryClient();
  const toast = useToast();
  const bottomRef = useRef<HTMLDivElement>(null);
  const [wsStatus, setWsStatus] = useState<"idle" | "open" | "closed">("idle");

  // Keep a ref so WS callbacks always see the latest selectedUserId
  // without needing to close/reopen the socket on every chat switch.
  const selectedUserIdRef = useRef<string | null>(null);
  useEffect(() => {
    selectedUserIdRef.current = selectedUserId;
  }, [selectedUserId]);

  const { data: chats = [], isLoading: chatsLoading } = useQuery({
    queryKey: ["support-chats"],
    queryFn: async () =>
      (await api.get<SupportChatSummary[]>("/support/admin/chats")).data,
  });

  const { data: messages = [], isLoading: msgsLoading } = useQuery({
    queryKey: ["support-messages", selectedUserId],
    queryFn: async () =>
      selectedUserId
        ? (
            await api.get<SupportMessage[]>(
              `/support/admin/chats/${selectedUserId}/messages`,
            )
          ).data
        : [],
    enabled: !!selectedUserId,
  });

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  // ─── Stable WebSocket — NOT in selectedUserId deps ───────────────────────
  // The selectedUserIdRef keeps the callback up-to-date without reconnecting.
  useEffect(() => {
    const token = localStorage.getItem(TOKEN_KEY);
    if (!token) return;
    let socket: WebSocket | null = null;
    let retry: ReturnType<typeof setTimeout> | null = null;
    let alive = true;

    const connect = () => {
      socket = new WebSocket(`${WS_URL}/support/ws/admin?token=${token}`);
      socket.onopen = () => {
        if (alive) setWsStatus("open");
      };
      socket.onclose = () => {
        if (!alive) return;
        setWsStatus("closed");
        retry = setTimeout(connect, 3_000);
      };
      socket.onerror = () => socket?.close();
      socket.onmessage = (event) => {
        let payload: { event: string } & Record<string, unknown>;
        try {
          payload = JSON.parse(event.data);
        } catch {
          return;
        }

        if (payload.event === "new_message") {
          const msg = mapMessage(
            (payload as unknown as WsNewMessage).message,
          );
          if (selectedUserIdRef.current === msg.user_id) {
            qc.setQueryData<SupportMessage[]>(
              ["support-messages", msg.user_id],
              (prev = []) =>
                prev.some((m) => m.id === msg.id) ? prev : [...prev, msg],
            );
            // Mark thread as read since admin is viewing it.
            void api
              .post(`/support/admin/chats/${msg.user_id}/read`)
              .catch(() => undefined);
            // Zero out unread in the list optimistically.
            qc.setQueryData<SupportChatSummary[]>(
              ["support-chats"],
              (prev = []) =>
                prev.map((c) =>
                  c.user_id === msg.user_id ? { ...c, unread_count: 0 } : c,
                ),
            );
          }
          void qc.invalidateQueries({ queryKey: ["support-chats"] });
        } else if (payload.event === "chat_updated") {
          const upd = payload as unknown as WsChatUpdated;
          qc.setQueryData<SupportChatSummary[]>(
            ["support-chats"],
            (prev = []) =>
              prev.map((c) =>
                c.user_id === upd.user_id
                  ? {
                      ...c,
                      last_message: upd.last_message,
                      last_message_at: upd.last_message_at,
                      unread_count: upd.unread_count,
                    }
                  : c,
              ),
          );
        }
      };
    };

    connect();
    return () => {
      alive = false;
      if (retry) clearTimeout(retry);
      socket?.close();
    };
    // Only qc — NOT selectedUserId. The ref keeps the callback updated.
  }, [qc]);

  // ─── Mark as read when opening a thread ──────────────────────────────────
  useEffect(() => {
    if (!selectedUserId) return;

    // Optimistic: zero the badge immediately.
    qc.setQueryData<SupportChatSummary[]>(["support-chats"], (prev = []) =>
      prev.map((c) =>
        c.user_id === selectedUserId ? { ...c, unread_count: 0 } : c,
      ),
    );

    // Then persist on the server in the background.
    void api
      .post(`/support/admin/chats/${selectedUserId}/read`)
      .catch(() => undefined);
  }, [selectedUserId, qc]);

  // ─── Send reply ───────────────────────────────────────────────────────────
  const sendReply = useMutation({
    mutationFn: async (text: string) => {
      const res = await api.post<SupportMessage>(
        `/support/admin/chats/${selectedUserId}/messages`,
        { text },
      );
      return res.data;
    },
    onMutate: async (text: string) => {
      // Optimistic: add message to the list immediately.
      if (!selectedUserId) return;
      const optimistic: SupportMessage = {
        id: `optimistic-${Date.now()}`,
        user_id: selectedUserId,
        text,
        is_from_user: false,
        sent_by: null,
        created_at: new Date().toISOString(),
      };
      qc.setQueryData<SupportMessage[]>(
        ["support-messages", selectedUserId],
        (prev = []) => [...prev, optimistic],
      );
      return { optimisticId: optimistic.id };
    },
    onSuccess: (serverMsg, _text, ctx) => {
      setReply("");
      // Replace the optimistic message with the real one.
      if (selectedUserId) {
        qc.setQueryData<SupportMessage[]>(
          ["support-messages", selectedUserId],
          (prev = []) =>
            prev.map((m) =>
              m.id === ctx?.optimisticId ? serverMsg : m,
            ),
        );
      }
      void qc.invalidateQueries({ queryKey: ["support-chats"] });
    },
    onError: (err, _text, ctx) => {
      toast.error(apiError(err));
      // Roll back optimistic message.
      if (selectedUserId && ctx?.optimisticId) {
        qc.setQueryData<SupportMessage[]>(
          ["support-messages", selectedUserId],
          (prev = []) => prev.filter((m) => m.id !== ctx.optimisticId),
        );
      }
    },
  });

  const handleSend = () => {
    const text = reply.trim();
    if (text && !sendReply.isPending) sendReply.mutate(text);
  };

  const selectedChat = chats.find((c) => c.user_id === selectedUserId);

  return (
    <div className="flex h-[calc(100vh-64px)] overflow-hidden">
      {/* ── Chat list sidebar ── */}
      <aside className={`flex-col border-r border-line bg-card ${
        selectedUserId
          ? "hidden md:flex md:w-72 md:shrink-0"
          : "flex w-full md:w-72 md:shrink-0"
      }`}>
        <div className="border-b border-line px-4 py-3">
          <PageHeader
            title={t.supportChats.title}
            subtitle={
              wsStatus === "open"
                ? t.supportChats.open
                : wsStatus === "closed"
                  ? "Qayta ulanmoqda…"
                  : "Ulanmoqda…"
            }
          />
        </div>
        <div className="flex-1 overflow-y-auto">
          {chatsLoading && (
            <div className="flex items-center justify-center py-12 text-sm text-muted">
              {t.common.loading}
            </div>
          )}
          {!chatsLoading && chats.length === 0 && (
            <div className="flex flex-col items-center gap-2 py-12 text-center text-sm text-muted">
              <MessageCircle size={28} className="opacity-30" />
              <p>{t.supportChats.noChats}</p>
            </div>
          )}
          {chats.map((chat) => {
            const isActive = chat.user_id === selectedUserId;
            const name =
              chat.full_name ??
              chat.phone ??
              chat.email ??
              "Foydalanuvchi";
            const initials = name.slice(0, 2).toUpperCase();
            return (
              <button
                key={chat.user_id}
                onClick={() => setSelectedUserId(chat.user_id)}
                className={`flex w-full items-center gap-3 border-b border-line px-4 py-3 text-left transition ${
                  isActive
                    ? "bg-wine/8 dark:bg-wine/15"
                    : "hover:bg-wine-50 dark:hover:bg-wine-900/20"
                }`}
              >
                <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-wine/10 text-xs font-bold text-wine dark:bg-wine/15 dark:text-wine-300">
                  {initials}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-1">
                    <span className="truncate text-sm font-semibold text-ink">
                      {name}
                    </span>
                    {chat.unread_count > 0 && (
                      <span className="shrink-0 rounded-full bg-wine px-1.5 py-0.5 text-[10px] font-bold text-white">
                        {chat.unread_count}
                      </span>
                    )}
                  </div>
                  <p className="mt-0.5 truncate text-[11px] text-muted">
                    {chat.last_message}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      </aside>

      {/* ── Chat area ── */}
      <div className="flex min-w-0 flex-1 flex-col bg-surface">
        {!selectedUserId ? (
          <div className="flex flex-1 flex-col items-center justify-center gap-3 text-center text-muted">
            <MessageCircle size={48} className="opacity-20" />
            <p className="text-sm">{t.supportChats.noChats}</p>
          </div>
        ) : (
          <>
            {/* Header */}
            <div className="flex items-center gap-3 border-b border-line bg-card px-4 py-3 md:px-6">
              <button
                onClick={() => setSelectedUserId(null)}
                className="grid h-8 w-8 shrink-0 place-items-center rounded-xl border border-line text-muted hover:border-wine/30 hover:text-wine md:hidden"
              >
                <ArrowLeft size={16} />
              </button>
              <div className="grid h-9 w-9 place-items-center rounded-full bg-wine/10 dark:bg-wine/15">
                <User size={18} className="text-wine dark:text-wine-300" />
              </div>
              <div>
                <p className="text-sm font-bold text-ink">
                  {selectedChat?.full_name ??
                    selectedChat?.phone ??
                    selectedChat?.email ??
                    "Foydalanuvchi"}
                </p>
                <p className="text-[11px] text-muted">
                  {selectedChat?.phone ?? selectedChat?.email ?? ""}
                </p>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto px-6 py-4">
              {msgsLoading && (
                <div className="flex justify-center py-10 text-sm text-muted">
                  {t.common.loading}
                </div>
              )}
              {!msgsLoading && messages.length === 0 && (
                <div className="flex justify-center py-10 text-sm text-muted">
                  {t.supportChats.noChats}
                </div>
              )}
              {messages.map((msg) => {
                const isUser = msg.is_from_user;
                const isOptimistic = msg.id.startsWith("optimistic-");
                return (
                  <div
                    key={msg.id}
                    className={`mb-3 flex ${isUser ? "justify-start" : "justify-end"}`}
                  >
                    <div
                      className={`max-w-sm rounded-2xl px-4 py-2.5 text-sm leading-relaxed transition-opacity ${
                        isUser
                          ? "rounded-tl-sm bg-card text-ink shadow-sm ring-1 ring-line"
                          : `rounded-tr-sm bg-wine text-white ${isOptimistic ? "opacity-60" : ""}`
                      }`}
                    >
                      <p className="mb-1 text-[10px] font-semibold opacity-60">
                        {isUser ? "Foydalanuvchi" : "Qo'llab-quvvatlash"}
                      </p>
                      {msg.text}
                    </div>
                  </div>
                );
              })}
              <div ref={bottomRef} />
            </div>

            {/* Reply input */}
            <div className="border-t border-line bg-card px-6 py-3">
              <div className="flex items-end gap-3">
                <textarea
                  value={reply}
                  onChange={(e) => setReply(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      handleSend();
                    }
                  }}
                  placeholder={`${t.supportChats.typeMessage} (Enter — ${t.supportChats.send})`}
                  rows={2}
                  className="flex-1 resize-none rounded-xl border border-line bg-surface px-4 py-2.5 text-sm text-ink placeholder:text-muted outline-none transition focus:border-wine/40 focus:ring-2 focus:ring-wine/10"
                />
                <button
                  onClick={handleSend}
                  disabled={!reply.trim() || sendReply.isPending}
                  className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-wine text-white transition hover:bg-wine-dark disabled:opacity-40"
                >
                  {sendReply.isPending ? (
                    <span className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                  ) : (
                    <Send size={17} />
                  )}
                </button>
              </div>
              {sendReply.isError && (
                <p className="mt-1.5 text-xs text-red-500">
                  {apiError(sendReply.error)}
                </p>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
