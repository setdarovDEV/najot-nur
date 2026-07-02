import React, { useState, useEffect, useRef } from "react";
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
  Clock,
  Smartphone,
  CheckCircle2,
  ChevronLeft,
  XCircle,
  HelpCircle
} from "lucide-react";
import { QUIZ_QUESTIONS, MOCK_SPEECH_RESULT, MOCK_VOICE_RESULT } from "../data";
import { TestResult } from "../types";

interface PhoneEmulatorProps {
  initialTest?: "speech" | "voice" | "observation" | null;
  onTrackEvent: (eventName: "speech_test_click" | "voice_test_click" | "observation_test_click" | "main_cta_click", metadata: any) => void;
  onCloseMobile?: () => void;
}

export default function PhoneEmulator({ initialTest, onTrackEvent, onCloseMobile }: PhoneEmulatorProps) {
  // Navigation states: 'home' | 'speech_intro' | 'speech_rec' | 'speech_analyzing' | 'speech_res' | 'voice_intro' | 'voice_rec' | 'voice_analyzing' | 'voice_res' | 'quiz_intro' | 'quiz_q' | 'quiz_res'
  const [screen, setScreen] = useState<string>("home");
  
  // Quiz specific states
  const [currentQIndex, setCurrentQIndex] = useState(0);
  const [selectedOption, setSelectedOption] = useState<string | null>(null);
  const [isAnswerSubmitted, setIsAnswerSubmitted] = useState(false);
  const [quizScore, setQuizScore] = useState(0);

  // Recording states
  const [isRecording, setIsRecording] = useState(false);
  const [recordDuration, setRecordDuration] = useState(0);
  const [waveHeights, setWaveHeights] = useState<number[]>(Array(18).fill(8));
  const [analyzingProgress, setAnalyzingProgress] = useState(0);
  const [analyzingText, setAnalyzingText] = useState("Audio to'lqin yozib olinmoqda...");

  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const waveRef = useRef<NodeJS.Timeout | null>(null);
  const progressRef = useRef<NodeJS.Timeout | null>(null);

  // Sync with initial test request from landing_demo page CTAs
  useEffect(() => {
    if (initialTest === "speech") {
      startSpeechTestFlow();
    } else if (initialTest === "voice") {
      startVoiceTestFlow();
    } else if (initialTest === "observation") {
      startQuizFlow();
    }
  }, [initialTest]);

  // Clean timers
  useEffect(() => {
    return () => {
      stopRecordingTimers();
      if (progressRef.current) clearInterval(progressRef.current);
    };
  }, []);

  const stopRecordingTimers = () => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (waveRef.current) clearInterval(waveRef.current);
    setIsRecording(false);
  };

  // Soundwave animation simulation
  const startRecordingTimers = () => {
    setRecordDuration(0);
    setIsRecording(true);
    
    // Timer
    timerRef.current = setInterval(() => {
      setRecordDuration(prev => {
        if (prev >= 8) { // Auto finish after 8 seconds for fast landing_demo page experience
          stopRecordingTimers();
          goToAnalyzing();
          return 8;
        }
        return prev + 1;
      });
    }, 1000);

    // Wave animations
    waveRef.current = setInterval(() => {
      setWaveHeights(prev => prev.map(() => Math.floor(Math.random() * 32) + 6));
    }, 110);
  };

  const goToAnalyzing = () => {
    const isVoice = screen.startsWith("voice");
    setScreen(isVoice ? "voice_analyzing" : "speech_analyzing");
    setAnalyzingProgress(0);
    
    const statuses = [
      "Audio to'lqini tahlil qilinmoqda...",
      "Ortiqcha pauza va parazit so'zlar hisoblanmoqda...",
      "Ovoz aniqligi va intonatsiyasi baholanmoqda...",
      "Shaxsiy tavsiyalar shakllantirilmoqda..."
    ];

    let currentStep = 0;
    setAnalyzingText(statuses[0]);

    progressRef.current = setInterval(() => {
      setAnalyzingProgress(prev => {
        if (prev >= 100) {
          clearInterval(progressRef.current!);
          setScreen(isVoice ? "voice_res" : "speech_res");
          return 100;
        }
        
        const nextProgress = prev + 10;
        if (nextProgress === 25) { setAnalyzingText(statuses[1]); }
        else if (nextProgress === 55) { setAnalyzingText(statuses[2]); }
        else if (nextProgress === 80) { setAnalyzingText(statuses[3]); }
        
        return nextProgress;
      });
    }, 300);
  };

  // Launchers
  const startSpeechTestFlow = () => {
    onTrackEvent("speech_test_click", { test_type: "speech_analysis", source: "emulator" });
    setScreen("speech_intro");
  };

  const startVoiceTestFlow = () => {
    onTrackEvent("voice_test_click", { test_type: "voice_reading_check", source: "emulator" });
    setScreen("voice_intro");
  };

  const startQuizFlow = () => {
    onTrackEvent("observation_test_click", { test_type: "observation_test", source: "emulator" });
    setScreen("quiz_intro");
    setCurrentQIndex(0);
    setSelectedOption(null);
    setIsAnswerSubmitted(false);
    setQuizScore(0);
  };

  // Quiz Navigation
  const handleAnswerSelect = (optionKey: string) => {
    if (isAnswerSubmitted) return;
    setSelectedOption(optionKey);
  };

  const submitAnswer = () => {
    if (!selectedOption || isAnswerSubmitted) return;
    setIsAnswerSubmitted(true);
    
    const currentQ = QUIZ_QUESTIONS[currentQIndex];
    const isCorrect = currentQ.options.find(o => o.key === selectedOption)?.isCorrect || false;
    
    if (isCorrect) {
      setQuizScore(prev => prev + 1);
    }
  };

  const nextQuestion = () => {
    setSelectedOption(null);
    setIsAnswerSubmitted(false);
    if (currentQIndex < QUIZ_QUESTIONS.length - 1) {
      setCurrentQIndex(prev => prev + 1);
    } else {
      setScreen("quiz_res");
    }
  };

  const getQuizRank = (score: number) => {
    if (score === 4) return { title: "Sherlok Xolms darajasi", desc: "Siz insonlarning mimika, ko'z qorachig'i va jismoniy holatidagi eng mayda o'zgarishlarni ham benuqson ilg'aysiz. Tabiiy kuzatuvchilik qobiliyatingiz juda yuqori!" };
    if (score === 3) return { title: "Tajribali amaliyotchi", desc: "Noverbal signallarning ko'pini to'g'ri tushunasiz. Kundalik suhbatlarda odamlarning hissiyotlarini yaxshi sezasiz va tahlil qila olasiz." };
    if (score >= 1) return { title: "O'rtacha kuzatuvchi", desc: "Ko'p tarqalgan mimika va ishoralarni sezasiz, ammo chuqurroq noverbal signallarni tahlil qilishda qiynalasiz. Mashqlar yordam beradi." };
    return { title: "Boshlovchi", desc: "Ko'pincha odamlarning haqiqiy niyatlarini yoki ichki hissiyotlarini e'tiborsiz qoldirasiz. NotiqAI yordamida tana tilini o'rganishni boshlang!" };
  };

  return (
    <div className="relative mx-auto w-full max-w-[320px] h-[640px] bg-neutral-950 rounded-[44px] p-3 shadow-[0_25px_60px_-15px_rgba(139,15,58,0.4)] border-4 border-neutral-800 flex flex-col overflow-hidden">
      {/* Phone Screen Dynamic Island / Camera Notch */}
      <div className="absolute top-4 left-1/2 -translate-x-1/2 w-28 h-5 bg-neutral-900 rounded-full z-30 flex items-center justify-between px-3">
        <div className="w-1.5 h-1.5 rounded-full bg-blue-500/80" />
        <div className="w-8 h-1 bg-neutral-800 rounded-full" />
        <div className="w-2 h-2 rounded-full bg-neutral-950 border border-neutral-800" />
      </div>

      {/* Internal Phone Screen */}
      <div className="relative flex-1 bg-[#0B0207] rounded-[32px] overflow-hidden flex flex-col text-neutral-200 select-none">
        
        {/* Screen Status Bar */}
        <div className="h-8 pt-2 px-6 flex justify-between items-center bg-[#13050F]/70 text-[11px] font-medium text-neutral-400 z-10">
          <span>12:30</span>
          <div className="flex items-center gap-1.5">
            <span className="text-[9px] bg-wine-950 text-wine-300 px-1 py-0.2 rounded font-mono font-bold border border-wine-900/30">5G</span>
            <div className="w-5 h-2.5 border border-neutral-700 rounded-sm p-0.5 flex items-center">
              <div className="h-full w-4 bg-neutral-400 rounded-2xs" />
            </div>
          </div>
        </div>

        {/* App Mini Header */}
        <div className="h-12 border-b border-wine-950/40 px-4 flex items-center justify-between bg-[#0B0207] z-10">
          {screen !== "home" ? (
            <button
              onClick={() => {
                stopRecordingTimers();
                setScreen("home");
              }}
              className="p-1 text-wine-400 hover:bg-wine-950/50 rounded-full transition flex items-center text-[11px] font-semibold gap-0.5"
            >
              <ChevronLeft className="w-4 h-4" />
              <span>Orqaga</span>
            </button>
          ) : (
            <div className="flex items-center gap-1.5">
              <div className="w-6 h-6 rounded-lg bg-wine-800 flex items-center justify-center">
                <Mic className="w-3.5 h-3.5 text-white" />
              </div>
              <span className="font-display font-bold text-sm tracking-tight text-white">NotiqAI</span>
            </div>
          )}

          <div className="flex items-center gap-2">
            <span className="inline-block w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-[10px] font-medium text-neutral-500 font-mono">LIVE SIM</span>
            {onCloseMobile && (
              <button onClick={onCloseMobile} className="md:hidden text-neutral-400 hover:text-neutral-200">
                <X className="w-4 h-4" />
              </button>
            )}
          </div>
        </div>

        {/* Dynamic Screen Viewport */}
        <div className="flex-1 overflow-y-auto custom-scrollbar bg-[#0D0308] flex flex-col">
          
          {/* SCREEN: HOME */}
          {screen === "home" && (
            <div className="p-4 flex flex-col flex-1">
              <div className="text-center my-3">
                <span className="bg-wine-950/80 text-wine-300 text-[10px] font-bold px-2 py-0.5 rounded-full border border-wine-900/30">
                  ⚡ BEPUL MASHQLAR
                </span>
                <h3 className="font-display font-bold text-base text-white mt-2">
                  Nutq va Ovoz Laboratoriyasi
                </h3>
                <p className="text-xs text-neutral-400 mt-1 max-w-[240px] mx-auto">
                  Ro'yxatdan o'tmasdan quyidagi 3 ta testni bepul sinab ko'ring:
                </p>
              </div>

              {/* Home options list */}
              <div className="space-y-2.5 mt-3 flex-1">
                {/* Option 1: Speech analysis */}
                <button
                  onClick={startSpeechTestFlow}
                  className="w-full text-left bg-[#180713]/85 p-3.5 rounded-2xl border border-wine-950/50 shadow-xs hover:border-wine-800 hover:bg-[#250D1D]/90 transition group"
                >
                  <div className="flex items-start gap-3">
                    <div className="w-9 h-9 rounded-xl bg-wine-900/45 flex items-center justify-center text-wine-300 group-hover:bg-wine-800 transition">
                      <Mic className="w-5 h-5" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <h4 className="font-bold text-xs text-white">1. Nutq tahlili (AI)</h4>
                        <span className="text-[9px] font-bold text-emerald-400 bg-emerald-950/60 px-1.5 py-0.2 rounded border border-emerald-900/30">BEPUL</span>
                      </div>
                      <p className="text-[11px] text-neutral-400 mt-0.5 leading-tight">
                        O'zingiz haqingizda gapiring, AI pauzalar va so'zlarni tahlil qiladi.
                      </p>
                    </div>
                  </div>
                </button>

                {/* Option 2: Voice Check */}
                <button
                  onClick={startVoiceTestFlow}
                  className="w-full text-left bg-[#180713]/85 p-3.5 rounded-2xl border border-wine-950/50 shadow-xs hover:border-wine-800 hover:bg-[#250D1D]/90 transition group"
                >
                  <div className="flex items-start gap-3">
                    <div className="w-9 h-9 rounded-xl bg-pink-950/50 flex items-center justify-center text-pink-400 group-hover:bg-pink-900/70 transition">
                      <MessageSquare className="w-5 h-5" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <h4 className="font-bold text-xs text-white">2. Ovozni tekshirish</h4>
                        <span className="text-[9px] font-bold text-emerald-400 bg-emerald-950/60 px-1.5 py-0.2 rounded border border-emerald-900/30">5 DAQIQA</span>
                      </div>
                      <p className="text-[11px] text-neutral-400 mt-0.5 leading-tight">
                        Matnni o'qing, AI talaffuz, ohang va tezlik bo'yicha baho beradi.
                      </p>
                    </div>
                  </div>
                </button>

                {/* Option 3: Observation Check */}
                <button
                  onClick={startQuizFlow}
                  className="w-full text-left bg-[#180713]/85 p-3.5 rounded-2xl border border-wine-950/50 shadow-xs hover:border-wine-800 hover:bg-[#250D1D]/90 transition group"
                >
                  <div className="flex items-start gap-3">
                    <div className="w-9 h-9 rounded-xl bg-purple-950/50 flex items-center justify-center text-[#E0B0FF] group-hover:bg-purple-900/70 transition">
                      <Eye className="w-5 h-5" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <h4 className="font-bold text-xs text-white">3. Kuzatuvchanlik testi</h4>
                        <span className="text-[9px] font-bold text-purple-300 bg-purple-950/60 px-1.5 py-0.2 rounded border border-purple-900/30">QUIZ</span>
                      </div>
                      <p className="text-[11px] text-neutral-400 mt-0.5 leading-tight">
                        Insonlarning tana tili va mimikalarini tushunishni tekshiring.
                      </p>
                    </div>
                  </div>
                </button>
              </div>

              {/* Bottom badge */}
              <div className="mt-auto py-3 text-center border-t border-wine-950/50">
                <p className="text-[10px] text-neutral-500 flex items-center justify-center gap-1 font-medium">
                  <Check className="w-3.5 h-3.5 text-wine-500" />
                  Mikrofoningizni sinab ko'ring (Yozuv butunlay xavfsiz)
                </p>
              </div>
            </div>
          )}

          {/* SCREEN: SPEECH INTRO */}
          {screen === "speech_intro" && (
            <div className="p-4 flex flex-col flex-1 justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-wine-50 text-wine-900 flex items-center justify-center mx-auto my-3 border border-wine-100">
                  <Mic className="w-6 h-6" />
                </div>
                <h3 className="font-display font-bold text-base text-neutral-900 text-center">
                  Nutq Tahlili (AI)
                </h3>
                <p className="text-xs text-neutral-500 mt-2 text-center leading-relaxed">
                  Ushbu sinov darsida siz o'zingiz haqingizda taxminan <strong className="text-neutral-800">2 daqiqa</strong> erkin gapirishingiz kerak bo'ladi.
                </p>

                <div className="mt-5 bg-white p-4 rounded-2xl border border-neutral-100 space-y-3">
                  <span className="text-[10px] font-bold text-wine-800 bg-wine-50 px-2 py-0.5 rounded-full">
                    Tavsiya etilgan mavzular:
                  </span>
                  <ul className="text-[11px] text-neutral-600 space-y-2 list-disc pl-4 font-medium">
                    <li>Ismingiz, kasbingiz va qiziqishlaringiz</li>
                    <li>Notiqlik ko'nikmasi sizga nima uchun kerak?</li>
                    <li>Suhbat yoki hayotingizdagi qiziq bir voqea</li>
                  </ul>
                </div>
              </div>

              <div className="space-y-2 mt-6">
                <button
                  onClick={() => {
                    setScreen("speech_rec");
                    startRecordingTimers();
                  }}
                  className="w-full bg-wine-900 hover:bg-wine-800 text-white text-xs font-bold py-3 px-4 rounded-xl transition shadow-md active:scale-98 flex items-center justify-center gap-2"
                >
                  <Play className="w-4 h-4 fill-white" />
                  Yozuvni boshlash
                </button>
                <p className="text-[9px] text-center text-neutral-400">
                  Yozuv bosilgach mikrofonga yaqinroq gapiring.
                </p>
              </div>
            </div>
          )}

          {/* SCREEN: SPEECH RECORD */}
          {screen === "speech_rec" && (
            <div className="p-4 flex flex-col flex-1 justify-between items-center">
              <div className="w-full text-center mt-3">
                <span className="bg-rose-50 text-rose-600 text-[10px] font-bold px-2.5 py-0.5 rounded-full border border-rose-100 inline-flex items-center gap-1 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-rose-600" />
                  Yozib olinmoqda (REC)
                </span>
                <p className="text-xs text-neutral-500 mt-2 max-w-[200px] mx-auto leading-tight font-medium">
                  "O'zingiz haqingizda gapiring..."
                </p>
              </div>

              {/* Dynamic simulated wave lines */}
              <div className="h-32 flex items-center justify-center gap-1.5 w-full bg-white rounded-3xl border border-neutral-100 shadow-inner px-4 relative overflow-hidden">
                <div className="absolute top-2 left-3 text-[9px] text-neutral-400 font-mono">Simulated Waveform</div>
                {waveHeights.map((h, i) => (
                  <div
                    key={i}
                    style={{ height: `${h}px` }}
                    className="w-1.5 rounded-full bg-wine-800/80 transition-all duration-100 min-h-[4px]"
                  />
                ))}
              </div>

              <div className="w-full text-center space-y-4">
                <div className="font-mono text-xl font-bold text-neutral-900">
                  00:0{recordDuration}
                  <span className="text-neutral-400 text-sm"> / 00:08s</span>
                </div>

                <button
                  onClick={() => {
                    stopRecordingTimers();
                    goToAnalyzing();
                  }}
                  className="w-16 h-16 rounded-full bg-rose-600 text-white hover:bg-rose-700 transition flex items-center justify-center shadow-lg active:scale-95 mx-auto relative group"
                >
                  <div className="absolute inset-0 rounded-full bg-rose-600 animate-pulse-ring opacity-50" />
                  <div className="w-5 h-5 bg-white rounded-xs z-10" />
                </button>
                <p className="text-[10px] text-neutral-400">
                  Yozib bo'lgach to'xtatish tugmasini bosing
                </p>
              </div>
            </div>
          )}

          {/* SCREEN: ANALYZING STATE */}
          {(screen === "speech_analyzing" || screen === "voice_analyzing") && (
            <div className="p-6 flex flex-col flex-1 justify-center items-center">
              <div className="relative mb-6">
                <div className="w-16 h-16 rounded-full border-4 border-wine-100 border-t-wine-900 animate-spin" />
                <Sparkles className="w-6 h-6 text-wine-900 absolute top-5 left-5 animate-pulse" />
              </div>
              
              <h3 className="font-display font-bold text-sm text-neutral-800 text-center mb-1">
                NotiqAI tahlil qilmoqda...
              </h3>
              
              {/* Progress percentage */}
              <div className="font-mono text-xl font-bold text-wine-900 my-2">
                {analyzingProgress}%
              </div>

              {/* Status bar */}
              <div className="w-full max-w-[200px] h-1.5 bg-neutral-100 rounded-full overflow-hidden mt-1 mb-4">
                <div
                  style={{ width: `${analyzingProgress}%` }}
                  className="h-full bg-wine-900 transition-all duration-200"
                />
              </div>

              <p className="text-xs text-neutral-500 text-center italic max-w-[220px] font-medium animate-pulse">
                {analyzingText}
              </p>
            </div>
          )}

          {/* SCREEN: SPEECH RESULT */}
          {screen === "speech_res" && (
            <div className="p-4 flex flex-col flex-1">
              <div className="text-center">
                <span className="bg-emerald-50 text-emerald-700 text-[10px] font-bold px-2.5 py-0.5 rounded-full border border-emerald-100 inline-flex items-center gap-1">
                  <Award className="w-3.5 h-3.5" />
                  Tahlil yakunlandi!
                </span>
                <h3 className="font-display font-bold text-base text-neutral-900 mt-2">
                  Sizning Nutq Tahlilingiz
                </h3>
                <p className="text-[11px] text-wine-900 font-bold bg-wine-50 px-3 py-1 rounded-full border border-wine-100 inline-block mt-1">
                  🎗️ {MOCK_SPEECH_RESULT.accentTitle}
                </p>
              </div>

              {/* Progress Circle & Score */}
              <div className="my-4 bg-white p-4 rounded-2xl border border-neutral-100 flex items-center justify-between shadow-xs">
                <div>
                  <div className="text-3xl font-display font-bold text-wine-900">
                    {MOCK_SPEECH_RESULT.overallScore}
                    <span className="text-neutral-400 text-xs">/100 ball</span>
                  </div>
                  <p className="text-[10px] text-neutral-500 font-medium mt-1">
                    Umumiy nutq salohiyati ko'rsatkichi
                  </p>
                </div>
                {/* Visual circle progress bar (simulated with SVG) */}
                <div className="relative w-16 h-16 flex items-center justify-center">
                  <svg className="w-full h-full transform -rotate-90">
                    <circle cx="32" cy="32" r="28" stroke="#f3f4f6" strokeWidth="4" fill="transparent" />
                    <circle cx="32" cy="32" r="28" stroke="#8B0F3A" strokeWidth="4" fill="transparent" strokeDasharray="175" strokeDashoffset="28" />
                  </svg>
                  <span className="absolute font-mono font-bold text-sm text-wine-900">84%</span>
                </div>
              </div>

              {/* Metrics Sliders */}
              <div className="space-y-3 bg-white p-4 rounded-2xl border border-neutral-100 shadow-2xs">
                <h4 className="font-bold text-xs text-neutral-800 border-b border-neutral-100 pb-1.5">
                  Asosiy ko'rsatkichlar:
                </h4>
                {MOCK_SPEECH_RESULT.metrics.map((m, idx) => (
                  <div key={idx} className="space-y-1">
                    <div className="flex justify-between items-center text-[10px]">
                      <span className="font-medium text-neutral-700">{m.label.split(" (")[0]}</span>
                      <span className="font-bold text-wine-900">{m.score}/100</span>
                    </div>
                    <div className="w-full h-1 bg-neutral-100 rounded-full">
                      <div
                        style={{ width: `${m.score}%` }}
                        className="h-full bg-wine-900 rounded-full"
                      />
                    </div>
                  </div>
                ))}
              </div>

              {/* Parazit words found */}
              <div className="mt-3 bg-rose-50/50 p-4 rounded-2xl border border-rose-100 shadow-2xs">
                <h4 className="font-bold text-xs text-rose-900 flex items-center gap-1">
                  ⚠️ Parazit so'zlar topildi:
                </h4>
                <div className="flex flex-wrap gap-2 mt-2">
                  {MOCK_SPEECH_RESULT.fillerWords.map((w, idx) => (
                    <span key={idx} className="bg-rose-100/80 text-rose-900 border border-rose-200/50 font-bold text-[10px] px-2 py-0.5 rounded-lg flex items-center gap-1 font-mono">
                      "{w.word}" <span className="bg-rose-950 text-white text-[8px] px-1 rounded-full">{w.count} marta</span>
                    </span>
                  ))}
                </div>
                <p className="text-[10px] text-rose-800/85 mt-2 leading-tight">
                  Tavsiya: Gap orasida to'xtalish bo'lganda 'haligi' demasdan, 1.5 soniyalik pauza qiling. Ovoz yanada ishonchli chiqadi.
                </p>
              </div>

              {/* General Feedback */}
              <div className="mt-3 bg-white p-4 rounded-2xl border border-neutral-100">
                <h4 className="font-bold text-xs text-neutral-800 mb-1">AI Sharhi:</h4>
                <p className="text-[10.5px] text-neutral-600 leading-relaxed italic">
                  "{MOCK_SPEECH_RESULT.feedback}"
                </p>
              </div>

              {/* CTA options */}
              <div className="mt-4 space-y-2 pb-6">
                <button
                  onClick={() => alert("Siz bepul versiyadasiz. To'liq 15 sahifalik PDF hisobot va audio tahlilni olish uchun NotiqAI ilovasini yuklab oling!")}
                  className="w-full bg-wine-900 hover:bg-wine-800 text-white font-bold text-xs py-3 rounded-xl transition flex items-center justify-center gap-2 shadow-md"
                >
                  <Download className="w-3.5 h-3.5" />
                  Hisobotni yuklab olish (PDF)
                </button>
                <button
                  onClick={() => setScreen("home")}
                  className="w-full border border-neutral-200 hover:bg-neutral-100 text-neutral-700 font-bold text-xs py-2.5 rounded-xl transition flex items-center justify-center gap-1.5"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  Qayta urinib ko'rish
                </button>
              </div>
            </div>
          )}

          {/* SCREEN: VOICE INTRO */}
          {screen === "voice_intro" && (
            <div className="p-4 flex flex-col flex-1 justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-pink-50 text-pink-600 flex items-center justify-center mx-auto my-3 border border-pink-100">
                  <MessageSquare className="w-6 h-6" />
                </div>
                <h3 className="font-display font-bold text-base text-neutral-900 text-center">
                  Ovoz va Diksiya Sinovi
                </h3>
                <p className="text-xs text-neutral-500 mt-2 text-center leading-relaxed">
                  Quyidagi jumlani chiroyli intonatsiya va baland ovozda o'qing. AI sizning <strong className="text-neutral-800">talaffuz aniqligi</strong> va <strong className="text-neutral-800">diksiyangizni</strong> baholaydi.
                </p>

                <div className="mt-5 bg-white p-4 rounded-2xl border border-neutral-100 text-center">
                  <span className="text-[9px] font-bold text-pink-700 bg-pink-50 px-2.5 py-0.5 rounded-full mb-2 inline-block">
                    O'qiladigan matn:
                  </span>
                  <p className="text-xs font-semibold text-neutral-800 leading-relaxed italic bg-neutral-50 p-3 rounded-xl border border-neutral-100/50">
                    "Muvaffaqiyatli muloqot siri — gapirayotgan gapimizda emas, balki uni qanday yetkazishimizda va tinglovchini qanchalik his qilishimizda."
                  </p>
                </div>
              </div>

              <div className="space-y-2 mt-6">
                <button
                  onClick={() => {
                    setScreen("voice_rec");
                    startRecordingTimers();
                  }}
                  className="w-full bg-wine-900 hover:bg-wine-800 text-white text-xs font-bold py-3 px-4 rounded-xl transition shadow-md flex items-center justify-center gap-2"
                >
                  <Play className="w-4 h-4 fill-white" />
                  Yozib olishni boshlash
                </button>
                <p className="text-[9px] text-center text-neutral-400">
                  Tayyor bo'lsangiz tugmani bosing va o'qing.
                </p>
              </div>
            </div>
          )}

          {/* SCREEN: VOICE RECORD */}
          {screen === "voice_rec" && (
            <div className="p-4 flex flex-col flex-1 justify-between items-center">
              <div className="w-full text-center mt-3">
                <span className="bg-rose-50 text-rose-600 text-[10px] font-bold px-2.5 py-0.5 rounded-full border border-rose-100 inline-flex items-center gap-1 animate-pulse">
                  <span className="w-1.5 h-1.5 rounded-full bg-rose-600" />
                  Matnni o'qing
                </span>
                
                <div className="bg-white p-4 rounded-2xl border border-neutral-100 my-4 text-center">
                  <p className="text-xs font-semibold text-neutral-800 leading-relaxed italic bg-neutral-50 p-2.5 rounded-xl">
                    "Muvaffaqiyatli muloqot siri — gapirayotgan gapimizda emas, balki uni qanday yetkazishimizda..."
                  </p>
                </div>
              </div>

              {/* Voice bars */}
              <div className="h-16 flex items-end justify-center gap-1.5 w-full bg-white rounded-2xl border border-neutral-100 shadow-inner px-4 relative overflow-hidden my-2">
                {waveHeights.slice(0, 12).map((h, i) => (
                  <div
                    key={i}
                    style={{ height: `${h}px` }}
                    className="w-2 rounded-t-full bg-pink-600/80 transition-all duration-100 min-h-[4px]"
                  />
                ))}
              </div>

              <div className="w-full text-center space-y-3">
                <div className="font-mono text-lg font-bold text-neutral-900">
                  00:0{recordDuration}
                  <span className="text-neutral-400 text-xs"> / 00:08s</span>
                </div>

                <button
                  onClick={() => {
                    stopRecordingTimers();
                    goToAnalyzing();
                  }}
                  className="w-14 h-14 rounded-full bg-rose-600 text-white hover:bg-rose-700 transition flex items-center justify-center shadow-lg active:scale-95 mx-auto relative"
                >
                  <div className="absolute inset-0 rounded-full bg-rose-600 animate-pulse-ring opacity-50" />
                  <div className="w-4.5 h-4.5 bg-white rounded-xs" />
                </button>
                <p className="text-[10px] text-neutral-400">
                  O'qib bo'lgach to'xtatish tugmasini bosing
                </p>
              </div>
            </div>
          )}

          {/* SCREEN: VOICE RESULT */}
          {screen === "voice_res" && (
            <div className="p-4 flex flex-col flex-1">
              <div className="text-center">
                <span className="bg-pink-50 text-pink-700 text-[10px] font-bold px-2.5 py-0.5 rounded-full border border-pink-100 inline-flex items-center gap-1">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  Diksiya tekshirildi!
                </span>
                <h3 className="font-display font-bold text-base text-neutral-900 mt-2">
                  Diksiya va Ovoz Natijalari
                </h3>
                <p className="text-[11px] text-pink-950 font-bold bg-pink-50 px-3 py-1 rounded-full border border-pink-100 inline-block mt-1">
                  🎤 {MOCK_VOICE_RESULT.accentTitle}
                </p>
              </div>

              {/* Progress Circle & Score */}
              <div className="my-3 bg-white p-4 rounded-2xl border border-neutral-100 flex items-center justify-between shadow-xs">
                <div>
                  <div className="text-3xl font-display font-bold text-pink-700">
                    {MOCK_VOICE_RESULT.overallScore}
                    <span className="text-neutral-400 text-xs">/100 ball</span>
                  </div>
                  <p className="text-[10px] text-neutral-500 font-medium mt-1">
                    Talaffuz aniqligi ko'rsatkichi
                  </p>
                </div>
                <div className="relative w-14 h-14 flex items-center justify-center">
                  <svg className="w-full h-full transform -rotate-90">
                    <circle cx="28" cy="28" r="24" stroke="#f3f4f6" strokeWidth="4" fill="transparent" />
                    <circle cx="28" cy="28" r="24" stroke="#D81B52" strokeWidth="4" fill="transparent" strokeDasharray="150" strokeDashoffset="33" />
                  </svg>
                  <span className="absolute font-mono font-bold text-xs text-pink-700">78%</span>
                </div>
              </div>

              {/* Paragraph details highlights */}
              <div className="bg-white p-3.5 rounded-2xl border border-neutral-100 shadow-2xs mb-3">
                <h4 className="font-bold text-[11px] text-neutral-400 uppercase tracking-wider mb-1.5">
                  Talaffuz qilingan matn tahlili:
                </h4>
                <p className="text-xs leading-relaxed font-semibold">
                  <span className="text-emerald-600 bg-emerald-50 px-0.5 rounded">"Muvaffaqiyatli</span>{" "}
                  <span className="text-emerald-600 bg-emerald-50 px-0.5 rounded">muloqot</span>{" "}
                  <span className="text-emerald-600 bg-emerald-50 px-0.5 rounded">siri</span> —{" "}
                  <span className="text-amber-600 bg-amber-50 px-0.5 rounded font-bold" title="Lekin so'zi o'rniga bir oz sekinlashish kuzatildi">gapirayotgan</span>{" "}
                  <span className="text-emerald-600 bg-emerald-50 px-0.5 rounded">gapimizda</span>{" "}
                  <span className="text-rose-600 bg-rose-50 px-0.5 rounded line-through" title="Talaffuz tushunarsizroq bo'ldi">emas,</span>{" "}
                  <span className="text-emerald-600 bg-emerald-50 px-0.5 rounded">balki..."</span>
                </p>
                <div className="flex gap-2.5 mt-2.5 text-[9px] text-neutral-500">
                  <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-emerald-500" /> To'g'ri</span>
                  <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-amber-500" /> Intonatsiya xatosi</span>
                  <span className="flex items-center gap-1"><span className="w-2 h-2 rounded-full bg-rose-500" /> Loyqa talaffuz</span>
                </div>
              </div>

              {/* Metrics Sliders */}
              <div className="space-y-2 bg-white p-4 rounded-2xl border border-neutral-100 shadow-2xs">
                {MOCK_VOICE_RESULT.metrics.map((m, idx) => (
                  <div key={idx} className="space-y-0.5">
                    <div className="flex justify-between items-center text-[10px]">
                      <span className="font-medium text-neutral-600">{m.label.split(" (")[0]}</span>
                      <span className="font-bold text-neutral-800">{m.score}/100</span>
                    </div>
                    <div className="w-full h-1 bg-neutral-100 rounded-full">
                      <div
                        style={{ width: `${m.score}%` }}
                        className="h-full bg-pink-600 rounded-full"
                      />
                    </div>
                  </div>
                ))}
              </div>

              {/* General Feedback */}
              <div className="mt-3 bg-white p-3.5 rounded-2xl border border-neutral-100">
                <h4 className="font-bold text-xs text-neutral-800 mb-0.5">AI Sharhi:</h4>
                <p className="text-[10.5px] text-neutral-600 leading-relaxed italic">
                  "{MOCK_VOICE_RESULT.feedback}"
                </p>
              </div>

              {/* CTA options */}
              <div className="mt-4 space-y-2 pb-6">
                <button
                  onClick={() => alert("Diksiya va ovoz yuksalishi bo'yicha shaxsiy trening dasturini yuklab olish uchun NotiqAI mobil ilovasini yuklab oling.")}
                  className="w-full bg-wine-900 hover:bg-wine-800 text-white font-bold text-xs py-3 rounded-xl transition flex items-center justify-center gap-2 shadow-md"
                >
                  <Download className="w-3.5 h-3.5" />
                  Trening dasturini olish (PDF)
                </button>
                <button
                  onClick={() => setScreen("home")}
                  className="w-full border border-neutral-200 hover:bg-neutral-100 text-neutral-700 font-bold text-xs py-2.5 rounded-xl transition flex items-center justify-center gap-1.5"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  Qayta urinib ko'rish
                </button>
              </div>
            </div>
          )}

          {/* SCREEN: QUIZ INTRO */}
          {screen === "quiz_intro" && (
            <div className="p-4 flex flex-col flex-1 justify-between">
              <div>
                <div className="w-12 h-12 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center mx-auto my-3 border border-purple-100">
                  <Eye className="w-6 h-6" />
                </div>
                <h3 className="font-display font-bold text-base text-neutral-900 text-center">
                  Kuzatuvchanlik Testi
                </h3>
                <p className="text-xs text-neutral-500 mt-2 text-center leading-relaxed">
                  Insonlarning noverbal signallari — tana tili, mimikalar va yashirin harakatlarni qanchalik yaxshi tushunasiz?
                </p>

                <div className="mt-5 bg-white p-4 rounded-2xl border border-neutral-100 space-y-3.5">
                  <div className="flex items-start gap-2 text-xs">
                    <span className="text-purple-600 mt-0.5 font-bold">✓</span>
                    <p className="text-neutral-600"><strong className="text-neutral-800">4 ta savol</strong>: Haqiqiy psixologik ssenariylar</p>
                  </div>
                  <div className="flex items-start gap-2 text-xs">
                    <span className="text-purple-600 mt-0.5 font-bold">✓</span>
                    <p className="text-neutral-600"><strong className="text-neutral-800">Tezkor natija</strong> va chuqur psixologik sharh</p>
                  </div>
                  <div className="flex items-start gap-2 text-xs">
                    <span className="text-purple-600 mt-0.5 font-bold">✓</span>
                    <p className="text-neutral-600">Odamlarning yashirin niyatlarini bilish darajasi</p>
                  </div>
                </div>
              </div>

              <div className="space-y-2 mt-6">
                <button
                  onClick={() => setScreen("quiz_q")}
                  className="w-full bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold py-3 px-4 rounded-xl transition shadow-md flex items-center justify-center gap-1.5"
                >
                  Testni boshlash
                  <ChevronRight className="w-4 h-4" />
                </button>
                <p className="text-[9px] text-center text-neutral-400">
                  Ushbu test shaxsingizni rivojlantirishga yordam beradi.
                </p>
              </div>
            </div>
          )}

          {/* SCREEN: QUIZ QUESTION */}
          {screen === "quiz_q" && (
            <div className="p-4 flex flex-col flex-1 justify-between">
              <div>
                {/* Question Progress bar */}
                <div className="mb-4">
                  <div className="flex justify-between items-center text-[10px] text-neutral-400 mb-1">
                    <span>MIMIKA VA TANA TILI</span>
                    <span className="font-bold text-purple-600">Savol {currentQIndex + 1} / 4</span>
                  </div>
                  <div className="w-full h-1 bg-neutral-100 rounded-full overflow-hidden">
                    <div
                      style={{ width: `${((currentQIndex + 1) / 4) * 100}%` }}
                      className="h-full bg-purple-600 rounded-full"
                    />
                  </div>
                </div>

                <h4 className="font-bold text-xs text-neutral-900 leading-snug">
                  {QUIZ_QUESTIONS[currentQIndex].question}
                </h4>

                {/* Option list */}
                <div className="space-y-2 mt-4">
                  {QUIZ_QUESTIONS[currentQIndex].options.map((option) => {
                    const isSelected = selectedOption === option.key;
                    
                    let buttonClass = "w-full text-left p-3 rounded-xl border text-xs transition-all flex items-start gap-2 ";
                    if (isAnswerSubmitted) {
                      if (option.isCorrect) {
                        buttonClass += "bg-emerald-50 border-emerald-300 text-emerald-900 font-medium";
                      } else if (isSelected) {
                        buttonClass += "bg-rose-50 border-rose-300 text-rose-900";
                      } else {
                        buttonClass += "bg-white border-neutral-100 text-neutral-400";
                      }
                    } else {
                      if (isSelected) {
                        buttonClass += "bg-purple-50 border-purple-400 text-purple-900 font-medium shadow-xs";
                      } else {
                        buttonClass += "bg-white border-neutral-100 text-neutral-700 hover:bg-neutral-50";
                      }
                    }

                    return (
                      <button
                        key={option.key}
                        disabled={isAnswerSubmitted}
                        onClick={() => handleAnswerSelect(option.key)}
                        className={buttonClass}
                      >
                        <span className={`w-5 h-5 rounded-full flex items-center justify-center text-[10px] font-bold shrink-0 ${
                          isSelected ? "bg-purple-600 text-white" : "bg-neutral-100 text-neutral-500"
                        }`}>
                          {option.key}
                        </span>
                        <span className="leading-tight">{option.text}</span>
                      </button>
                    );
                  })}
                </div>

                {/* Question Explanation card */}
                {isAnswerSubmitted && (
                  <div className="mt-4 bg-purple-50/50 p-3.5 rounded-xl border border-purple-100 text-[11px] leading-relaxed text-purple-950 flex gap-2">
                    <Info className="w-4 h-4 text-purple-600 shrink-0 mt-0.5" />
                    <div>
                      <strong className="text-purple-900 block mb-0.5">Tahlil:</strong>
                      {QUIZ_QUESTIONS[currentQIndex].explanation}
                    </div>
                  </div>
                )}
              </div>

              {/* Action buttons */}
              <div className="mt-6">
                {!isAnswerSubmitted ? (
                  <button
                    onClick={submitAnswer}
                    disabled={!selectedOption}
                    className={`w-full py-3 px-4 rounded-xl text-xs font-bold transition shadow-md flex items-center justify-center gap-1.5 ${
                      selectedOption
                        ? "bg-purple-600 hover:bg-purple-700 text-white active:scale-98"
                        : "bg-neutral-200 text-neutral-400 cursor-not-allowed"
                    }`}
                  >
                    Javobni tekshirish
                  </button>
                ) : (
                  <button
                    onClick={nextQuestion}
                    className="w-full bg-purple-600 hover:bg-purple-700 text-white text-xs font-bold py-3 px-4 rounded-xl transition shadow-md active:scale-98 flex items-center justify-center gap-1.5"
                  >
                    {currentQIndex === 3 ? "Natijalarni ko'rish" : "Keyingi savol"}
                    <ChevronRight className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          )}

          {/* SCREEN: QUIZ RESULT */}
          {screen === "quiz_res" && (
            <div className="p-4 flex flex-col flex-1">
              <div className="text-center mt-2">
                <span className="bg-purple-50 text-purple-700 text-[10px] font-bold px-2.5 py-0.5 rounded-full border border-purple-100 inline-flex items-center gap-1">
                  <Award className="w-3.5 h-3.5" />
                  Test nihoyasiga yetdi
                </span>
                <h3 className="font-display font-bold text-base text-neutral-900 mt-2">
                  Kuzatuvchanlik Bahosi
                </h3>
                <p className="text-[11px] text-purple-950 font-bold bg-purple-50 px-3 py-1 rounded-full border border-purple-100 inline-block mt-1">
                  🎯 {getQuizRank(quizScore).title}
                </p>
              </div>

              {/* Progress Circle & Score */}
              <div className="my-4 bg-white p-4 rounded-2xl border border-neutral-100 flex items-center justify-between shadow-xs">
                <div>
                  <div className="text-3xl font-display font-bold text-purple-600">
                    {quizScore} <span className="text-neutral-400 text-xs">/ 4 to'g'ri</span>
                  </div>
                  <p className="text-[10px] text-neutral-500 font-medium mt-1">
                    Sizning to'g'ri javoblaringiz
                  </p>
                </div>
                {/* Visual circle progress bar (simulated with SVG) */}
                <div className="relative w-14 h-14 flex items-center justify-center">
                  <svg className="w-full h-full transform -rotate-90">
                    <circle cx="28" cy="28" r="24" stroke="#f3f4f6" strokeWidth="4" fill="transparent" />
                    <circle
                      cx="28"
                      cy="28"
                      r="24"
                      stroke="#9333ea"
                      strokeWidth="4"
                      fill="transparent"
                      strokeDasharray="150"
                      strokeDashoffset={150 - (150 * (quizScore / 4))}
                    />
                  </svg>
                  <span className="absolute font-mono font-bold text-xs text-purple-600">{Math.round((quizScore / 4) * 100)}%</span>
                </div>
              </div>

              {/* Rank Description */}
              <div className="bg-white p-4 rounded-2xl border border-neutral-100 shadow-2xs">
                <h4 className="font-bold text-xs text-neutral-800 mb-1.5">Sizning noverbal portretingiz:</h4>
                <p className="text-[11px] text-neutral-600 leading-relaxed italic">
                  "{getQuizRank(quizScore).desc}"
                </p>
              </div>

              <div className="bg-purple-50/50 p-4 rounded-2xl border border-purple-100 mt-3">
                <h4 className="font-bold text-xs text-purple-900 mb-1">💡 NotiqAI tavsiyasi:</h4>
                <p className="text-[10px] text-purple-800 leading-relaxed">
                  Tana tili va yuz mimikalarini 100% o'qish hamda ulardan suhbat davomida foydalanish uchun NotiqAI ilovasidagi kundalik interaktiv psixologik darslarni o'tishingiz tavsiya etiladi.
                </p>
              </div>

              {/* CTA options */}
              <div className="mt-5 space-y-2 pb-6">
                <button
                  onClick={() => alert("Muloqot psixologiyasi va kuzatuvchanlik darsligi NotiqAI ilovasida sizga mutlaqo bepul ochiladi!")}
                  className="w-full bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs py-3 rounded-xl transition flex items-center justify-center gap-1.5 shadow-md"
                >
                  <Check className="w-4 h-4" />
                  Kurs darslarini olish (Ilovada)
                </button>
                <button
                  onClick={() => startQuizFlow()}
                  className="w-full border border-neutral-200 hover:bg-neutral-100 text-neutral-700 font-bold text-xs py-2.5 rounded-xl transition flex items-center justify-center gap-1.5"
                >
                  <RotateCcw className="w-3.5 h-3.5" />
                  Testni qaytadan boshlash
                </button>
              </div>
            </div>
          )}

        </div>
        
        {/* Phone Bottom Home Bar Indicator */}
        <div className="h-6 bg-[#0B0207] flex items-center justify-center relative border-t border-wine-950/20">
          <div className="w-24 h-1 bg-[#2E1825] rounded-full" />
        </div>

      </div>
    </div>
  );
}
