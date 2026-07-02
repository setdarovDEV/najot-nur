import Header from "./components/Header";
import Hero from "./components/Hero";
import Trust from "./components/Trust";
import Problem from "./components/Problem";
import Features from "./components/Features";
import Results from "./components/Results";
import Audience from "./components/Audience";
import HowItWorks from "./components/HowItWorks";
import FinalCTA from "./components/FinalCTA";
import Footer from "./components/Footer";
import StickyCTA from "./components/StickyCTA";

export default function App() {
  return (
    <div className="min-h-screen">
      <Header />
      <main>
        <Hero />
        <Trust />
        <Problem />
        <Features />
        <Results />
        <Audience />
        <HowItWorks />
        <FinalCTA />
      </main>
      <Footer />
      <StickyCTA />
    </div>
  );
}
