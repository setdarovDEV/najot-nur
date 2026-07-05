import { useState, useEffect, useRef } from "react";
import { X, Mic, StopCircle, ChevronRight } from "lucide-react";
import { getDeviceOS } from "../lib/device";
import { track } from "../lib/tracking";
import { BRAND } from "../lib/config";

type Phase = "pick" | "countdown" | "recording" | "result";

export interface Exercise {
  id: string;
  label: string;
  level: "Oson" | "O'rta" | "Qiyin";
  text: string;
}

const EXERCISES: Exercise[] = [
  {
    id: "easy",
    label: "Oson",
    level: "Oson",
    text: "Salom! Mening ismim … Men bugun o'zim haqimda qisqacha gapirib bermoqchiman. Men notiqlik san'atini o'rganishni yaxshi ko'raman.",
  },
  {
    id: "medium",
    label: "O'rta",
    level: "O'rta",
    text: "Nutqimizni rivojlantirish uchun har kuni mashq qilish zarur. To'g'ri nafas olish, aniq talaffuz va ishonchli ovoz — bularning barchasi bir-birini to'ldiradi.",
  },
  {
    id: "hard",
    label: "Qiyin",
    level: "Qiyin",
    text: "Notiqlik san'ati — bu nafaqat so'zlarni to'g'ri talaffuz qilish, balki tinglovchini o'zingizga jalb eta bilish, ularni ilhomlantirish va har bir jumlada ma'no, ohang hamda qat'iyatni mujassam eta olish imkonini beruvchi qadimiy san'atdir.",
  },
];

const N_BARS = 20;

function randBar() {
  return 15 + Math.random() * 75;
}

interface Props {
  initialExercise?: string;
  onClose: () => void;
}

export default function PronunciationDemo({ initialExercise, onClose }: Props) {
  const [phase, setPhase] = useState<Phase>("pick");
  const [selectedId, setSelectedId] = useState<string>(
    initialExercise ?? EXERCISES[0].id,
  );
  const [countdown, setCountdown] = useState(3);
  const [elapsed, setElapsed] = useState(0);
  const [bars, setBars] = useState<number[]>(
    Array.from({ length: N_BARS }, () => 30),
  );

  const mediaRef = useRef<MediaRecorder | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const waveRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const exercise = EXERCISES.find((e) => e.id === selectedId) ?? EXERCISES[0];
  const os = getDeviceOS();

  // Countdown 3 → 2 → 1 → go
  useEffect(() => {
    if (phase !== "countdown") return;
    if (countdown <= 0) {
      setPhase("recording");
      return;
    }
    const t = setTimeout(() => setCountdown((v) => v - 1), 1000);
    return () => clearTimeout(t);
  }, [phase, countdown]);

  // Recording: timer + wave animation
  useEffect(() => {
    if (phase !== "recording") return;

    waveRef.current = setInterval(() => {
      setBars(Array.from({ length: N_BARS }, randBar));
    }, 90);

    timerRef.current = setInterval(() => {
      setElapsed((v) => v + 1);
    }, 1000);

    return () => {
      clearInterval(waveRef.current!);
      clearInterval(timerRef.current!);
    };
  }, [phase]);

  async function handleStart() {
    setCountdown(3);
    setElapsed(0);
    setPhase("countdown");
    track("speech_test_click", {
      exercise: selectedId,
      placement: "demo_modal",
    });

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mr = new MediaRecorder(stream);
      mediaRef.current = mr;
      mr.start();
    } catch {
      /* mic denied — demo still works visually */
    }
  }

  function handleStop() {
    mediaRef.current?.stop();
    mediaRef.current?.stream.getTracks().forEach((t) => t.stop());
    clearInterval(waveRef.current!);
    clearInterval(timerRef.current!);
    setPhase("result");
  }

  const mm = String(Math.floor(elapsed / 60)).padStart(2, "0");
  const ss = String(elapsed % 60).padStart(2, "0");

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 backdrop-blur-sm sm:items-center"
      onClick={(e) => {
        if (e.target === e.currentTarget) onClose();
      }}
    >
      <div className="relative w-full max-w-lg overflow-hidden rounded-t-3xl bg-white shadow-2xl sm:rounded-3xl">
        {/* ── Header ──────────────────────────────────────── */}
        <div className="flex items-center justify-between border-b border-wine-50 px-5 py-4">
          <div>
            <div className="text-sm font-extrabold text-wine-700">
              Talaffuz mashqi
            </div>
            <div className="text-[11px] text-neutral-400">
              NotiqAI ilovasidagi real tajriba
            </div>
          </div>
          <button
            onClick={onClose}
            className="grid h-8 w-8 place-items-center rounded-xl bg-neutral-100 text-neutral-500 hover:bg-wine-50 hover:text-wine-700 transition"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="max-h-[80vh] overflow-y-auto p-5">
          {/* ── PHASE: PICK ─────────────────────────────── */}
          {phase === "pick" && (
            <div className="space-y-3">
              <p className="text-sm font-semibold text-neutral-600">
                Qiyinlik darajasini tanlang:
              </p>

              {EXERCISES.map((ex) => {
                const isSelected = selectedId === ex.id;
                const colors =
                  ex.id === "easy"
                    ? "border-emerald-300 bg-emerald-50"
                    : ex.id === "medium"
                      ? "border-sky-300 bg-sky-50"
                      : "border-wine-300 bg-wine-50";
                const badge =
                  ex.id === "easy"
                    ? "bg-emerald-100 text-emerald-700"
                    : ex.id === "medium"
                      ? "bg-sky-100 text-sky-700"
                      : "bg-wine-100 text-wine-700";

                return (
                  <button
                    key={ex.id}
                    onClick={() => setSelectedId(ex.id)}
                    className={`w-full rounded-2xl border-2 p-4 text-left transition ${
                      isSelected ? colors : "border-neutral-100 hover:border-neutral-200 bg-white"
                    }`}
                  >
                    <span
                      className={`mb-2 inline-block rounded-full px-2.5 py-0.5 text-[10px] font-extrabold uppercase tracking-wider ${badge}`}
                    >
                      {ex.level}
                    </span>
                    <p className="text-sm leading-relaxed text-neutral-700">
                      {ex.text}
                    </p>
                  </button>
                );
              })}

              <button
                onClick={handleStart}
                className="btn-shimmer mt-1 flex w-full items-center justify-center gap-2 rounded-2xl bg-gradient-to-br from-wine-600 to-wine-800 py-4 text-sm font-bold text-white shadow-cta transition hover:from-wine-500 hover:to-wine-700 active:scale-[0.98]"
              >
                <Mic className="h-4 w-4" />
                Boshlash
              </button>
              <p className="text-center text-[11px] text-neutral-400">
                Mikrofon ruxsati so'raladi
              </p>
            </div>
          )}

          {/* ── PHASE: COUNTDOWN ─────────────────────── */}
          {phase === "countdown" && (
            <div className="flex flex-col items-center gap-4 py-10 text-center">
              <div
                key={countdown}
                className="text-[72px] font-extrabold leading-none text-wine-700 tabular-nums"
                style={{ animation: "countPop 0.3s cubic-bezier(0.34,1.56,0.64,1)" }}
              >
                {countdown === 0 ? "Go!" : countdown}
              </div>
              <p className="text-sm font-semibold text-neutral-500">
                Tayyorlaning — matni o'qing
              </p>
              <div className="mt-2 rounded-2xl bg-neutral-50 p-4">
                <p className="text-sm leading-relaxed text-neutral-700">
                  {exercise.text}
                </p>
              </div>
            </div>
          )}

          {/* ── PHASE: RECORDING ─────────────────────── */}
          {phase === "recording" && (
            <div className="space-y-4">
              {/* Text to read */}
              <div className="rounded-2xl bg-wine-50 ring-1 ring-wine-100 p-4">
                <div className="mb-2 flex items-center gap-1.5">
                  <span className="relative flex h-2 w-2">
                    <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-red-400 opacity-75" />
                    <span className="relative inline-flex h-2 w-2 rounded-full bg-red-500" />
                  </span>
                  <span className="text-[11px] font-extrabold uppercase tracking-wider text-red-500">
                    Yozilmoqda
                  </span>
                  <span className="ml-auto font-mono text-sm font-bold text-neutral-500 tabular-nums">
                    {mm}:{ss}
                  </span>
                </div>
                <p className="text-sm leading-relaxed font-medium text-wine-900">
                  {exercise.text}
                </p>
              </div>

              {/* Live waveform */}
              <div className="flex h-16 items-center justify-center gap-0.5 rounded-2xl bg-neutral-50 px-3">
                {bars.map((h, i) => (
                  <span
                    key={i}
                    className="w-1.5 rounded-full bg-gradient-to-t from-wine-700 to-wine-400 transition-all duration-75"
                    style={{ height: `${h}%` }}
                  />
                ))}
              </div>

              <button
                onClick={handleStop}
                className="flex w-full items-center justify-center gap-2 rounded-2xl border-2 border-red-100 bg-red-50 py-3.5 text-sm font-bold text-red-600 transition hover:bg-red-100 active:scale-[0.98]"
              >
                <StopCircle className="h-4 w-4" />
                To'xtatish va natijani ko'rish
              </button>
            </div>
          )}

          {/* ── PHASE: RESULT ────────────────────────── */}
          {phase === "result" && (
            <div className="space-y-4">
              <p className="text-center text-sm font-semibold text-neutral-700">
                Ajoyib! Natijangiz tayyor
              </p>

              {/* Blurred result card */}
              <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-wine-700 to-wine-950 p-5 text-white shadow-cta">
                {/* Decorative blobs */}
                <div className="pointer-events-none absolute -right-6 -top-6 h-28 w-28 rounded-full bg-white/5 blur-2xl" />

                {/* Score row */}
                <div className="flex items-center gap-4">
                  <div className="relative flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-white/10 ring-1 ring-white/20">
                    <svg viewBox="0 0 56 56" className="h-14 w-14 -rotate-90">
                      <circle cx="28" cy="28" r="22" fill="none" stroke="rgba(255,255,255,0.15)" strokeWidth="5" />
                      <circle cx="28" cy="28" r="22" fill="none" stroke="#fff" strokeWidth="5" strokeLinecap="round" strokeDasharray="138.2" strokeDashoffset="34.5" />
                    </svg>
                    <span className="absolute text-lg font-extrabold">75</span>
                  </div>
                  <div>
                    <div className="text-xs text-white/60">Umumiy ball</div>
                    <div className="text-2xl font-extrabold">75 / 100</div>
                    <div className="text-xs text-white/70">Yaxshi natija!</div>
                  </div>
                </div>

                {/* Metric bars */}
                <div className="mt-4 space-y-2.5">
                  {[
                    { label: "Talaffuz aniqligi", pct: 78 },
                    { label: "Ravonlik", pct: 72 },
                    { label: "Pauzalar balansi", pct: 80 },
                    { label: "Ovoz ishonchliligi", pct: 70 },
                  ].map((m) => (
                    <div key={m.label}>
                      <div className="mb-1 flex justify-between text-[11px]">
                        <span className="text-white/70">{m.label}</span>
                        <span className="text-white/90 font-bold">{m.pct}%</span>
                      </div>
                      <div className="h-1.5 overflow-hidden rounded-full bg-white/15">
                        <div
                          className="h-full rounded-full bg-white/50"
                          style={{ width: `${m.pct}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>

                {/* Blur lock overlay */}
                <div className="absolute inset-0 flex flex-col items-center justify-center rounded-3xl bg-black/30 backdrop-blur-[3px]">
                  <div className="rounded-2xl bg-white/10 px-5 py-3 text-center ring-1 ring-white/25 backdrop-blur-sm">
                    <div className="text-sm font-extrabold">
                      To'liq natijani ko'rish uchun
                    </div>
                    <div className="mt-0.5 text-xs text-white/75">
                      ilovamizni yuklab oling
                    </div>
                  </div>
                </div>
              </div>

              {/* Download buttons */}
              <div className="space-y-2.5">
                <p className="text-center text-[11px] font-semibold text-neutral-400">
                  Batafsil tahlilni ilovada bepul ko'ring
                </p>

                {(os === "android" || os === "desktop") && (
                  <a
                    href={BRAND.links.playMarket || "#"}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() =>
                      track("main_cta_click", {
                        placement: "demo_result",
                        store: "play",
                      })
                    }
                    className="flex w-full items-center gap-3.5 rounded-2xl bg-[#1a1a1a] px-5 py-3.5 text-white transition hover:bg-neutral-800 active:scale-[0.98]"
                  >
                    {/* Google Play icon */}
                    <svg className="h-6 w-6 shrink-0" viewBox="0 0 24 24" fill="none">
                      <path d="M3.61 1.81A1 1 0 0 0 2 2.73v18.54a1 1 0 0 0 1.61.92l10.83-9.27a1 1 0 0 0 0-1.84L3.61 1.81Z" fill="#EA4335"/>
                      <path d="m14.44 11.08-2.6-2.22L3.61 1.81l10.17 5.89 2.32 1.34-1.66 2.04Z" fill="#FBBC04"/>
                      <path d="m16.1 12.96-1.66-1.88 1.66-2.04 3.04 1.76a1 1 0 0 1 0 1.76l-3.04 1.76v-.01l.01-.01-.01.66Z" fill="#4285F4"/>
                      <path d="m3.61 22.19 10.83-9.27-2.6-2.22L3.61 22.19Z" fill="#34A853"/>
                    </svg>
                    <div className="text-left">
                      <div className="text-[10px] text-neutral-400 leading-none mb-0.5">
                        Google Play
                      </div>
                      <div className="text-sm font-extrabold leading-none">
                        Google Play'dan yuklab olish
                      </div>
                    </div>
                    <ChevronRight className="ml-auto h-4 w-4 text-neutral-500" />
                  </a>
                )}

                {(os === "ios" || os === "desktop") && (
                  <a
                    href={BRAND.links.appStore || "#"}
                    target="_blank"
                    rel="noopener noreferrer"
                    onClick={() =>
                      track("main_cta_click", {
                        placement: "demo_result",
                        store: "apple",
                      })
                    }
                    className="flex w-full items-center gap-3.5 rounded-2xl bg-[#1a1a1a] px-5 py-3.5 text-white transition hover:bg-neutral-800 active:scale-[0.98]"
                  >
                    {/* Apple icon */}
                    <svg className="h-6 w-6 shrink-0" viewBox="0 0 24 24" fill="currentColor">
                      <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
                    </svg>
                    <div className="text-left">
                      <div className="text-[10px] text-neutral-400 leading-none mb-0.5">
                        App Store
                      </div>
                      <div className="text-sm font-extrabold leading-none">
                        App Store'dan yuklab olish
                      </div>
                    </div>
                    <ChevronRight className="ml-auto h-4 w-4 text-neutral-500" />
                  </a>
                )}
              </div>

              {/* Try again */}
              <button
                onClick={() => {
                  setPhase("pick");
                  setElapsed(0);
                }}
                className="w-full rounded-2xl border border-neutral-200 py-3 text-sm font-semibold text-neutral-500 transition hover:border-wine-200 hover:text-wine-700"
              >
                Boshqa matnni sinab ko'rish
              </button>
            </div>
          )}
        </div>
      </div>

      <style>{`
        @keyframes countPop {
          from { transform: scale(1.4); opacity: 0; }
          to   { transform: scale(1);   opacity: 1; }
        }
      `}</style>
    </div>
  );
}
