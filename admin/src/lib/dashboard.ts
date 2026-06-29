import { useQueries, type UseQueryResult } from "@tanstack/react-query";
import { api } from "./api";
import type {
  AdminCourse,
  ClientRow,
  Curator,
  Homework,
  Page,
  Payment,
  PushNotification,
  Stats,
} from "./types";

// ─── Composite dashboard queries ────────────────────────────────────────────
//
// Each dashboard fetches everything in a single parallel batch via useQueries,
// so the UI never has to wait sequentially.

export type AdminDashboardQueries = readonly [
  UseQueryResult<Stats, unknown>,
  UseQueryResult<Page<ClientRow>, unknown>,
  UseQueryResult<Homework[], unknown>,
  UseQueryResult<Page<Payment>, unknown>,
  UseQueryResult<PushNotification[], unknown>,
  UseQueryResult<AdminCourse[], unknown>,
  UseQueryResult<Curator[], unknown>,
];

export function useAdminDashboard(): AdminDashboardQueries {
  return useQueries({
    queries: [
      {
        queryKey: ["admin", "stats"],
        queryFn: async () => (await api.get<Stats>("/admin/stats")).data,
      },
      {
        queryKey: ["admin", "dashboard-recent-clients", 6],
        queryFn: async () =>
          (
            await api.get<Page<ClientRow>>("/admin/clients", {
              params: { size: 6 },
            })
          ).data,
      },
      {
        queryKey: ["admin", "dashboard-homeworks", "submitted"],
        queryFn: async () =>
          (
            await api.get<Homework[]>("/admin/homeworks", {
              params: { status: "submitted" },
            })
          ).data,
      },
      {
        queryKey: ["admin", "dashboard-payments", 8],
        queryFn: async () =>
          (
            await api.get<Page<Payment>>("/admin/payments", {
              params: { size: 8, page: 1 },
            })
          ).data,
      },
      {
        queryKey: ["admin", "dashboard-push", 5],
        queryFn: async () =>
          (await api.get<PushNotification[]>("/admin/push")).data,
        select: (rows: PushNotification[]) => rows.slice(0, 5),
      },
      {
        queryKey: ["admin", "courses"],
        queryFn: async () =>
          (await api.get<AdminCourse[]>("/admin/courses")).data,
      },
      {
        queryKey: ["admin", "curators"],
        queryFn: async () => (await api.get<Curator[]>("/admin/curators")).data,
      },
    ],
  }) as unknown as AdminDashboardQueries;
}

export type CuratorDashboardQueries = readonly [
  UseQueryResult<Stats, unknown>,
  UseQueryResult<Homework[], unknown>,
  UseQueryResult<Homework[], unknown>,
  UseQueryResult<AdminCourse[], unknown>,
  UseQueryResult<Page<ClientRow>, unknown>,
];

export function useCuratorDashboard(): CuratorDashboardQueries {
  return useQueries({
    queries: [
      {
        queryKey: ["admin", "stats"],
        queryFn: async () => (await api.get<Stats>("/admin/stats")).data,
      },
      {
        queryKey: ["admin", "dashboard-homeworks", "submitted"],
        queryFn: async () =>
          (
            await api.get<Homework[]>("/admin/homeworks", {
              params: { status: "submitted" },
            })
          ).data,
      },
      {
        queryKey: ["admin", "dashboard-homeworks", "reviewed"],
        queryFn: async () =>
          (
            await api.get<Homework[]>("/admin/homeworks", {
              params: { status: "reviewed" },
            })
          ).data,
      },
      {
        queryKey: ["admin", "courses"],
        queryFn: async () =>
          (await api.get<AdminCourse[]>("/admin/courses")).data,
      },
      {
        queryKey: ["admin", "dashboard-leaderboard", 20],
        queryFn: async () =>
          (
            await api.get<Page<ClientRow>>("/admin/clients", {
              params: { size: 20 },
            })
          ).data,
      },
    ],
  }) as unknown as CuratorDashboardQueries;
}
