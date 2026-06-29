import { Navigate, Route, Routes } from "react-router-dom";

import { useAuth } from "./lib/auth";
import { Layout } from "./components/Layout";
import { LoginPage } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { HomeworksPage } from "./pages/HomeworksPage";
import { AudiobooksPage } from "./pages/AudiobooksPage";
import { VideoLessonsPage } from "./pages/VideoLessonsPage";
import { SupportChatsPage } from "./pages/SupportChatsPage";
import { ReferencesPage } from "./pages/ReferencesPage";
import { PracticumsPage } from "./pages/PracticumsPage";
import { QuizzesPage } from "./pages/QuizzesPage";
import { CertificateRequestsPage } from "./pages/CertificateRequestsPage";

export default function App() {
  const { isAuthed } = useAuth();

  if (!isAuthed) {
    return (
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    );
  }

  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<DashboardPage />} />
        <Route path="homeworks" element={<HomeworksPage />} />
        <Route path="certificate-requests" element={<CertificateRequestsPage />} />
        <Route path="references" element={<ReferencesPage />} />
        <Route path="practicums" element={<PracticumsPage />} />
        <Route path="quizzes" element={<QuizzesPage />} />
        <Route path="audiobooks" element={<AudiobooksPage />} />
        <Route path="video-lessons" element={<VideoLessonsPage />} />
        <Route path="support-chats" element={<SupportChatsPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Route>
      <Route path="/login" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
