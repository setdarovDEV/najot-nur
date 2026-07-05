import { BadgeCheck, Sparkles, Timer, UserCheck, Zap } from "lucide-react";

const BADGES = [
  { text: "Bepul sinab ko‘rish", icon: BadgeCheck },
  { text: "5 daqiqada natija", icon: Timer },
  { text: "AI — Najot Nurning ovozi va bilimlari asosida mashq qildirilgan", icon: UserCheck },
  { text: "AI orqali avtomatik tahlil", icon: Sparkles },
  { text: "Telefoningizda — istalgan joyda", icon: Zap },
];

/** Infinite marquee trust strip — badges duplicated for a seamless loop. */
export default function Trust() {
  return (
    <section className="marquee-mask overflow-hidden border-y border-wine-100/60 bg-wine-50/50 py-6">
      <div className="animate-marquee flex w-max gap-4 pr-4">
        {[...BADGES, ...BADGES, ...BADGES].map((badge, i) => (
          <div
            key={i}
            className="flex shrink-0 items-center gap-2.5 rounded-full bg-white px-5 py-2.5 shadow-card ring-1 ring-wine-100/70"
          >
            <badge.icon className="h-4.5 w-4.5 text-wine-600" />
            <span className="whitespace-nowrap text-sm font-bold text-ink">{badge.text}</span>
          </div>
        ))}
      </div>
    </section>
  );
}
