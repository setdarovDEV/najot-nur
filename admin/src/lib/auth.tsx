import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { api, TOKEN_KEY, isTokenExpired, setUnauthorizedHandler } from "./api";
import { detectSite, roleErrorForSite } from "./subdomain";

export type UserRole = "admin" | "curator" | "user";

export interface UserProfile {
  id: string;
  full_name: string | null;
  email: string | null;
  role: UserRole;
  avatar_url: string | null;
}

export interface Permissions {
  /** Can upload audiobooks / video lessons and grade homework. */
  canUpload: boolean;
  /** Can publish audiobooks (admin only). */
  canPublish: boolean;
  /** Can manage curators (admin only). */
  canManageCurators: boolean;
  /** Can view payments and read-only access to all sections. */
  canViewReports: boolean;
  /** Can send push notifications. */
  canSendPush: boolean;
  /** Can manage end-users (clients). */
  canManageClients: boolean;
}

function permissionsFor(role: UserRole | null): Permissions {
  const isAdmin = role === "admin";
  const isCurator = role === "curator";
  return {
    canUpload: isCurator || isAdmin,
    canPublish: isAdmin,
    canManageCurators: isAdmin,
    canViewReports: isAdmin,
    canSendPush: isAdmin,
    canManageClients: isAdmin,
  };
}

interface AuthState {
  token: string | null;
  role: UserRole | null;
  user: UserProfile | null;
  isAuthed: boolean;
  perms: Permissions;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  refreshUser: () => Promise<void>;
}

function parseRole(token: string): UserRole | null {
  try {
    const payload = JSON.parse(atob(token.split(".")[1]));
    return (payload.role as UserRole) ?? null;
  } catch {
    return null;
  }
}

const AuthContext = createContext<AuthState | null>(null);

/** Read a non-expired token from storage; clears it if already expired. */
function initialToken(): string | null {
  const t = localStorage.getItem(TOKEN_KEY);
  if (!t) return null;
  if (isTokenExpired(t)) {
    localStorage.removeItem(TOKEN_KEY);
    return null;
  }
  return t;
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(initialToken);
  const [role, setRole] = useState<UserRole | null>(() => {
    const t = token;
    return t ? parseRole(t) : null;
  });
  const [user, setUser] = useState<UserProfile | null>(null);

  function logout() {
    localStorage.removeItem(TOKEN_KEY);
    setToken(null);
    setRole(null);
    setUser(null);
  }

  async function fetchUser() {
    try {
      const res = await api.get<UserProfile>("/auth/me");
      setUser(res.data);
    } catch {
      setUser(null);
    }
  }

  // When the API rejects any request with 401 (expired/invalid token), clear the
  // session — App re-renders, `isAuthed` becomes false, and the user lands on /login.
  useEffect(() => {
    setUnauthorizedHandler(logout);
    return () => setUnauthorizedHandler(null);
  }, []);

  useEffect(() => {
    if (token && !user) {
      void fetchUser();
    }
  }, [token]);

  async function login(email: string, password: string) {
    const res = await api.post("/auth/login", { email, password });
    const access = res.data.access_token as string;
    const parsedRole = parseRole(access);

    // Reject if the server role doesn't match the subdomain (e.g., a curator
    // trying to log in on admin.notiqlik.uz with a valid password).
    const roleErr = roleErrorForSite(parsedRole ?? "", detectSite());
    if (roleErr) throw new Error(roleErr);

    localStorage.setItem(TOKEN_KEY, access);
    setToken(access);
    setRole(parsedRole);
    await fetchUser();
  }

  const perms = permissionsFor(role);
  return (
    <AuthContext.Provider
      value={{
        token,
        role,
        user,
        isAuthed: !!token,
        perms,
        login,
        logout,
        refreshUser: fetchUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthState {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
