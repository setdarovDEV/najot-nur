/** Najot Nur shield mark (docs/NN_aydentika.pdf) + NotiqAI wordmark. */
export default function Logo({ light = false }: { light?: boolean }) {
  return (
    <div className="flex items-center gap-2.5">
      <img
        src={light ? "/logo-nn-white.png" : "/logo-nn.png"}
        alt="Najot Nur"
        className="h-10 w-auto"
        width="29"
        height="40"
      />
      <div className="leading-tight">
        <span className={`block text-lg font-extrabold tracking-tight ${light ? "text-white" : "text-ink"}`}>
          NotiqAI
        </span>
        <span className={`block text-[10px] font-semibold ${light ? "text-white/70" : "text-wine-600"}`}>
          Najot Nur loyihasi
        </span>
      </div>
    </div>
  );
}
