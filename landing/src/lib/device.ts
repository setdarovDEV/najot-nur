import { BRAND } from "./config";

export type DeviceOS = "ios" | "android" | "desktop";

export function getDeviceOS(): DeviceOS {
  const ua = navigator.userAgent;
  if (/iPad|iPhone|iPod/.test(ua)) return "ios";
  if (/Android/i.test(ua)) return "android";
  return "desktop";
}

export function getAppDownloadUrl(): string {
  const os = getDeviceOS();
  if (os === "ios") return BRAND.links.appStore || BRAND.links.playMarket || "#";
  return BRAND.links.playMarket || "#";
}

/** Fire a custom event to open the pronunciation demo modal. */
export function openDemo(exerciseId?: string): void {
  document.dispatchEvent(
    new CustomEvent("open-demo", { detail: { exerciseId } }),
  );
}
