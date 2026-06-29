const stats = [
  { value: "5,200+", label: "Faol foydalanuvchi" },
  { value: "96%", label: "AI aniqlik darajasi" },
  { value: "120+", label: "Video dars" },
  { value: "18", label: "Tajribali kurator" },
];

export function Stats() {
  return (
    <section className="bg-wine text-white">
      <div className="container-x grid grid-cols-2 gap-6 py-14 md:grid-cols-4">
        {stats.map((s) => (
          <div key={s.label} className="text-center md:text-left">
            <div className="text-4xl font-extrabold tracking-tight md:text-5xl">
              {s.value}
            </div>
            <div className="mt-2 text-sm font-semibold uppercase tracking-wider text-white/70">
              {s.label}
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
