import { Navigate, Route, Routes } from "react-router-dom";

import { useAuth } from "./lib/auth";
import { Layout } from "./components/Layout";
import { LoginPage } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { ClientsPage } from "./pages/ClientsPage";
import { ClientDetailPage } from "./pages/ClientDetailPage";
import { HomeworksPage } from "./pages/HomeworksPage";
import { AudiobooksPage } from "./pages/AudiobooksPage";
import { NotificationsPage } from "./pages/NotificationsPage";
import { PaymentsPage } from "./pages/PaymentsPage";
import { OrdersPage } from "./pages/OrdersPage";
import { VideoLessonsPage } from "./pages/VideoLessonsPage";
import { CuratorsPage } from "./pages/CuratorsPage";
import { SupportChatsPage } from "./pages/SupportChatsPage";
import { ReferencesPage } from "./pages/ReferencesPage";
import { PracticumsPage } from "./pages/PracticumsPage";
import { QuizzesPage } from "./pages/QuizzesPage";
import { CertificateRequestsPage } from "./pages/CertificateRequestsPage";

export default function App() {
  const { isAuthed, perms } = useAuth();

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

        {/* Admin-only routes */}
        {perms.canManageClients && (
          <Route path="clients" element={<ClientsPage />} />
        )}
        {perms.canManageClients && (
          <Route path="clients/:id" element={<ClientDetailPage />} />
        )}
        {perms.canManageCurators && (
          <Route path="curators" element={<CuratorsPage />} />
        )}
        {perms.canSendPush && (
          <Route path="notifications" element={<NotificationsPage />} />
        )}
        {perms.canViewReports && (
          <Route path="payments" element={<PaymentsPage />} />
        )}
        {perms.canViewReports && (
          <Route path="orders" element={<OrdersPage />} />
        )}

        {/* Curator + admin routes (content management) */}
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
