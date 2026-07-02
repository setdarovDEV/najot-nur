import React, { useState, useRef, useEffect } from "react";
import {
  Mic,
  MessageSquare,
  Eye,
  Check,
  ChevronRight,
  Sparkles,
  TrendingUp,
  X,
  Play,
  Volume2,
  Award,
  Download,
  RotateCcw,
  Info,
  Smartphone,
  Users,
  Flame,
  Layers,
  Terminal,
  Activity,
  CheckCircle2,
  AlertTriangle,
  FlameKindling,
  SmartphoneIcon,
  DownloadCloud
} from "lucide-react";
import { TrackingEvent } from "./types";
import PhoneEmulator from "./components/PhoneEmulator";
import TrackingConsole from "./components/TrackingConsole";

export default function App() {
  const [events, setEvents] = useState<TrackingEvent[]>([]);
  const [activeEmulatorTest, setActiveEmulatorTest] = useState<"speech" | "voice" | "observation" | null>(null);
  const [isMobileDrawerOpen, setIsMobileDrawerOpen] = useState(false);
  const [isScrolledPastHero, setIsScrolledPastHero] = useState(false);

  const emulatorSectionRef = useRef<HTMLDivElement>(null);

  // Monitor scroll for sticky mobile CTA and header transitions
  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 400) {
        setIsScrolledPastHero(true);
      } else {
        setIsScrolledPastHero(false);
      }
    };
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // Event logger utility
  const trackEvent = (
    eventName: "speech_test_click" | "voice_test_click" | "observation_test_click" | "main_cta_click",
    metadata: Record<string, any> = {}
  ) => {
    const now = new Date();
    const timeStr = now.toTimeString().split(" ")[0] + "." + String(now.getMilliseconds()).padStart(3, "0");
    const newEvent: TrackingEvent = {
      id: Math.random().toString(36).substring(2, 9),
      name: eventName,
      timestamp: timeStr,
      metadata: {
        ...metadata,
        viewportWidth: window.innerWidth,
        device: window.innerWidth < 768 ? "mobile" : "desktop",
        utm_source: "instagram_ads",
        campaign: "notiqai_funnel_2026"
      }
    };
    setEvents((prev) => [...prev, newEvent]);
  };

  // Trigger test and scroll
  const handleStartTest = (type: "speech" | "voice" | "observation", eventName: any) => {
    trackEvent(eventName, { selected_test: type, trigger_button: "landing_page_cta" });
    setActiveEmulatorTest(type);
    
    // Smooth reset so that the change is detected
    setTimeout(() => setActiveEmulatorTest(null), 100);

    if (window.innerWidth < 768) {
      setIsMobileDrawerOpen(true);
    } else {
      if (emulatorSectionRef.current) {
        emulatorSectionRef.current.scrollIntoView({ behavior: "smooth", block: "center" });
      }
    }
  };

  const handleMainCTA = () => {
    trackEvent("main_cta_click", { action: "start_primary_flow", trigger: "hero_primary" });
    setActiveEmulatorTest("speech");
    setTimeout(() => setActiveEmulatorTest(null), 100);

    if (window.innerWidth < 768) {
      setIsMobileDrawerOpen(true);
    } else {
      if (emulatorSectionRef.current) {
        emulatorSectionRef.current.scrollIntoView({ behavior: "smooth", block: "center" });
      }
    }
  };

  return (
    <div className="min-h-screen bg-[#070104] text-[#E5E7EB] antialiased selection:bg-wine-900 selection:text-white font-sans">
      
      {/* 1. HEADER / NAVBAR */}
      <header className="sticky top-0 z-40 bg-[#070104]/90 backdrop-blur-md border-b border-wine-950/40 transition-all">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-xl bg-wine-800 flex items-center justify-center text-white shadow-sm shadow-wine-900/30">
              <Mic className="w-4.5 h-4.5" />
            </div>
            <div>
              <span className="font-display font-black text-lg tracking-tight text-white block">NotiqAI</span>
              <span className="text-[9px] text-[#FF9EBA] -mt-1 block font-mono font-medium">AI SPEECH LAB</span>
            </div>
          </div>

          <div className="hidden md:flex items-center gap-6 text-sm font-medium text-neutral-400">
            <a href="#muammo" className="hover:text-wine-400 transition">Nutq muammolari</a>
            <a href="#imkoniyatlar" className="hover:text-wine-400 transition">Imkoniyatlar</a>
            <a href="#kimlar-uchun" className="hover:text-wine-400 transition">Kimlar uchun?</a>
            <a href="#qanday-ishlaydi" className="hover:text-wine-400 transition">Qanday ishlaydi?</a>
          </div>

          <div className="flex items-center gap-3">
            <span className="hidden sm:inline-flex items-center gap-1.5 text-xs text-emerald-400 bg-emerald-950/45 px-2.5 py-1 rounded-full border border-emerald-900/40 font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Ro'yxatdan o'tish shart emas
            </span>
            
            <button
              id="header_cta_btn"
              onClick={handleMainCTA}
              className="bg-wine-800 hover:bg-wine-700 text-white text-xs font-bold px-4 py-2.5 rounded-xl transition-all shadow-sm shadow-wine-900/20 active:scale-95"
            >
              Bepul sinab ko'rish
            </button>
          </div>
        </div>
      </header>

      {/* 2. HERO SECTION */}
      <section className="relative pt-8 pb-16 lg:pt-16 lg:pb-24 overflow-hidden bg-gradient-to-b from-[#13040C] via-[#070104] to-[#070104]">
        
        {/* Subtle decorative background elements */}
        <div className="absolute top-1/4 left-0 w-72 h-72 bg-wine-900/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-10 right-0 w-80 h-80 bg-pink-950/20 rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
            
            {/* Left Content Column */}
            <div className="lg:col-span-7 space-y-6 text-center lg:text-left">
              
              {/* Funnel Intent Badges */}
              <div className="inline-flex flex-wrap justify-center lg:justify-start items-center gap-2.5">
                <span className="bg-wine-800 text-white text-[11px] font-extrabold px-3 py-1 rounded-full uppercase tracking-wider shadow-sm border border-wine-700/50">
                  🔥 Reklama maxsus taklifi
                </span>
                <span className="bg-wine-950/60 text-[#FFA1BC] text-[11px] font-bold px-3 py-1 rounded-full border border-wine-900/40 flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-rose-500 animate-ping" />
                  Bepul AI Tahlili (5 Daqiqa)
                </span>
              </div>

              {/* Main Headline */}
              <h1 className="font-display font-black text-3xl sm:text-4xl lg:text-[46px] leading-[1.15] text-white tracking-tight">
                Nutqingiz va ovozingizni <span className="text-wine-400 relative inline-block">AI orqali 5 daqiqada<span className="absolute bottom-1 left-0 w-full h-1 bg-wine-500/80 rounded-full" /></span> tekshirib ko‘ring
              </h1>

              {/* Subheadline */}
              <p className="text-neutral-300 text-base sm:text-lg max-w-xl mx-auto lg:mx-0 leading-relaxed">
                NotiqAI ovozingiz, talaffuzingiz, pauzalaringiz, parazit so‘zlaringiz va fikr yetkazishingizni chuqur tahlil qilib, shaxsiy rivojlanish hisobotingizni beradi.
              </p>

              {/* Primary & Secondary Call to Actions */}
              <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-3.5 pt-2">
                <button
                  id="hero_primary_cta"
                  onClick={() => handleStartTest("speech", "speech_test_click")}
                  className="w-full sm:w-auto bg-wine-800 hover:bg-wine-700 text-white font-bold text-sm px-8 py-4 rounded-2xl transition-all shadow-lg shadow-wine-900/30 hover:-translate-y-0.5 active:translate-y-0 flex items-center justify-center gap-2 group"
                >
                  <Mic className="w-4.5 h-4.5" />
                  <span>Bepul tahlil olish</span>
                  <ChevronRight className="w-4.5 h-4.5 group-hover:translate-x-0.5 transition-transform" />
                </button>

                <button
                  id="hero_secondary_cta"
                  onClick={() => handleStartTest("observation", "observation_test_click")}
                  className="w-full sm:w-auto bg-[#13050F] hover:bg-[#1C0816] text-neutral-200 font-bold text-sm px-6 py-4 rounded-2xl border border-wine-950/80 transition-all shadow-xs flex items-center justify-center gap-2 group hover:border-purple-900/60"
                >
                  <Eye className="w-4.5 h-4.5 text-purple-400" />
                  <span>Kuzatuvchanlik testini topshirish</span>
                </button>
              </div>

              {/* Low Friction Proof */}
              <div className="pt-2 flex flex-wrap justify-center lg:justify-start items-center gap-x-5 gap-y-2 text-xs text-neutral-400 font-medium">
                <span className="flex items-center gap-1.5">
                  <Check className="w-4.5 h-4.5 text-emerald-500" />
                  Ro‘yxatdan o‘tmasdan ham sinab ko‘rish mumkin
                </span>
                <span className="hidden sm:inline-block w-1.5 h-1.5 rounded-full bg-neutral-700" />
                <span className="flex items-center gap-1.5">
                  <Check className="w-4.5 h-4.5 text-emerald-500" />
                  100% xavfsiz audio yozuv
                </span>
              </div>

              {/* Instantly loaded conversion proof highlights */}
              <div className="pt-6 grid grid-cols-3 gap-4 border-t border-wine-950/40 max-w-md mx-auto lg:mx-0 text-left">
                <div>
                  <div className="font-display font-black text-xl text-wine-400">5 daqiqa</div>
                  <div className="text-[10px] text-neutral-400 font-medium uppercase tracking-wider">Tezkor natija</div>
                </div>
                <div>
                  <div className="font-display font-black text-xl text-wine-400">0% xavf</div>
                  <div className="text-[10px] text-neutral-400 font-medium uppercase tracking-wider">Ro'yxatdan o'tmasdan</div>
                </div>
                <div>
                  <div className="font-display font-black text-xl text-wine-400">AI Tahlil</div>
                  <div className="text-[10px] text-neutral-400 font-medium uppercase tracking-wider">Chuqur diagnostika</div>
                </div>
              </div>

            </div>

            {/* Right Column: Dynamic Interactive iPhone Simulator */}
            <div className="lg:col-span-5 relative" ref={emulatorSectionRef}>
              
              {/* Sparkle callout */}
              <div className="absolute -top-6 -left-6 z-20 bg-[#160511] p-3 rounded-2xl border border-wine-900/50 shadow-md flex items-center gap-2.5 max-w-[200px] animate-bounce text-white">
                <div className="w-8 h-8 rounded-lg bg-wine-950 flex items-center justify-center text-wine-300">
                  <Sparkles className="w-4 h-4" />
                </div>
                <div className="text-[10.5px] leading-tight font-bold text-neutral-200">
                  Pastda bepul sinab ko'ring!
                </div>
              </div>

              {/* iPhone container with gradient backlights */}
              <div className="absolute inset-0 bg-gradient-to-tr from-wine-600/10 to-purple-500/10 rounded-[50px] blur-2xl scale-95 pointer-events-none" />
              
              <PhoneEmulator
                initialTest={activeEmulatorTest}
                onTrackEvent={trackEvent}
              />
            </div>

          </div>
        </div>
      </section>

      {/* 3. PROBLEM SECTION */}
      <section id="muammo" className="py-16 bg-[#0B0206] border-y border-wine-950/40">
        <div className="max-w-4xl mx-auto px-4 sm:px-6">
          <div className="text-center space-y-4 max-w-2xl mx-auto mb-12">
            <span className="text-xs font-bold text-wine-300 bg-wine-950/65 px-3 py-1 rounded-full uppercase tracking-wider border border-wine-900/30">
              Muammo nimada?
            </span>
            <h2 className="font-display font-black text-2xl sm:text-3xl text-white">
              Gapirish oson. Ta’sirli gapirish esa alohida ko‘nikma.
            </h2>
            <p className="text-neutral-300 text-sm sm:text-base leading-relaxed">
              Ko‘pchilik odamlar o‘z nutqidagi xatolarni sezmaydi: ortiqcha pauzalar, parazit so‘zlar, ishonchsiz ovoz yoki fikrni chalkash yetkazish. NotiqAI sizga nutqingizni chetdan ko‘rgandek xolis baholashga yordam beradi.
            </p>
          </div>

          {/* Comparison Split Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
            {/* Bad communication state */}
            <div className="bg-[#11040A]/60 p-6 rounded-3xl border border-wine-950/40 shadow-xs relative overflow-hidden group">
              <div className="absolute top-0 left-0 w-1.5 h-full bg-neutral-700" />
              <div className="flex items-center gap-2 text-neutral-400 mb-4">
                <AlertTriangle className="w-5 h-5 text-neutral-500" />
                <span className="font-display font-bold text-xs uppercase tracking-wider">Odatdagi chalkash nutq</span>
              </div>
              <ul className="space-y-3 text-xs text-neutral-300 font-medium">
                <li className="flex items-start gap-2">
                  <span className="text-rose-500 mt-0.5 shrink-0">✕</span>
                  <span>Har 10 ta gapda "haligi", "xo'sh", "ya'ni" kabi parazit so'zlar.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-rose-500 mt-0.5 shrink-0">✕</span>
                  <span>Tez gapirish yoki hayajon tufayli so'zlar va harflarni yutib yuborish.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-rose-500 mt-0.5 shrink-0">✕</span>
                  <span>Monoton, past ohangda gapirish — tinglovchini tezda charchatadi.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-rose-500 mt-0.5 shrink-0">✕</span>
                  <span>Noadekvat, noo'rin tana tili yoki inson his-tuyg'ularini mutlaqo sezmaslik.</span>
                </li>
              </ul>
            </div>

            {/* Premium state with NotiqAI */}
            <div className="bg-[#1A0510]/80 p-6 rounded-3xl border border-wine-900/30 shadow-md relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1.5 h-full bg-wine-600" />
              <div className="flex items-center gap-2 text-wine-300 mb-4">
                <CheckCircle2 className="w-5 h-5 text-wine-400" />
                <span className="font-display font-bold text-xs uppercase tracking-wider text-wine-300">NotiqAI tahlilidan so'ng</span>
              </div>
              <ul className="space-y-3 text-xs text-neutral-200 font-medium">
                <li className="flex items-start gap-2">
                  <span className="text-wine-400 mt-0.5 shrink-0">✓</span>
                  <span>Parazit so'zlarsiz ravon muloqot va toza nutq darajasi.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-wine-400 mt-0.5 shrink-0">✓</span>
                  <span>Diksiya va intonatsiyani matn tinish belgilariga qarab boshqarish siri.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-wine-400 mt-0.5 shrink-0">✓</span>
                  <span>Mijoz yoki rahbar eshitganda ishonch uyg'otadigan chuqur ohang barqarorligi.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-wine-400 mt-0.5 shrink-0">✓</span>
                  <span>Tana tili va noverbal harakatlarni aniq o'qib, vaziyatni boshqarish ko'nikmasi.</span>
                </li>
              </ul>
            </div>
          </div>

        </div>
      </section>

      {/* 4. FEATURES SECTION (3 THINGS TO TRY) */}
      <section id="imkoniyatlar" className="py-16 sm:py-20 bg-[#070104]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center space-y-3 max-w-2xl mx-auto mb-12">
            <span className="text-xs font-bold text-wine-300 bg-wine-950/65 px-3 py-1 rounded-full uppercase tracking-wider border border-wine-900/30">
              Sizga taklifimiz
            </span>
            <h2 className="font-display font-black text-2xl sm:text-3xl text-white">
              Bugun 3 ta narsani bepul sinab ko‘ring
            </h2>
            <p className="text-neutral-400 text-sm">
              Pastdagi kartalardan birini bosing va o'ng tarafdagi (yoki mobil qurilmangizdagi) interaktiv simulyatorda testni darhol boshlang:
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            {/* Feature 1 */}
            <button
              onClick={() => handleStartTest("speech", "speech_test_click")}
              className="text-left bg-[#13050E] p-6 rounded-3xl border border-wine-950/80 shadow-sm hover:border-wine-800 hover:shadow-lg hover:shadow-wine-950/20 transition group"
            >
              <div className="w-12 h-12 rounded-2xl bg-wine-950 text-wine-300 flex items-center justify-center mb-5 group-hover:bg-wine-900 transition">
                <Mic className="w-6 h-6" />
              </div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-display font-bold text-base text-white">Nutq tahlili</h3>
                <span className="text-[10px] bg-emerald-950/60 text-emerald-300 px-2 py-0.5 rounded font-bold font-mono">POPULAR</span>
              </div>
              <p className="text-xs text-neutral-400 leading-relaxed mb-4">
                O‘zingiz haqingizda 2 daqiqa gapiring va AI nutqingizni tahlil qilib, xatolaringizni belgilab beradi.
              </p>
              <span className="text-xs font-bold text-wine-300 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Yozuvni boshlash <ChevronRight className="w-3.5 h-3.5" />
              </span>
            </button>

            {/* Feature 2 */}
            <button
              onClick={() => handleStartTest("voice", "voice_test_click")}
              className="text-left bg-[#13050E] p-6 rounded-3xl border border-wine-950/80 shadow-sm hover:border-pink-900/60 hover:shadow-lg hover:shadow-wine-950/20 transition group"
            >
              <div className="w-12 h-12 rounded-2xl bg-pink-950 text-pink-400 flex items-center justify-center mb-5 group-hover:bg-pink-900 transition">
                <MessageSquare className="w-6 h-6" />
              </div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-display font-bold text-base text-white">Ovozni tekshirish</h3>
                <span className="text-[10px] bg-pink-950/65 text-pink-300 px-2 py-0.5 rounded font-bold font-mono">DIKSIYA</span>
              </div>
              <p className="text-xs text-neutral-400 leading-relaxed mb-4">
                Berilgan muloqot matnini o‘qing va AI talaffuz, ohang, tezlik hamda diksiya aniqligi bo‘yicha aniq baholaydi.
              </p>
              <span className="text-xs font-bold text-pink-400 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Matnni o'qish <ChevronRight className="w-3.5 h-3.5" />
              </span>
            </button>

            {/* Feature 3 */}
            <button
              onClick={() => handleStartTest("observation", "observation_test_click")}
              className="text-left bg-[#13050E] p-6 rounded-3xl border border-wine-950/80 shadow-sm hover:border-purple-900/60 hover:shadow-lg hover:shadow-wine-950/20 transition group"
            >
              <div className="w-12 h-12 rounded-2xl bg-purple-950 text-purple-400 flex items-center justify-center mb-5 group-hover:bg-purple-900 transition">
                <Eye className="w-6 h-6" />
              </div>
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-display font-bold text-base text-white">Kuzatuvchanlik testi</h3>
                <span className="text-[10px] bg-purple-950/65 text-purple-300 px-2 py-0.5 rounded font-bold font-mono">PSIXOLOGIK</span>
              </div>
              <p className="text-xs text-neutral-400 leading-relaxed mb-4">
                Insonlarning yashirin tana tili, ko'z imo-ishoralari va mimikalarini qanchalik to'g'ri o'qiy olishingizni sinang.
              </p>
              <span className="text-xs font-bold text-purple-400 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                Viktorinani boshlash <ChevronRight className="w-3.5 h-3.5" />
              </span>
            </button>

          </div>
        </div>
      </section>

      {/* 5. RESULT SECTION */}
      <section className="py-16 bg-gradient-to-br from-wine-950 to-wine-900 text-white relative overflow-hidden">
        
        {/* Background blobs */}
        <div className="absolute top-0 right-0 w-64 h-64 bg-wine-500/10 rounded-full blur-2xl pointer-events-none" />
        <div className="absolute bottom-0 left-10 w-96 h-96 bg-pink-500/5 rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            
            <div className="lg:col-span-6 space-y-5">
              <span className="text-[10px] font-black tracking-widest text-wine-300 uppercase bg-wine-900/60 border border-wine-800/40 px-3 py-1 rounded-full">
                Sizning natijangiz
              </span>
              <h2 className="font-display font-black text-2xl sm:text-3xl tracking-tight">
                5 daqiqadan keyin nimalarni bilasiz?
              </h2>
              <p className="text-wine-100/80 text-sm leading-relaxed max-w-md">
                Interaktiv testlarni topshirgandan so'ng, sizga NotiqAI platformasi va eng mukammal audio-vizual baholash tizimi yordamdir:
              </p>
              <div className="pt-2">
                <button
                  onClick={handleMainCTA}
                  className="bg-white hover:bg-wine-50 text-wine-950 font-bold text-xs px-6 py-3.5 rounded-xl transition shadow-md flex items-center gap-1.5 active:scale-98"
                >
                  O'z tahlilingizni ko'rish
                  <ChevronRight className="w-4 h-4 text-wine-950" />
                </button>
              </div>
            </div>

            <div className="lg:col-span-6 bg-[#16040F]/80 border border-wine-900/30 p-6 sm:p-8 rounded-3xl shadow-xl backdrop-blur-xs space-y-4">
              
              {/* Result checklist list */}
              {[
                { title: "Ovozingiz qanchalik ishonchli eshitilishi", desc: "Ovoz chastotalari va titrash diapazoni aniqligi tahlili." },
                { title: "Nutqingizdagi pauza va parazit so‘zlar", desc: "Siz bilmagan 'haligi', 'xo'sh' kabi to'ldiruvchi so'zlarning to'liq soni." },
                { title: "Fikrlaringiz qanchalik tartibli yetkazilishi", desc: "Mantiqiy izchillik va bog'lanish samaradorligi ballari." },
                { title: "Talaffuzingizdagi xatolar", desc: "Qaysi so'z va bo'g'inlarda tutilayotganligingiz bo'yicha vizual ko'rsatuv." },
                { title: "Kuzatuvchanlik darajangiz", desc: "Suhbatdosh hissiyotlarini tana tiliga asosan topish darajangiz." }
              ].map((item, index) => (
                <div key={index} className="flex items-start gap-3 border-b border-wine-950/40 pb-3 last:border-0 last:pb-0">
                  <div className="w-5 h-5 rounded-full bg-emerald-950/60 text-emerald-400 flex items-center justify-center shrink-0 mt-0.5 border border-emerald-900/30">
                    <Check className="w-3.5 h-3.5" />
                  </div>
                  <div>
                    <h4 className="text-xs sm:text-sm font-bold text-white">{item.title}</h4>
                    <p className="text-[10.5px] text-wine-200/80 leading-snug mt-0.5">{item.desc}</p>
                  </div>
                </div>
              ))}

            </div>

          </div>
        </div>
      </section>

      {/* 6. AUDIENCE (KIMLAR UCHUN?) SECTION */}
      <section id="kimlar-uchun" className="py-16 sm:py-20 bg-[#0B0206]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          
          <div className="text-center space-y-3 max-w-2xl mx-auto mb-12">
            <span className="text-xs font-bold text-wine-300 bg-wine-950/65 px-3 py-1 rounded-full uppercase tracking-wider border border-wine-900/30">
              Segmentatsiya
            </span>
            <h2 className="font-display font-black text-2xl sm:text-3xl text-white">
              Bu kimlar uchun eng kerakli?
            </h2>
            <p className="text-neutral-400 text-sm">
              NotiqAI faqatgina ma'ruzachilar uchun emas, u muloqot orqali muvaffaqiyatga intiladigan barcha uchun zarurdir:
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
            
            {[
              {
                title: "Sotuv menejerlari",
                desc: "Mijozlarni telefonda yoki uchrashuvda ishontirish, e'tirozlar bilan samarali ishlash va savdoni 2 baravargacha oshirish uchun.",
                icon: <TrendingUp className="w-5 h-5" />
              },
              {
                title: "Rahbarlar va tadbirkorlar",
                desc: "Jamoani ilhomlantiruvchi nutq so'zlash, investorlar oldida prezentatsiyalarni yuqori darajada himoya qilish va liderlik qilish uchun.",
                icon: <Award className="w-5 h-5" />
              },
              {
                title: "Talabalar",
                desc: "Imtihonlarni yuqori baholarga topshirish, diplom ishi himoyasida dadil turish va kelajakdagi ish suhbatlarida mukammal ko'rinish uchun.",
                icon: <Users className="w-5 h-5" />
              },
              {
                title: "Kontent yaratuvchilar",
                desc: "Podkastlar, YouTube videolar yoki Reels yozishda aniq, dinamik va zeriktirmaydigan tarzda gapirish ko'nikmasini shakllantirish uchun.",
                icon: <Flame className="w-5 h-5" />
              },
              {
                title: "Prezentatsiyaga tayyorlanayotganlar",
                desc: "Ma'suliyatli chiqishlardan oldin hayajonni jilovlash, vaqt o'lchoviga (taymerga) rioya qilish va nutqni oldindan sinab olish uchun.",
                icon: <Smartphone className="w-5 h-5" />
              }
            ].map((card, index) => (
              <div key={index} className="bg-[#13050E] p-5 rounded-3xl border border-wine-950/80 shadow-3xs hover:border-wine-800 transition-all">
                <div className="w-10 h-10 rounded-xl bg-wine-950 text-wine-300 flex items-center justify-center mb-4 border border-wine-900/30">
                  {card.icon}
                </div>
                <h3 className="font-display font-bold text-xs sm:text-sm text-white mb-1.5">{card.title}</h3>
                <p className="text-[11px] text-neutral-400 leading-relaxed font-medium">{card.desc}</p>
              </div>
            ))}

          </div>
        </div>
      </section>

      {/* 7. WORKFLOW (QANDAY ISHLAYDI?) SECTION */}
      <section id="qanday-ishlaydi" className="py-16 bg-[#070104] border-t border-wine-950/40">
        <div className="max-w-4xl mx-auto px-4 sm:px-6">
          
          <div className="text-center space-y-3 max-w-2xl mx-auto mb-14">
            <span className="text-xs font-bold text-wine-300 bg-wine-950/65 px-3 py-1 rounded-full uppercase tracking-wider border border-wine-900/30">
              Ishlash tartibi
            </span>
            <h2 className="font-display font-black text-2xl sm:text-3xl text-white">
              Qanday ishlaydi?
            </h2>
            <p className="text-neutral-400 text-sm">
              Sizga hech qanday murakkab qurilma yoki alohida mikrosxema shart emas. Hammasi 3 ta oddiy qadamda amalga oshiriladi:
            </p>
          </div>

          <div className="relative border-l-2 border-wine-950/60 pl-6 sm:pl-8 space-y-12 max-w-lg mx-auto">
            
            {/* Step 1 */}
            <div className="relative">
              <span className="absolute -left-[38px] sm:-left-[46px] top-0 w-8 h-8 rounded-full bg-wine-800 text-white font-bold text-xs flex items-center justify-center border-4 border-[#070104] shadow-sm">
                1
              </span>
              <h3 className="font-display font-bold text-sm sm:text-base text-white mb-1">
                Test turini tanlang
              </h3>
              <p className="text-xs text-neutral-400 leading-relaxed font-medium">
                Foydalanuvchi nutq tahlili, ovoz tekshiruvi yoki kuzatuvchanlik testini (psychological quiz) tanlaydi.
              </p>
            </div>

            {/* Step 2 */}
            <div className="relative">
              <span className="absolute -left-[38px] sm:-left-[46px] top-0 w-8 h-8 rounded-full bg-wine-800 text-white font-bold text-xs flex items-center justify-center border-4 border-[#070104] shadow-sm">
                2
              </span>
              <h3 className="font-display font-bold text-sm sm:text-base text-white mb-1">
                2 daqiqa gapiring yoki matnni o‘qing
              </h3>
              <p className="text-xs text-neutral-400 leading-relaxed font-medium">
                Siz tanlagan mashq turiga ko'ra mikrofoningiz yoqiladi va berilgan amaliyotni bajarasiz yoki quiz savollariga javob berasiz.
              </p>
            </div>

            {/* Step 3 */}
            <div className="relative">
              <span className="absolute -left-[38px] sm:-left-[46px] top-0 w-8 h-8 rounded-full bg-wine-800 text-white font-bold text-xs flex items-center justify-center border-4 border-[#070104] shadow-sm">
                3
              </span>
              <h3 className="font-display font-bold text-sm sm:text-base text-white mb-1">
                AI tahlilini oling
              </h3>
              <p className="text-xs text-neutral-400 leading-relaxed font-medium">
                Foydalanuvchi bir necha soniya ichida o'z xatolari, ball ko'rsatkichi va ovozni kuchaytirish bo'yicha amaliy maslahatlarni ko'radi.
              </p>
            </div>

          </div>
        </div>
      </section>

      {/* 8. FINAL CTA SECTION */}
      <section className="py-20 bg-gradient-to-b from-[#180410] to-[#070104] text-[#E5E7EB] relative overflow-hidden text-center border-t border-wine-950/40">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 relative z-10 space-y-6">
          <span className="text-[11px] font-extrabold text-[#FFA1BC] uppercase tracking-widest bg-wine-950 border border-wine-900/30 px-3 py-1 rounded-full">
            Notiqlik cho'qqisiga birinchi qadam
          </span>
          <h2 className="font-display font-black text-3xl sm:text-4xl text-white max-w-xl mx-auto tracking-tight">
            Nutqingiz qanday eshitilishini bilmoqchimisiz?
          </h2>
          <p className="text-neutral-300 text-sm sm:text-base max-w-md mx-auto leading-relaxed">
            Telefoningizdan shunchaki 2 daqiqa gapiring va AI tahlilini oling. Mutlaqo tekin va xavfsiz.
          </p>

          <div className="pt-2">
            <button
              onClick={() => handleStartTest("speech", "main_cta_click")}
              className="bg-wine-800 hover:bg-wine-700 text-white font-bold text-sm px-10 py-4 rounded-2xl transition shadow-lg shadow-wine-900/30 inline-flex items-center gap-2 group hover:-translate-y-0.5 active:translate-y-0"
            >
              <Mic className="w-4.5 h-4.5" />
              <span>Bepul testni boshlash</span>
              <ChevronRight className="w-4.5 h-4.5 group-hover:translate-x-0.5 transition-transform" />
            </button>
          </div>

          <p className="text-[11px] text-neutral-400 font-semibold">
            Ro‘yxatdan o‘tish yo‘q • 5 daqiqada yakunlanadi
          </p>
        </div>
      </section>

      {/* 9. FOOTER */}
      <footer className="bg-[#070104] text-neutral-400 py-12 border-t border-wine-950/50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6 pb-8 border-b border-wine-950/40">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-wine-800 flex items-center justify-center text-white">
                <Mic className="w-3.5 h-3.5" />
              </div>
              <span className="font-display font-bold text-white text-base">NotiqAI</span>
            </div>
            <div className="flex flex-wrap justify-center gap-6 text-xs font-medium text-neutral-500">
              <span className="hover:text-wine-400 cursor-pointer transition">Foydalanish qoidalari</span>
              <span className="hover:text-wine-400 cursor-pointer transition">Maxfiylik siyosati</span>
              <span className="hover:text-wine-400 cursor-pointer transition">Koll-markaz</span>
              <span className="hover:text-wine-400 cursor-pointer transition">Toshkent, O'zbekiston</span>
            </div>
          </div>
          <div className="pt-8 flex flex-col sm:flex-row items-center justify-between text-[11px] text-neutral-500 font-medium">
            <p>© 2026 NotiqAI Laboratory. Barcha huquqlar himoyalangan.</p>
            <p className="mt-2 sm:mt-0">O'zbekistonda yoshlar uchun ta'limni osonlashtirish loyihasi.</p>
          </div>
        </div>
      </footer>

      {/* 10. STICKY BOTTOM MOBILE CTA */}
      {isScrolledPastHero && (
        <div className="fixed bottom-0 left-0 w-full bg-[#070104]/95 backdrop-blur-md border-t border-wine-950/40 p-3 flex items-center justify-between md:hidden z-30 shadow-[0_-8px_30px_rgba(0,0,0,0.4)] animate-slide-up">
          <div className="text-left pl-1">
            <span className="text-[9px] font-bold text-emerald-400 bg-emerald-950/50 px-1.5 py-0.2 rounded inline-block border border-emerald-900/30">
              MUTLAQO BEPUL
            </span>
            <div className="text-[11px] font-black text-white mt-0.5">NotiqAI Testi</div>
          </div>
          
          <button
            onClick={() => handleStartTest("speech", "main_cta_click")}
            className="bg-wine-800 hover:bg-wine-700 text-white font-bold text-xs px-5 py-3 rounded-xl transition shadow-md active:scale-95 flex items-center gap-1.5"
          >
            <Mic className="w-4 h-4" />
            <span>Bepul testni boshlash</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* 11. MOBILE DRAWERS / MODAL OVERLAY SHEET */}
      {isMobileDrawerOpen && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-xs flex items-end justify-center md:hidden">
          <div className="bg-[#0B0206] w-full max-h-[90vh] rounded-t-[32px] flex flex-col overflow-hidden relative shadow-2xl border-t border-wine-950/40 animate-slide-up">
            
            {/* Drawer top close drag bar */}
            <div className="h-6 flex items-center justify-center relative bg-[#13050E]/60">
              <div className="w-12 h-1 rounded-full bg-wine-900/50" />
              <button
                onClick={() => setIsMobileDrawerOpen(false)}
                className="absolute right-4 top-1 p-1 text-neutral-400 hover:text-white hover:bg-wine-950 rounded-full transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Mobile Emulator container */}
            <div className="flex-1 overflow-y-auto p-4 bg-[#070104]">
              <PhoneEmulator
                initialTest={activeEmulatorTest}
                onTrackEvent={trackEvent}
                onCloseMobile={() => setIsMobileDrawerOpen(false)}
              />
            </div>

            {/* Close footer */}
            <div className="p-3 bg-[#0B0206] border-t border-wine-950/40 text-center">
              <button
                onClick={() => setIsMobileDrawerOpen(false)}
                className="w-full py-2.5 text-xs text-neutral-400 font-semibold hover:bg-wine-950 hover:text-white rounded-xl transition"
              >
                Kuzatuvni yopish (Sahifaga qaytish)
              </button>
            </div>

          </div>
        </div>
      )}

      {/* 12. EVENT TRACKER CONSOLE (DESKTOP) */}
      <TrackingConsole
        events={events}
        onClear={() => setEvents([])}
      />

    </div>
  );
}
