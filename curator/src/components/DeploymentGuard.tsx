import type { ReactNode } from "react";

/**
 * Hosts this build is allowed to run on. If the current hostname isn't in
 * the allowlist, we refuse to render the app — that means a swapped Docker
 * image (e.g. the admin build accidentally deployed to curator.notiqlik.uz)
 * shows a clear error to the user instead of silently letting them into the
 * wrong panel.
 *
 * Localhost / private IPs are always allowed so the dev server works.
 */
const ALLOWED_PROD_HOSTS: readonly string[] = (
  (import.meta.env.VITE_EXPECTED_HOST as string | undefined) ?? ""
)
  .split(",")
  .map((h) => h.trim().toLowerCase())
  .filter(Boolean);

function isLocalHost(host: string): boolean {
  return (
    host === "localhost" ||
    host === "127.0.0.1" ||
    host === "0.0.0.0" ||
    host === "::1" ||
    host.endsWith(".localhost") ||
    /^10\./.test(host) ||
    /^192\.168\./.test(host) ||
    /^172\.(1[6-9]|2[0-9]|3[01])\./.test(host)
  );
}

export function DeploymentGuard({ children }: { children: ReactNode }) {
  if (typeof window === "undefined") return <>{children}</>;

  const host = window.location.hostname.toLowerCase();

  // Local / private network → always allowed (dev / staging).
  if (isLocalHost(host)) return <>{children}</>;

  // No expected host configured (e.g. dev with no VITE_EXPECTED_HOST) →
  // allow by default.
  if (ALLOWED_PROD_HOSTS.length === 0) return <>{children}</>;

  if (ALLOWED_PROD_HOSTS.includes(host)) return <>{children}</>;

  // Wrong deployment — show a clear error instead of letting the user
  // sign in on a panel that was never meant for this domain.
  return <DeploymentMismatch expected={ALLOWED_PROD_HOSTS} got={host} />;
}

function DeploymentMismatch({
  expected,
  got,
}: {
  expected: readonly string[];
  got: string;
}) {
  return (
    <div className="grid min-h-screen place-items-center bg-gradient-to-br from-red-900 via-wine-dark to-wine-deep p-6 text-white">
      <div className="w-full max-w-lg rounded-3xl bg-card p-8 text-ink shadow-2xl">
        <div className="mb-4 grid h-14 w-14 place-items-center rounded-2xl bg-red-100 text-red-600">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="28"
            height="28"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
            <line x1="12" y1="9" x2="12" y2="13" />
            <line x1="12" y1="17" x2="12.01" y2="17" />
          </svg>
        </div>
        <h1 className="text-xl font-extrabold text-ink">Notoʻgʻri domen</h1>
        <p className="mt-2 text-sm leading-relaxed text-muted">
          Bu ilova notoʻgʻri domenda ishlayapti. Ehtimol, server notoʻgʻri
          build bilan deploy qilingan.
        </p>

        <div className="mt-5 space-y-2 rounded-2xl border border-line bg-surface p-4 font-mono text-xs">
          <div className="flex items-center justify-between gap-2">
            <span className="text-muted">Joriy domen:</span>
            <span className="font-bold text-red-600">{got}</span>
          </div>
          <div className="flex items-center justify-between gap-2">
            <span className="text-muted">Kutilgan domen:</span>
            <span className="font-bold text-green-700">
              {expected.join(", ")}
            </span>
          </div>
        </div>

        <p className="mt-5 text-xs leading-relaxed text-muted">
          Tuzatish uchun serverda toʻgʻri Docker image ni deploy qiling yoki
          <code className="mx-1 rounded bg-surface px-1.5 py-0.5 font-mono text-[11px]">
            VITE_EXPECTED_HOST
          </code>
          build arg sifatida toʻgʻri domenga oʻrnating.
        </p>
      </div>
    </div>
  );
}
