export type TrackingEventName =
  | "speech_test_click"
  | "voice_test_click"
  | "observation_test_click"
  | "main_cta_click";

declare global {
  interface Window {
    dataLayer?: Record<string, unknown>[];
  }
}

/**
 * Pushes CTA events into window.dataLayer (GTM / Meta Pixel bridge).
 * Event names are fixed by the landing TZ, section 12.
 */
export function track(event: TrackingEventName, meta: Record<string, unknown> = {}): void {
  const payload = {
    event,
    ...meta,
    device: window.innerWidth < 768 ? "mobile" : "desktop",
    ts: Date.now(),
  };
  window.dataLayer = window.dataLayer ?? [];
  window.dataLayer.push(payload);
  if (import.meta.env.DEV) {
    console.debug("[track]", payload);
  }
}
