import { useReveal } from "../lib/hooks";

const stats = [
  { value: "5,200+", label: "Faol foydalanuvchi" },
  { value: "96%", label: "AI aniqlik darajasi" },
  { value: "120+", label: "Video dars" },
  { value: "18", label: "Tajribali kurator" },
];

export function Stats() {
  const { ref, visible } = useReveal<HTMLDivElement>();
  return (
    <section className="relative overflow-hidden bg-wine text-white">
      <div
        aria-hidden
        className="absolute inset-0 opacity-[0.07]"
        style={{
          backgroundImage:
            "radial-gradient(circle, rgba(255,255,255,0.6) 1px, transparent 1px)",
          backgroundSize: "20px 20px",
        }}
      />
      <div
        aria-hidden
        className="absolute -left-32 top-0 h-64 w-64 animate-blob rounded-full bg-orange/30 blur-3xl"
      />
      <div
        aria-hidden
        className="absolute -right-32 bottom-0 h-64 w-64 animate-blob rounded-full bg-skyblue/30 blur-3xl"
        style={{ animationDelay: "3s" }}
      />
      <div ref={ref} className={`container-x relative grid grid-cols-2 gap-6 py-14 md:grid-cols-4 reveal ${visible ? "is-visible" : ""}`}>
        {stats.map((s, i) => (
          <div
            key={s.label}
            className="group text-center md:text-left"
            style={{ animation: `fade-up 0.7s ${i * 0.1}s ease-out both` }}
          >
            <div className="text-4xl font-extrabold tracking-tight transition group-hover:scale-105 md:text-5xl">
              {s.value}
            </div>
            <div className="mt-2 text-sm font-semibold uppercase tracking-wider text-white/70">
              {s.label}
            </div>
            <div
              aria-hidden
              className="mx-auto mt-3 h-1 w-0 rounded-full bg-orange transition-all duration-700 group-hover:w-16 md:mx-0"
            />
          </div>
        ))}
      </div>
    </section>
  );
}
