// ─────────────────────────────────────────────
//  API response types (snake_case mirrors)
// ─────────────────────────────────────────────

export interface User {
  id: string;
  full_name: string | null;
  email: string | null;
  phone: string | null;
  role: "user" | "admin" | "curator";
  avatar_url: string | null;
  city: string | null;
}

export interface TokenPair {
  access_token: string;
  refresh_token: string;
}

export interface AuthResult {
  is_new_user: boolean;
  tokens: TokenPair;
}

export interface OtpCheckResponse {
  valid: boolean;
  ttl: number;
}

export interface PhoneExistsResponse {
  exists: boolean;
  has_password: boolean;
}

// ── Courses ──────────────────────────────────

export interface Lesson {
  id: string;
  title: string;
  description: string | null;
  order_index: number;
  video_url: string | null;
  duration_sec: number;
  is_voice_exercise: boolean;
  voice_exercise_prompt: string | null;
  is_demo: boolean;
}

export interface Course {
  id: string;
  title: string;
  description: string | null;
  cover_url: string | null;
  price: number | string;
  level: string;
  lessons: Lesson[];
  created_at?: string;
}

export interface LessonQuestion {
  id: string;
  question: string;
  options: string[];
  order_index: number;
}

export interface LessonDetail {
  id: string;
  title: string;
  description: string | null;
  video_url: string | null;
  duration_sec: number;
  is_voice_exercise: boolean;
  voice_exercise_prompt: string | null;
  is_demo: boolean;
  is_completed: boolean;
  auto_score: number | null;
  questions: LessonQuestion[];
}

export interface EnrolledLesson {
  lesson_id: string;
  title: string;
  order_index: number;
  duration_sec: number;
  is_voice_exercise: boolean;
  is_completed: boolean;
  auto_score: number | null;
}

export interface Enrollment {
  id: string;
  course_id: string;
  status: string;
  progress_pct: number;
}

export interface CourseProgress {
  enrolled: boolean;
  enrollment_id: string | null;
  status: string | null;
  progress_pct: number | null;
  enrolled_at: string | null;
  has_pending_order: boolean;
  lessons: EnrolledLesson[];
}

export interface QuizResult {
  score: number;
  correct: number;
  total: number;
  passed: boolean;
}

export interface Homework {
  id: string;
  status: string;
  submission_text: string | null;
  submission_url: string | null;
  curator_score: number | null;
  curator_feedback: string | null;
  reviewed_at: string | null;
  created_at: string;
}

export interface EnrollmentStatusResponse {
  has_active_enrollment: boolean;
  is_staff: boolean;
}

// ── Audiobooks ───────────────────────────────

export interface AudiobookPage {
  page_number: number;
  content: string | null;
  audio_url: string | null;
}

export interface Audiobook {
  id: string;
  title: string;
  author: string | null;
  cover_url: string | null;
  description: string | null;
  category: string | null;
  audio_url: string | null;
  is_free: boolean;
  price: number | string;
  total_pages: number;
  pages: AudiobookPage[];
  created_at?: string;
}

export interface AudiobookAccess {
  state: "granted" | "locked";
  reason: "free" | "purchased" | "pending" | "none";
  has_pending_order: boolean;
}

// ── Orders / payments ────────────────────────

export type OrderPurpose = "course" | "audiobook";
export type OrderPaymentMethod = "uzum" | "uzum_nasiya" | "cash";
export type OrderStatus = "pending" | "approved" | "rejected";

export interface Order {
  id: string;
  user_id: string;
  purpose: OrderPurpose;
  course_id: string | null;
  audiobook_id: string | null;
  target_title: string | null;
  amount: number | string;
  currency: string;
  payment_method: OrderPaymentMethod;
  status: OrderStatus;
  payment_proof_url: string | null;
  admin_note: string | null;
  reviewed_at: string | null;
  created_at: string;
}

export interface Page<T> {
  items: T[];
  total: number;
  page: number;
  size: number;
}

export interface PaymentInitiateResponse {
  payment_id: string;
  redirect_url: string;
  status: string;
  requires_registration: boolean;
}

// ── Quizzes ──────────────────────────────────

export interface Quiz {
  id: string;
  title: string;
  description: string | null;
  difficulty: string;
  status: string;
  category: string;
  question_count: number;
  created_at: string;
  cover_image_url: string | null;
  video_url: string | null;
}

export interface QuizDetail extends Quiz {
  questions: { question: string; options: string[] }[];
}

export interface QuizAttempt {
  id: string;
  quiz_id: string;
  user_id: string;
  answers: number[];
  score: number;
  correct_count: number;
  total_count: number;
}

// ── Practicums ───────────────────────────────

export interface Practicum {
  id: string;
  title: string;
  description: string | null;
  category: string | null;
  expert_text: string | null;
  expert_audio_url: string | null;
  is_free: boolean;
  price: number | string;
  status: string;
  created_at: string;
}

export interface PracticumSubmission {
  id: string;
  practicum_id: string;
  audio_url: string | null;
  transcript: string | null;
  overall_score: number | null;
  status: string;
  created_at: string;
  accuracy_score?: number | null;
  word_errors?: WordError[] | null;
  word_analysis?: Record<string, unknown> | null;
  char_stats?: Record<string, unknown> | null;
  phoneme_errors?: unknown[] | null;
  summary?: string | null;
}

// ── Speech / voice ───────────────────────────

export interface PronunciationReference {
  id: string;
  title: string;
  text: string;
  difficulty: "easy" | "medium" | "hard";
  language: string;
  reference_audio_url: string | null;
}

export interface WordError {
  word: string;
  error: string;
}

export interface SpeechAnalysis {
  id: string;
  status: string;
  transcript: string | null;
  duration_sec: number;
  overall_score: number | null;
  meaning_score: number | null;
  fluency_score: number | null;
  filler_words: Record<string, number | string> | null;
  pauses: unknown[] | null;
  info_balance: string | null;
  summary: string | null;
  details: Record<string, unknown> | null;
  created_at: string;
}

export interface VoiceAnalysis {
  id: string;
  reference_id: string | null;
  reference_text: string;
  transcript: string;
  audio_url: string | null;
  status: string;
  accuracy_score: number | null;
  overall_score: number | null;
  word_errors: WordError[] | null;
  word_analysis: unknown[] | null;
  char_stats: Record<string, unknown> | null;
  phoneme_errors: unknown[] | null;
  summary: string | null;
  recommendations: string[] | null;
  created_at: string;
}

// ── Observation ──────────────────────────────

export interface ObservationTest {
  id: string;
  title: string;
  prompt: string;
  category: string;
  media_type: "image" | "video";
  media_url: string | null;
  options: string[] | null;
  order_index: number;
}

export interface ObservationAttempt {
  id: string;
  score: number | null;
  summary: string | null;
  analysis: string | null;
  completed_at: string | null;
  created_at: string;
}

// ── Profile ──────────────────────────────────

export interface Certificate {
  id: string;
  course_id: string;
  course_title: string;
  serial_number: string;
  pdf_url: string | null;
  grade: number | null;
  issued_at: string;
}

export interface CertificateRequest {
  id: string;
  course_id: string;
  course_title: string;
  full_name: string;
  status: "pending" | "approved" | "rejected";
  rejection_reason: string | null;
  created_at: string;
  reviewed_at: string | null;
}

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  audience: string;
  sent_at: string | null;
  created_at: string;
}

// ── Support ──────────────────────────────────

export interface SupportMessage {
  id: string;
  user_id: string;
  text: string;
  is_from_user: boolean;
  sent_by: string | null;
  created_at: string;
}
