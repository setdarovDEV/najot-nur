import { useEffect, useState } from "react";
import { Menu, X } from "lucide-react";
import { BRAND } from "../lib/config";

const links = [
  { to: "#about", label: "Biz haqimizda" },
  { to: "#features", label: "Imkoniyatlar" },
  { to: "#how", label: "Qanday ishlaydi" },
  { to: "#pricing", label: "Narxlar" },
  { to: "#app", label: "Ilova" },
  { to: "#faq", label: "FAQ" },
  { to: "#contact", label: "Bog'lanish" },
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  return (
    <header
      className={`sticky top-0 z-40 border-b transition-all duration-300 ${
        scrolled
          ? "border-line bg-paper/85 shadow-sm backdrop-blur-lg"
          : "border-transparent bg-paper/60 backdrop-blur"
      }`}
    >
      <div className="container-x flex h-16 items-center justify-between">
        <a href="#top" className="group flex items-center gap-2.5 font-extrabold">
          <span className="relative grid h-9 w-9 place-items-center overflow-hidden rounded-xl bg-wine text-white shadow-lg shadow-wine/25 transition group-hover:scale-105 group-hover:rotate-3">
            <span className="relative z-10">NN</span>
            <span
              aria-hidden
              className="absolute inset-0 bg-gradient-to-br from-wine via-orange to-skyblue opacity-0 transition group-hover:opacity-100"
            />
          </span>
          <span className="text-lg tracking-tight transition group-hover:text-wine">
            {BRAND.name}
            <span className="ml-1 text-xs font-semibold text-muted">· {BRAND.parent}</span>
          </span>
        </a>

        <nav className="hidden items-center gap-1 md:flex">
          {links.map((l) => (
            <a
              key={l.to}
              href={l.to}
              className="relative rounded-lg px-3 py-2 text-sm font-semibold text-ink/80 transition hover:text-wine"
            >
              <span>{l.label}</span>
              <span
                aria-hidden
                className="absolute inset-x-2 -bottom-0.5 h-0.5 origin-left scale-x-0 rounded-full bg-wine transition-transform duration-300 group-hover:scale-x-100"
              />
            </a>
          ))}
        </nav>

        <div className="hidden items-center gap-2 md:flex">
          <a
            href="#contact"
            className="rounded-xl bg-wine px-5 py-2.5 text-sm font-bold text-white shadow-md shadow-wine/25 transition hover:scale-[1.02] hover:bg-wine-dark hover:shadow-lg hover:shadow-wine/30"
          >
            Bog'lanish
          </a>
        </div>

        <button
          className="grid h-10 w-10 place-items-center rounded-lg text-ink transition hover:bg-wine-50 md:hidden"
          onClick={() => setOpen((v) => !v)}
          aria-label="Menyuni ochish"
        >
          <span className="relative">
            {open ? <X size={20} /> : <Menu size={20} />}
            <span
              aria-hidden
              className="absolute -inset-1 -z-10 rounded-full bg-wine/10 opacity-0 transition group-hover:opacity-100"
            />
          </span>
        </button>
      </div>

      {open && (
        <div className="border-t border-line/60 bg-paper/95 backdrop-blur-md md:hidden">
          <div className="container-x space-y-1 py-4">
            {links.map((l, i) => (
              <a
                key={l.to}
                href={l.to}
                onClick={() => setOpen(false)}
                className="block rounded-lg px-3 py-2.5 text-sm font-semibold text-ink transition hover:bg-wine-50 hover:text-wine"
                style={{
                  animation: `fade-up 0.4s ${i * 0.04}s ease-out both`,
                }}
              >
                {l.label}
              </a>
            ))}
            <div className="pt-2">
              <a
                href="#contact"
                onClick={() => setOpen(false)}
                className="block w-full rounded-xl bg-wine px-4 py-3 text-center text-sm font-bold text-white shadow-md shadow-wine/20"
              >
                Bog'lanish
              </a>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
