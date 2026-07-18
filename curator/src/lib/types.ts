export interface SupportChatSummary {
  user_id: string;
  full_name: string | null;
  phone: string | null;
  email: string | null;
  last_message: string;
  last_message_at: string;
  unread_count: number;
}

export interface SupportMessage {
  id: string;
  user_id: string;
  text: string;
  is_from_user: boolean;
  sent_by: string | null;
  created_at: string;
}

export interface WsNewMessage {
  event: "new_message";
  message: SupportMessage;
}

export interface WsChatUpdated {
  event: "chat_updated";
  user_id: string;
  last_message: string;
  last_message_at: string;
  unread_count: number;
}

export interface ClientRow {
  id: string;
  full_name: string | null;
  phone: string | null;
  email: string | null;
  is_verified: boolean;
  created_at: string;
  last_speech_score: number | null;
  last_speech_summary: string | null;
}

export interface Page<T> {
  items: T[];
  total: number;
  page: number;
  size: number;
}

export interface Stats {
  users: number;
  audiobooks: number;
  speech_analyses: number;
  pending_homeworks: number;
}

export interface Homework {
  id: string;
  user_id: string;
  lesson_id: string;
  status: "submitted" | "reviewed" | "returned";
  submission_text: string | null;
  submission_url: string | null;
  curator_score: number | null;
  curator_feedback: string | null;
  reviewed_at: string | null;
  created_at: string;
  user_full_name?: string | null;
  user_phone?: string | null;
  lesson_title?: string | null;
}

export interface Audiobook {
  id: string;
  title: string;
  author: string | null;
  slug: string;
  is_free: boolean;
  total_pages: number;
  description: string | null;
  cover_url: string | null;
  audio_url: string | null;
  price: string;
  is_published: boolean;
}

export interface AudiobookPage {
  id: string;
  page_number: number;
  content: string | null;
  audio_url: string | null;
}

export interface AudiobookDetail extends Audiobook {
  pages: AudiobookPage[];
  description: string | null;
  cover_url: string | null;
  price: string;
}

export interface LessonQuestion {
  id: string;
  question: string;
  options: string[];
  correct_index: number;
  order_index: number;
}

export interface AdminLesson {
  id: string;
  title: string;
  description: string | null;
  order_index: number;
  video_url: string | null;
  duration_sec: number;
  is_voice_exercise: boolean;
  voice_exercise_prompt: string | null;
  is_demo: boolean;
  questions: LessonQuestion[];
}

export interface AdminCourse {
  id: string;
  title: string;
  slug: string;
  description: string | null;
  cover_url: string | null;
  price: string;
  level: string;
  is_published: boolean;
  lesson_count: number;
}

export interface AdminCourseDetail extends AdminCourse {
  lessons: AdminLesson[];
}

export interface CertificateRequest {
  id: string;
  user_id: string;
  user_full_name: string | null;
  user_phone: string | null;
  course_id: string;
  course_title: string;
  full_name: string;
  status: "pending" | "approved" | "rejected";
  rejection_reason: string | null;
  created_at: string;
  reviewed_at: string | null;
}

export interface LessonStat {
  title: string;
  order_index: number;
  completed: boolean;
  quiz_score: number | null;
}

export interface AudiobookStat {
  title: string;
  author: string | null;
  current_page: number;
  total_pages: number;
  last_listened_at: string;
}

export interface PracticumStat {
  title: string;
  score: number | null;
  status: string;
  submitted_at: string;
}

export interface PracticumSubmissionCharOp {
  position: number;
  expected_char: string | null;
  spoken_char: string | null;
  operation: "match" | "substitute" | "delete" | "insert" | "transpose";
  phoneme_group?: string;
  penalty?: number;
  tip?: string;
}

export interface PracticumSubmissionWord {
  ref_index?: number;
  reference_word: string;
  spoken_word: string | null;
  is_correct: boolean;
  word_score: number;
  char_ops?: PracticumSubmissionCharOp[];
  ai_comment?: string | null;
  recommendation?: string | null;
}

export interface PracticumSubmission {
  id: string;
  practicum_id: string;
  audio_url: string | null;
  transcript: string | null;
  overall_score: number | null;
  accuracy_score: number | null;
  status: string;
  created_at: string;
  user_full_name?: string | null;
  user_phone?: string | null;
  reference_text?: string | null;
  word_errors?: Array<{ index: number; word: string; error_type: string; note: string | null }> | null;
  word_analysis?: PracticumSubmissionWord[] | null;
  char_stats?: {
    top_problem_chars?: Array<{ char: string; count: number }>;
    phoneme_tips?: Array<{
      char: string;
      tip: string;
      tongue_position?: string;
      practice_words?: string[];
    }>;
    minimal_pairs?: string[];
    error_patterns?: Array<{ pattern: string; count: number }>;
    phoneme_group_accuracy?: Record<string, number>;
  } | null;
  phoneme_errors?: Array<{ word: string; sound: string; note: string }> | null;
  summary?: string | null;
}

export interface SpeechStat {
  overall_score: number | null;
  meaning_score: number | null;
  fluency_score: number | null;
  summary: string | null;
  created_at: string;
}

export interface StudentStats {
  course: {
    lessons_total: number;
    lessons_completed: number;
    progress_pct: number;
    status: string;
    lessons: LessonStat[];
  };
  audiobooks: AudiobookStat[];
  practicums: PracticumStat[];
  speech_analyses: SpeechStat[];
}
