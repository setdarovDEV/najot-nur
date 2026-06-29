import {
  createContext,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { AxiosError } from "axios";
import { api, TOKEN_KEY, isTokenExpired, setUnauthorizedHandler } from "./api";

export type UserRole = "admin" | "curator" | "user";

export interface UserProfile {
  id: string;
  full_name: string | null;
  email: string | null;
  role: UserRole;
  avatar_url: string | null;
}

interface AuthState {
  token: string | null;
  role: UserRole | null;
  user: UserProfile | null;
  isAuthed: boolean;
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
  if (typeof window === "undefined") return null;
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
  // Guard against concurrent /auth/me fetches and double-firing on rapid
  // re-renders or token changes.
  const inflight = useRef<Promise<void> | null>(null);

  function logout() {
    if (typeof window !== "undefined") {
      localStorage.removeItem(TOKEN_KEY);
    }
    setToken(null);
    setRole(null);
    setUser(null);
  }

  async function fetchUser() {
    // De-duplicate: if a fetch is already running, reuse it.
    if (inflight.current) return inflight.current;
    const p = (async () => {
      try {
        const res = await api.get<UserProfile>("/auth/me");
        setUser(res.data);
      } catch (err) {
        // 401 already handled by the global interceptor (calls logout()).
        // For any other failure (network, 5xx), just clear the cached profile
        // so the UI doesn't show a stale name.
        if (err instanceof AxiosError && err.response?.status !== 401) {
          setUser(null);
        }
      }
    })();
    inflight.current = p;
    try {
      await p;
    } finally {
      inflight.current = null;
    }
  }

  // When the API rejects any request with 401 (expired/invalid token), clear the
  // session — App re-renders, `isAuthed` becomes false, and the user lands on /login.
  useEffect(() => {
    setUnauthorizedHandler(logout);
    return () => setUnauthorizedHandler(null);
  }, []);

  useEffect(() => {
    if (token && !user && !inflight.current) {
      void fetchUser();
    }
  }, [token]);

  async function login(email: string, password: string) {
    // Reset cached profile so a previous user's name doesn't flash on the
    // dashboard between login and the /auth/me response.
    setUser(null);
    const res = await api.post("/auth/login", { email, password });
    const access = res.data.access_token as string;
    const parsedRole = parseRole(access);

    if (parsedRole !== "admin") {
      throw new Error("Bu panel faqat adminlar uchun ochiq.");
    }

    localStorage.setItem(TOKEN_KEY, access);
    setToken(access);
    setRole(parsedRole);
    await fetchUser();
  }

  return (
    <AuthContext.Provider
      value={{
        token,
        role,
        user,
        isAuthed: !!token,
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
