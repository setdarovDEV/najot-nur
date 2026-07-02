import Logo from "./Logo";
import CTAButton from "./CTAButton";
import { useScrolledPast } from "../lib/hooks";

export default function Header() {
  const scrolled = useScrolledPast(12);

  return (
    <header
      className={`sticky top-0 z-40 border-b bg-paper/85 backdrop-blur-md transition-all duration-300 ${
        scrolled ? "border-wine-100 shadow-soft" : "border-transparent"
      }`}
    >
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6">
        <div className="enter">
          <Logo />
        </div>
        <div className="enter" style={{ animationDelay: "150ms" }}>
          <CTAButton
            id="header_cta"
            event="main_cta_click"
            size="md"
            className="btn-shimmer"
            meta={{ placement: "header" }}
          >
            Bepul sinab ko‘rish
          </CTAButton>
        </div>
      </div>
    </header>
  );
}
