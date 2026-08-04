import { Navigate, Route, Routes } from "react-router-dom";
import { useAuth } from "./lib/auth";
import { Layout } from "./components/Layout";

import { LoginPage } from "./pages/auth/LoginPage";
import { RegisterPage } from "./pages/auth/RegisterPage";
import { ForgotPasswordPage } from "./pages/auth/ForgotPasswordPage";

import { HomePage } from "./pages/home/HomePage";
import { CoursesPage } from "./pages/courses/CoursesPage";
import { CourseDetailPage } from "./pages/courses/CourseDetailPage";
import { CourseLearningPage } from "./pages/courses/CourseLearningPage";
import { LessonPage } from "./pages/courses/LessonPage";
import { AudiobooksPage } from "./pages/audiobooks/AudiobooksPage";
import { AudiobookDetailPage } from "./pages/audiobooks/AudiobookDetailPage";
import { QuizzesPage } from "./pages/quizzes/QuizzesPage";
import { QuizPage } from "./pages/quizzes/QuizPage";
import { PracticumsPage } from "./pages/practicums/PracticumsPage";
import { PracticumDetailPage } from "./pages/practicums/PracticumDetailPage";
import { SpeechHubPage } from "./pages/speech/SpeechHubPage";
import { TalkPage } from "./pages/speech/TalkPage";
import { TalkResultPage } from "./pages/speech/TalkResultPage";
import { VoicePage } from "./pages/speech/VoicePage";
import { VoiceResultPage } from "./pages/speech/VoiceResultPage";
import { PracticePage } from "./pages/speech/PracticePage";
import { ObservationPage } from "./pages/observation/ObservationPage";
import { ObservationResultPage } from "./pages/observation/ObservationResultPage";

import { ProfilePage } from "./pages/profile/ProfilePage";
import { ProfileEditPage } from "./pages/profile/ProfileEditPage";
import { HistoryPage } from "./pages/profile/HistoryPage";
import { CertificatesPage } from "./pages/profile/CertificatesPage";
import { OrdersPage } from "./pages/profile/OrdersPage";
import { NotificationsPage } from "./pages/profile/NotificationsPage";
import { SupportChatPage } from "./pages/profile/SupportChatPage";
import { FaqPage } from "./pages/profile/FaqPage";
import { HelpContactPage } from "./pages/profile/HelpContactPage";

function Protected({ children }: { children: React.ReactNode }) {
  const { isAuthed } = useAuth();
  if (!isAuthed) return <Navigate to="/login" replace />;
  return <>{children}</>;
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />

      <Route
        element={
          <Protected>
            <Layout />
          </Protected>
        }
      >
        <Route path="/" element={<HomePage />} />
        <Route path="/courses" element={<CoursesPage />} />
        <Route path="/courses/:id" element={<CourseDetailPage />} />
        <Route path="/courses/:id/learn" element={<CourseLearningPage />} />
        <Route path="/courses/:id/lessons/:lessonId" element={<LessonPage />} />
        <Route path="/audiobooks" element={<AudiobooksPage />} />
        <Route path="/audiobooks/:id" element={<AudiobookDetailPage />} />
        <Route path="/quizzes" element={<QuizzesPage />} />
        <Route path="/quizzes/:id" element={<QuizPage />} />
        <Route path="/practicums" element={<PracticumsPage />} />
        <Route path="/practicums/:id" element={<PracticumDetailPage />} />
        <Route path="/speech" element={<SpeechHubPage />} />
        <Route path="/speech/talk" element={<TalkPage />} />
        <Route path="/speech/talk/result" element={<TalkResultPage />} />
        <Route path="/speech/voice" element={<VoicePage />} />
        <Route path="/speech/voice/result" element={<VoiceResultPage />} />
        <Route path="/speech/practice" element={<PracticePage />} />
        <Route path="/observation" element={<ObservationPage />} />
        <Route path="/observation/result" element={<ObservationResultPage />} />

        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/profile/edit" element={<ProfileEditPage />} />
        <Route path="/profile/history" element={<HistoryPage />} />
        <Route path="/profile/certificates" element={<CertificatesPage />} />
        <Route path="/profile/orders" element={<OrdersPage />} />
        <Route path="/profile/notifications" element={<NotificationsPage />} />
        <Route path="/profile/chat" element={<SupportChatPage />} />
        <Route path="/profile/faq" element={<FaqPage />} />
        <Route path="/profile/help" element={<HelpContactPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
