import { useQueries, type UseQueryResult } from "@tanstack/react-query";
import { api } from "./api";
import type {
  AdminCourse,
  ClientRow,
  Homework,
  Page,
  Stats,
} from "./types";

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
        queryKey: ["curator", "stats"],
        queryFn: async () => (await api.get<Stats>("/admin/stats")).data,
      },
      {
        queryKey: ["curator", "dashboard-homeworks", "submitted"],
        queryFn: async () =>
          (
            await api.get<Homework[]>("/admin/homeworks", {
              params: { status: "submitted" },
            })
          ).data,
      },
      {
        queryKey: ["curator", "dashboard-homeworks", "reviewed"],
        queryFn: async () =>
          (
            await api.get<Homework[]>("/admin/homeworks", {
              params: { status: "reviewed" },
            })
          ).data,
      },
      {
        queryKey: ["curator", "courses"],
        queryFn: async () =>
          (await api.get<AdminCourse[]>("/admin/courses")).data,
      },
      {
        queryKey: ["curator", "dashboard-leaderboard", 20],
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
