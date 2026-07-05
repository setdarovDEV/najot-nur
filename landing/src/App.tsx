import { useState, useEffect } from "react";
import Header from "./components/Header";
import Hero from "./components/Hero";
import Trust from "./components/Trust";
import Problem from "./components/Problem";
import Features from "./components/Features";
import PronunciationTrial from "./components/PronunciationTrial";
import Results from "./components/Results";
import Audience from "./components/Audience";
import HowItWorks from "./components/HowItWorks";
import FinalCTA from "./components/FinalCTA";
import Footer from "./components/Footer";
import StickyCTA from "./components/StickyCTA";
import PronunciationDemo from "./components/PronunciationDemo";

export default function App() {
  const [demoOpen, setDemoOpen] = useState(false);
  const [demoExercise, setDemoExercise] = useState<string | undefined>();

  useEffect(() => {
    const handler = (e: Event) => {
      const detail = (e as CustomEvent<{ exerciseId?: string }>).detail;
      setDemoExercise(detail?.exerciseId);
      setDemoOpen(true);
    };
    document.addEventListener("open-demo", handler);
    return () => document.removeEventListener("open-demo", handler);
  }, []);

  return (
    <div className="min-h-screen">
      <Header />
      <main>
        <Hero />
        <Trust />
        <Problem />
        <Features />
        <PronunciationTrial />
        <Results />
        <Audience />
        <HowItWorks />
        <FinalCTA />
      </main>
      <Footer />
      <StickyCTA />

      {demoOpen && (
        <PronunciationDemo
          initialExercise={demoExercise}
          onClose={() => setDemoOpen(false)}
        />
      )}
    </div>
  );
}
