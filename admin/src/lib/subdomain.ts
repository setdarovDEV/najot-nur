export type AppSite = "admin" | "curator" | "dev";

/** Detect which panel is being served based on the hostname. */
export function detectSite(): AppSite {
  const host = window.location.hostname;
  if (host.startsWith("admin.")) return "admin";
  if (host.startsWith("curator.")) return "curator";
  return "dev"; // localhost or any unknown host — no restrictions
}

/**
 * Returns an error message string if the email is not allowed for the site,
 * or null if it's fine.
 */
export function emailErrorForSite(email: string, site: AppSite): string | null {
  const normalized = email.toLowerCase().trim();

  if (site === "admin") {
    if (normalized !== "admin@najotnur.uz") {
      return "Bu panel faqat admin@najotnur.uz uchun ochiq.";
    }
  }

  if (site === "curator") {
    if (!normalized.endsWith("@najotnur.uz")) {
      return "Faqat @najotnur.uz pochtalari ruxsat etilgan.";
    }
    if (normalized === "admin@najotnur.uz") {
      return "Admin bu panelga kira olmaydi.";
    }
  }

  return null;
}

/**
 * Returns an error message if the logged-in role doesn't match the site,
 * or null if it's fine.
 */
export function roleErrorForSite(role: string, site: AppSite): string | null {
  if (site === "admin" && role !== "admin") {
    return "Bu panel faqat admin uchun.";
  }
  if (site === "curator" && role !== "curator") {
    return "Bu panel faqat kuratorlar uchun.";
  }
  return null;
}
