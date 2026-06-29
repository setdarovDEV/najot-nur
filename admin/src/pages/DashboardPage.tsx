import { useAuth } from "../lib/auth";
import { AdminDashboard } from "../components/dashboard/AdminDashboard";
import { CuratorDashboard } from "../components/dashboard/CuratorDashboard";

export function DashboardPage() {
  const { role } = useAuth();
  return role === "curator" ? <CuratorDashboard /> : <AdminDashboard />;
}
