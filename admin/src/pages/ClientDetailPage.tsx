import { useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { Link, useParams } from "react-router-dom";
import { Gift, MapPin } from "lucide-react";
import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import L from "leaflet";
import markerIcon2x from "leaflet/dist/images/marker-icon-2x.png";
import markerIcon from "leaflet/dist/images/marker-icon.png";
import markerShadow from "leaflet/dist/images/marker-shadow.png";
import "leaflet/dist/leaflet.css";
import { api, apiError } from "../lib/api";
import { ScoreBadge } from "./ClientsPage";
import { useLang } from "../lib/i18n";
import { useToast } from "../lib/toast";
import { Modal, ModalFooter } from "../components/Modal";
import type { AdminCourse, ClientEnrollment, ClientHomework } from "../lib/types";
import { Reveal, GlassInput, GlassSelect } from "../components/glass";

const markerIconInstance = L.icon({
  iconUrl: markerIcon,
  iconRetinaUrl: markerIcon2x,
  shadowUrl: markerShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

interface SpeechRow {
  id: string;
  overall_score: number | null;
  summary: string | null;
  created_at: string;
}
interface ClientDetail {
  id: string;
  full_name: string | null;
  phone: string | null;
  email: string | null;
  is_verified: boolean;
  created_at: string;
  city: string | null;
  region: string | null;
  country: string | null;
  latitude: number | null;
  longitude: number | null;
  speech_analyses: SpeechRow[];
  enrollments: ClientEnrollment[];
  homeworks: ClientHomework[];
}

export function ClientDetailPage() {
  const { id } = useParams();
  const { t } = useLang();
  const toast = useToast();
  const qc = useQueryClient();
  const [giftOpen, setGiftOpen] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ["client", id],
    queryFn: async () =>
      (await api.get<ClientDetail>(`/admin/clients/${id}`)).data,
  });

  const giftedCourseIds = new Set(data?.enrollments.map((e) => e.course_id));

  return (
    <div className="p-4 sm:p-6 md:p-8">
      <Link to="/clients" className="text-sm font-semibold text-wine">
        {t.clients.backToList}
      </Link>

      {isLoading || !data ? (
        <p className="mt-6 text-muted">{t.common.loading}</p>
      ) : (
        <>
          <div className="mt-4 rounded-2xl bg-gradient-to-br from-wine to-wine-deep p-5 text-white sm:p-6">
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div>
                <h1 className="text-xl font-extrabold sm:text-2xl">
                  {data.full_name ?? t.clients.unnamed}
                </h1>
                <div className="mt-2 flex flex-wrap gap-x-6 gap-y-1 text-sm text-white/85">
                  <span>📞 {data.phone ?? "—"}</span>
                  <span>✉️ {data.email ?? "—"}</span>
                  <span>{new Date(data.created_at).toLocaleDateString()}</span>
                </div>
                <code className="mt-2 block text-xs text-white/60">ID: {data.id}</code>
              </div>
              <button
                onClick={() => setGiftOpen(true)}
                className="press flex shrink-0 items-center gap-2 rounded-full bg-white/15 px-4 py-2.5 text-sm font-bold text-white transition hover:bg-white/25"
              >
                <Gift size={16} />
                {t.clients.giftCourse}
              </button>
            </div>
          </div>

          <h2 className="mb-3 mt-8 flex items-center gap-2 text-lg font-bold text-ink">
            <MapPin size={18} className="text-wine" />
            {t.clients.location}
          </h2>
          {data.latitude != null && data.longitude != null ? (
            <div className="overflow-hidden rounded-2xl border border-line">
              <div className="border-b border-line bg-card px-5 py-3 text-sm text-ink">
                <span className="font-semibold">{data.full_name ?? t.clients.unnamed}</span>
                <span className="ml-2 text-muted">
                  {[data.city, data.region, data.country].filter(Boolean).join(", ") || "—"}
                </span>
              </div>
              <div style={{ height: "320px" }}>
                <MapContainer
                  center={[data.latitude, data.longitude]}
                  zoom={11}
                  style={{ height: "100%", width: "100%" }}
                >
                  <TileLayer
                    attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                    url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                  />
                  <Marker position={[data.latitude, data.longitude]} icon={markerIconInstance}>
                    <Popup>
                      <div className="text-sm">
                        <div className="font-bold">{data.full_name ?? t.clients.unnamed}</div>
                        {data.phone && <div>📞 {data.phone}</div>}
                      </div>
                    </Popup>
                  </Marker>
                </MapContainer>
              </div>
            </div>
          ) : (
            <p className="rounded-xl border border-line bg-card p-5 text-muted">
              {t.clients.noLocation}
            </p>
          )}

          <h2 className="mb-3 mt-8 text-lg font-bold text-ink">{t.clients.courses}</h2>
          {data.enrollments.length === 0 ? (
            <p className="rounded-xl border border-line bg-card p-5 text-muted">
              {t.clients.noCourses}
            </p>
          ) : (
            <div className="space-y-3">
              {data.enrollments.map((e, i) => (
                <Reveal key={e.id} index={i}>
                  <div className="rounded-2xl border border-line bg-card p-5">
                    <div className="mb-2 flex items-center justify-between">
                      <span className="font-semibold text-ink">{e.course_title}</span>
                      <span className="text-xs text-muted">
                        {new Date(e.created_at).toLocaleDateString()}
                      </span>
                    </div>
                    <div className="flex items-center gap-3">
                      <div className="h-2 flex-1 overflow-hidden rounded-full bg-line/50">
                        <div
                          className="h-full rounded-full bg-wine"
                          style={{ width: `${Math.min(100, Math.max(0, e.progress_pct))}%` }}
                        />
                      </div>
                      <span className="text-xs font-semibold text-muted">
                        {e.progress_pct}%
                      </span>
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          )}

          <h2 className="mb-3 mt-8 text-lg font-bold text-ink">{t.clients.homeworkProgress}</h2>
          {data.homeworks.length === 0 ? (
            <p className="rounded-xl border border-line bg-card p-5 text-muted">
              {t.clients.noHomeworksClient}
            </p>
          ) : (
            <div className="space-y-3">
              {data.homeworks.map((hw, i) => (
                <Reveal key={hw.id} index={i}>
                  <div className="rounded-2xl border border-line bg-card p-5">
                    <div className="mb-2 flex items-center justify-between">
                      <span className="font-semibold text-ink">
                        <span className="text-wine">{hw.course_title}</span> › {hw.lesson_title}
                      </span>
                      <span
                        className={`rounded-full px-2.5 py-1 text-xs font-bold ${
                          hw.status === "reviewed"
                            ? "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                            : hw.status === "returned"
                              ? "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400"
                              : "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400"
                        }`}
                      >
                        {hw.status === "reviewed"
                          ? t.homeworks.reviewed
                          : hw.status === "returned"
                            ? t.homeworks.returned
                            : t.homeworks.new_}
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-sm text-muted">
                      <span>{hw.curator_feedback ?? "—"}</span>
                      {hw.curator_score != null && (
                        <span className="font-semibold text-ink">
                          {t.homeworks.score}: {hw.curator_score}
                        </span>
                      )}
                    </div>
                  </div>
                </Reveal>
              ))}
            </div>
          )}

          <h2 className="mb-3 mt-8 text-lg font-bold text-ink">{t.clients.speechAnalyses}</h2>
          {data.speech_analyses.length === 0 ? (
            <p className="rounded-xl border border-line bg-card p-5 text-muted">
              {t.clients.noAnalyses}
            </p>
          ) : (
            <div className="space-y-3">
              {data.speech_analyses.map((s, i) => (
                <Reveal key={s.id} index={i}>
                  <div className="rounded-2xl border border-line bg-card p-5">
                    <div className="mb-2 flex items-center justify-between">
                      {s.overall_score != null ? (
                        <ScoreBadge score={s.overall_score} />
                      ) : (
                        <span className="text-muted">—</span>
                      )}
                      <span className="text-xs text-muted">
                        {new Date(s.created_at).toLocaleString()}
                      </span>
                    </div>
                    <p className="text-sm leading-relaxed text-ink">
                      {s.summary ?? "—"}
                    </p>
                  </div>
                </Reveal>
              ))}
            </div>
          )}

          <GiftCourseModal
            open={giftOpen}
            onClose={() => setGiftOpen(false)}
            userId={data.id}
            excludeCourseIds={giftedCourseIds}
            onGifted={() => {
              qc.invalidateQueries({ queryKey: ["client", id] });
              toast.success(t.clients.giftSuccess);
              setGiftOpen(false);
            }}
          />
        </>
      )}
    </div>
  );
}

function GiftCourseModal({
  open,
  onClose,
  userId,
  excludeCourseIds,
  onGifted,
}: {
  open: boolean;
  onClose: () => void;
  userId: string;
  excludeCourseIds: Set<string>;
  onGifted: () => void;
}) {
  const { t } = useLang();
  const toast = useToast();
  const [courseId, setCourseId] = useState("");
  const [note, setNote] = useState("");

  const { data: courses } = useQuery({
    queryKey: ["admin-courses"],
    queryFn: async () => (await api.get<AdminCourse[]>("/admin/courses")).data,
    enabled: open,
  });

  const gift = useMutation({
    mutationFn: () =>
      api.post(`/admin/clients/${userId}/gift-course`, {
        course_id: courseId,
        admin_note: note || null,
      }),
    onSuccess: () => {
      setCourseId("");
      setNote("");
      onGifted();
    },
    onError: (e) => toast.error(apiError(e)),
  });

  const availableCourses = (courses ?? []).filter((c) => !excludeCourseIds.has(c.id));

  return (
    <Modal
      open={open}
      onClose={onClose}
      title={t.clients.giftCourseTitle}
      subtitle={t.clients.giftCourseDesc}
      size="sm"
      footer={
        <ModalFooter
          onClose={onClose}
          onSubmit={() => gift.mutate()}
          saving={gift.isPending}
          submitLabel={t.clients.giftSubmit}
          submitDisabled={!courseId}
        />
      }
    >
      <div className="space-y-4">
        <label className="block text-sm">
          <span className="mb-1 block font-semibold text-ink">
            {t.clients.selectCourse}
          </span>
          <GlassSelect
            value={courseId}
            onChange={(e) => setCourseId(e.target.value)}
          >
            <option value="">—</option>
            {availableCourses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
              </option>
            ))}
          </GlassSelect>
        </label>
        <label className="block text-sm">
          <span className="mb-1 block font-semibold text-ink">{t.clients.giftNote}</span>
          <GlassInput
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
        </label>
      </div>
    </Modal>
  );
}
