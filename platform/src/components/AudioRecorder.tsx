import { useEffect, useState } from "react";
import { AudioLines, RotateCcw, Square, AlertCircle } from "lucide-react";
import { useRecorder } from "../lib/useRecorder";
import { useLang } from "../lib/i18n";
import { SecondaryButton, PrimaryButton } from "./glass";

/**
 * Reusable voice recorder. Fills `audio` (Blob | null) when a recording is
 * complete. `recordingLabel` lets callers swap the label ("stop", etc.).
 */
export function AudioRecorder({
  audio,
  setAudio,
  variant = "compact",
  onRecorded,
}: {
  audio: Blob | null;
  setAudio: (b: Blob | null) => void;
  variant?: "compact" | "card";
  onRecorded?: () => void;
}) {
  const { t } = useLang();
  const recorder = useRecorder();
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    if (!recorder.recording) {
      setSeconds(0);
      return;
    }
    const iv = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(iv);
  }, [recorder.recording]);

  useEffect(() => {
    if (recorder.blob) {
      setAudio(recorder.blob);
      onRecorded?.();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [recorder.blob]);

  const errKey = recorder.error ? t.speech[recorder.error as "audioPermissionDenied"] : null;

  if (variant === "card") {
    return (
      <div className="rounded-3xl border border-line bg-card p-5">
        <div className="flex items-center gap-3">
          <div className="grid h-11 w-11 shrink-0 place-items-center rounded-2xl bg-wine-50 text-wine dark:bg-wine/20">
            <AudioLines size={20} />
          </div>
          <div className="min-w-0 flex-1">
            <div className="text-sm font-extrabold text-ink">
              {recorder.recording
                ? t.speech.recording
                : audio
                  ? t.practicums.submitted
                  : t.speech.recordBtn}
            </div>
            {recorder.recording && (
              <div className="mt-1 text-xs font-bold text-wine">
                {String(Math.floor(seconds / 60)).padStart(2, "0")}:
                {String(seconds % 60).padStart(2, "0")}
              </div>
            )}
            {audio && !recorder.recording && (
              <audio controls src={URL.createObjectURL(audio)} className="mt-2 w-full" />
            )}
          </div>
        </div>

        {errKey && (
          <div className="mt-3 flex items-center gap-2 rounded-2xl border border-red-200 bg-red-50 px-3 py-2.5 text-xs font-semibold text-red-600 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-400">
            <AlertCircle size={14} className="shrink-0" /> {errKey}
          </div>
        )}

        <div className="mt-4 flex gap-2">
          {recorder.recording ? (
            <PrimaryButton
              type="button"
              onClick={recorder.stop}
              className="flex-1"
            >
              <Square size={14} /> {t.speech.stopBtn}
            </PrimaryButton>
          ) : (
            <PrimaryButton type="button" onClick={recorder.start} className="flex-1">
              <AudioLines size={15} /> {t.speech.recordBtn}
            </PrimaryButton>
          )}
          {audio && !recorder.recording && (
            <SecondaryButton
              type="button"
              onClick={recorder.reset}
              className="shrink-0"
            >
              <RotateCcw size={14} /> {t.speech.restartBtn}
            </SecondaryButton>
          )}
        </div>
      </div>
    );
  }

  // compact: inline pill row
  return (
    <div>
      <div className="flex flex-wrap items-center gap-2">
        {recorder.recording ? (
          <PrimaryButton type="button" onClick={recorder.stop} className="px-4 py-2">
            <Square size={14} /> {t.speech.recording} {seconds}s
          </PrimaryButton>
        ) : (
          <PrimaryButton type="button" onClick={recorder.start} className="px-4 py-2">
            <AudioLines size={14} /> {audio ? t.speech.restartBtn : t.speech.recordBtn}
          </PrimaryButton>
        )}
        {audio && !recorder.recording && (
          <audio controls src={URL.createObjectURL(audio)} className="h-9 w-56" />
        )}
      </div>
      {errKey && (
        <p className="mt-2 flex items-center gap-1.5 text-xs font-semibold text-red-500">
          <AlertCircle size={13} /> {errKey}
        </p>
      )}
    </div>
  );
}
