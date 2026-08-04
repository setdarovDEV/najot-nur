import { useRef, useState } from "react";

/**
 * Minimal MediaRecorder wrapper. Records microphone audio and exposes the
 * resulting Blob. Returns an "error" string for permission/unsupported cases
 * so callers can surface a localized message.
 */
export function useRecorder() {
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const [recording, setRecording] = useState(false);
  const [blob, setBlob] = useState<Blob | null>(null);
  const [error, setError] = useState<string | null>(null);

  async function start() {
    setError(null);
    setBlob(null);
    if (!navigator.mediaDevices?.getUserMedia) {
      setError("recordingUnsupported");
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      chunksRef.current = [];
      const mime =
        MediaRecorder.isTypeSupported("audio/webm;codecs=opus")
          ? "audio/webm;codecs=opus"
          : MediaRecorder.isTypeSupported("audio/webm")
            ? "audio/webm"
            : "";
      const recorder = new MediaRecorder(stream, mime ? { mimeType: mime } : undefined);
      recorder.ondataavailable = (e) => {
        if (e.data.size > 0) chunksRef.current.push(e.data);
      };
      recorder.onstop = () => {
        const type = mime || "audio/webm";
        const b = new Blob(chunksRef.current, { type });
        setBlob(b);
        stream.getTracks().forEach((tr) => tr.stop());
      };
      mediaRecorderRef.current = recorder;
      recorder.start();
      setRecording(true);
    } catch {
      setError("audioPermissionDenied");
    }
  }

  function stop() {
    const recorder = mediaRecorderRef.current;
    if (!recorder || recorder.state === "inactive") return;
    recorder.stop();
    setRecording(false);
  }

  function reset() {
    stop();
    setBlob(null);
    setError(null);
  }

  return { recording, blob, error, start, stop, reset };
}
