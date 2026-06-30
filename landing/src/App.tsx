import { Navbar } from "./components/Navbar";
import { Footer } from "./components/Footer";
import { Hero } from "./sections/Hero";
import { About } from "./sections/About";
import { Features } from "./sections/Features";
import { How } from "./sections/How";
import { Stats } from "./sections/Stats";
import { Pricing } from "./sections/Pricing";
import { Testimonials } from "./sections/Testimonials";
import { FAQ } from "./sections/FAQ";
import { QRBanner } from "./sections/QRBanner";
import { CTA } from "./sections/CTA";
import { Contact } from "./sections/Contact";

export default function App() {
  return (
    <div className="min-h-screen bg-paper text-ink">
      <Navbar />
      <main>
        <Hero />
        <About />
        <Features />
        <How />
        <Stats />
        <Pricing />
        <Testimonials />
        <QRBanner />
        <FAQ />
        <CTA />
        <Contact />
      </main>
      <Footer />
    </div>
  );
}
