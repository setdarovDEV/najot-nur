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
  city: string | null;
  last_speech_score: number | null;
  last_speech_summary: string | null;
}

export interface ClientMapPoint {
  id: string;
  full_name: string | null;
  phone: string | null;
  city: string | null;
  region: string | null;
  country: string | null;
  latitude: number;
  longitude: number;
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
  user_full_name: string | null;
  user_phone: string | null;
  lesson_title: string | null;
  course_title: string | null;
  lesson_video_url: string | null;
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

export interface Payment {
  id: string;
  user_id: string;
  amount: string;
  currency: string;
  provider: "uzum" | "uzum_nasiya" | "atmos";
  status: "pending" | "paid" | "failed" | "refunded";
  purpose: "course" | "audiobook" | "subscription";
  reference_id: string | null;
  external_id: string | null;
  paid_at: string | null;
  created_at: string;
}

export type PaymentStatus = Payment["status"];

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

export interface PushNotification {
  id: string;
  title: string;
  body: string;
  audience: "all" | "course" | "user" | "city";
  target_id: string | null;
  target_city: string | null;
  sent_at: string | null;
  delivered_count: number | null;
  created_at: string;
}

export interface PushStatus {
  enabled: boolean;
  configured: boolean;
  service_account_path: string;
  service_account_exists: boolean;
  project_id: string | null;
  last_error: string | null;
  registered_tokens: number;
  audience_breakdown: {
    all_users: number;
    course_buyers: number;
  };
  hint: string;
}

export interface Order {
  id: string;
  user_id: string;
  user_full_name: string | null;
  user_phone: string | null;
  purpose: "course" | "audiobook";
  course_id: string | null;
  audiobook_id: string | null;
  target_title: string | null;
  amount: string;
  currency: string;
  payment_method: "uzum" | "uzum_nasiya" | "cash" | "gift";
  status: "pending" | "approved" | "rejected";
  payment_proof_url: string | null;
  admin_note: string | null;
  reviewed_at: string | null;
  created_at: string;
}

export interface ClientEnrollment {
  id: string;
  course_id: string;
  course_title: string;
  status: "active" | "completed" | "cancelled";
  progress_pct: number;
  created_at: string;
}

export interface ClientHomework {
  id: string;
  lesson_id: string;
  lesson_title: string;
  course_title: string;
  status: "submitted" | "reviewed" | "returned";
  curator_score: number | null;
  curator_feedback: string | null;
  reviewed_at: string | null;
  created_at: string;
}

export interface Curator {
  id: string;
  full_name: string | null;
  email: string | null;
  is_active: boolean;
  is_verified: boolean;
  created_at: string;
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

export interface StudentStats {
  course: {
    lessons_total: number;
    lessons_completed: number;
    progress_pct: number;
    status: string;
    lessons: {
      title: string;
      order_index: number;
      completed: boolean;
      quiz_score: number | null;
    }[];
  };
  audiobooks: {
    title: string;
    author: string | null;
    current_page: number;
    total_pages: number;
    last_listened_at: string;
  }[];
  practicums: {
    title: string;
    score: number | null;
    status: string;
    submitted_at: string;
  }[];
  speech_analyses: {
    overall_score: number;
    meaning_score: number;
    fluency_score: number;
    summary: string;
    created_at: string;
  }[];
}
