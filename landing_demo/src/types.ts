export interface QuizQuestion {
  id: number;
  question: string;
  options: {
    key: string;
    text: string;
    isCorrect: boolean;
  }[];
  explanation: string;
}

export interface TestResult {
  overallScore: number;
  metrics: {
    label: string;
    score: number;
    description: string;
  }[];
  fillerWords: {
    word: string;
    count: number;
  }[];
  feedback: string;
  accentTitle: string;
}

export interface TrackingEvent {
  id: string;
  name: "speech_test_click" | "voice_test_click" | "observation_test_click" | "main_cta_click";
  timestamp: string;
  metadata: Record<string, any>;
}
