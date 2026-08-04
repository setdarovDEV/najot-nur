import { useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { ArrowLeft, ChevronLeft, ChevronRight, Headphones, Lock, PlayCircle } from "lucide-react";
import { api, formatSum, mediaUrl } from "../../lib/api";
import { useLang } from "../../lib/i18n";
import { GlassCard, PrimaryButton, Spinner, StatusPill } from "../../components/glass";
import { OrderModal } from "../../components/OrderModal";
import type { Audiobook, AudiobookAccess } from "../../lib/types";

export function AudiobookDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useLang();
  const [orderOpen, setOrderOpen] = useState(false);
  const [page, setPage] = useState(1);

  const bookQ = useQuery({
    queryKey: ["audiobook", id],
    queryFn: async () => (await api.get<Audiobook>(`/audiobooks/${id}`)).data,
    enabled: !!id,
  });
  const accessQ = useQuery({
    queryKey: ["audiobook-access", id],
    queryFn: async () => (await api.get<AudiobookAccess>(`/audiobooks/${id}/access`)).data,
    enabled: !!id,
  });

  const book = bookQ.data;
  const access = accessQ.data;
  const granted = access?.state === "granted";
  const cover = mediaUrl(book?.cover_url);
  const currentPage = book?.pages.find((p) => p.page_number === page);
  const pages = book?.pages ?? [];

  if (bookQ.isLoading || !book) {
    return <div className="py-20"><Spinner size={26} /></div>;
  }

  return (
    <div className="mx-auto max-w-3xl">
      <button
        type="button"
        onClick={() => navigate("/audiobooks")}
        className="mb-4 flex items-center gap-1.5 text-xs font-bold text-muted transition hover:text-wine"
      >
        <ArrowLeft size={14} /> {t.common.back}
      </button>

      {/* Hero */}
      <GlassCard className="overflow-hidden">
        <div className="flex flex-col gap-5 p-5 sm:flex-row">
          <div className="grid h-40 w-40 shrink-0 place-items-center overflow-hidden rounded-3xl bg-wine-deep/10 sm:h-48 sm:w-48">
            {cover ? (
              <img src={cover} alt={book.title} className="h-full w-full object-cover" />
            ) : (
              <Headphones size={48} className="text-wine/30" />
            )}
          </div>
          <div className="min-w-0 flex-1">
            <h1 className="text-xl font-black leading-tight text-ink">{book.title}</h1>
            {book.author && (
              <p className="mt-1 text-sm text-muted">
                {t.audiobooks.by}: {book.author}
              </p>
            )}
            {book.description && (
              <p className="mt-3 text-sm leading-relaxed text-muted line-clamp-4">
                {book.description}
              </p>
            )}
            <div className="mt-3 flex flex-wrap items-center gap-2 text-xs text-muted">
              {book.category && <StatusPill tone="neutral">{book.category}</StatusPill>}
              <span>{t.audiobooks.pages(book.total_pages)}</span>
            </div>

            <div className="mt-4">
              {granted ? (
                <PrimaryButton onClick={() => setPage(1)}>
                  <PlayCircle size={17} /> {book.total_pages > 1 ? t.audiobooks.read : t.audiobooks.listen}
                </PrimaryButton>
              ) : access?.has_pending_order ? (
                <div className="flex items-center gap-2 rounded-2xl border border-warning/30 bg-warning/10 px-4 py-3 text-sm font-semibold text-warning">
                  <Lock size={16} /> {t.audiobooks.pendingOrder}
                </div>
              ) : book.is_free ? (
                <PrimaryButton onClick={() => setPage(1)}>
                  <PlayCircle size={17} /> {t.audiobooks.read}
                </PrimaryButton>
              ) : (
                <>
                  <PrimaryButton onClick={() => setOrderOpen(true)}>
                    {t.audiobooks.buy} · {formatSum(book.price)} so'm
                  </PrimaryButton>
                  <div className="mt-2 text-xs font-bold text-wine">{t.audiobooks.locked}</div>
                </>
              )}
            </div>
          </div>
        </div>
      </GlassCard>

      {/* Reader / player */}
      {granted || book.is_free ? (
        <div className="mt-5">
          {book.audio_url && (
            <audio controls className="w-full" src={mediaUrl(book.audio_url)!}>
              {t.audiobooks.listen}
            </audio>
          )}

          {pages.length > 1 && (
            <div className="mt-3 flex items-center justify-between">
              <span className="text-xs font-bold text-muted">
                {t.audiobooks.currentPage} {page} / {pages.length}
              </span>
            </div>
          )}

          {currentPage ? (
            <GlassCard className="mt-2 p-6">
              <div className="mb-4 flex items-center justify-between gap-2">
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1}
                  className="press flex items-center gap-1 rounded-full border border-line px-3.5 py-2 text-xs font-bold text-ink transition hover:border-wine/40 disabled:opacity-40"
                >
                  <ChevronLeft size={14} /> {t.audiobooks.prevPage}
                </button>
                <span className="text-[11px] font-black text-muted">
                  {t.audiobooks.pages(pages.length)}
                </span>
                <button
                  type="button"
                  onClick={() => setPage((p) => Math.min(pages.length, p + 1))}
                  disabled={page >= pages.length}
                  className="press flex items-center gap-1 rounded-full border border-line px-3.5 py-2 text-xs font-bold text-ink transition hover:border-wine/40 disabled:opacity-40"
                >
                  {t.audiobooks.nextPage} <ChevronRight size={14} />
                </button>
              </div>

              {currentPage.content && (
                <p className="whitespace-pre-line text-[15px] leading-[1.85] text-ink">
                  {currentPage.content}
                </p>
              )}

              {currentPage.audio_url && (
                <audio
                  controls
                  autoPlay={false}
                  className="mt-4 w-full"
                  src={mediaUrl(currentPage.audio_url)!}
                />
              )}
            </GlassCard>
          ) : (
            <GlassCard className="p-6 text-center text-sm text-muted">
              {t.common.noData}
            </GlassCard>
          )}
        </div>
      ) : null}

      <OrderModal
        open={orderOpen}
        onClose={() => setOrderOpen(false)}
        purpose="audiobook"
        amount={Number(book.price)}
        audiobookId={book.id}
        onSuccess={() => accessQ.refetch()}
      />
    </div>
  );
}
