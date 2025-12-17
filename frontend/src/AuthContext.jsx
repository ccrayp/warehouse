import React, { createContext, useState, useEffect } from "react";
import { apiHost } from "./apiRequest";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [accessToken, setAccessToken] = useState(localStorage.getItem("access_token"));
  const [refreshToken, setRefreshToken] = useState(localStorage.getItem("refresh_token"));
  const [sections, setSections] = useState(JSON.parse(localStorage.getItem("sections") || "[]"));
  const [user, setUser] = useState(JSON.parse(localStorage.getItem("user") || "null"));
  const [role, setRole] = useState(JSON.parse(localStorage.getItem("role") || "null"));
  const [employee_id, setEmployeeId] = useState(JSON.parse(localStorage.getItem("employee_id") || "null"));

  /* =======================
     sync state -> localStorage
     ======================= */
  useEffect(() => {
    accessToken
      ? localStorage.setItem("access_token", accessToken)
      : localStorage.removeItem("access_token");

    refreshToken
      ? localStorage.setItem("refresh_token", refreshToken)
      : localStorage.removeItem("refresh_token");

    localStorage.setItem("sections", JSON.stringify(sections));
    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("role", JSON.stringify(role));
    localStorage.setItem("employee_id", JSON.stringify(employee_id));
  }, [accessToken, refreshToken, sections, user, role, employee_id]);

  /* =======================
     refresh access token
     ======================= */
 let refreshPromise = null;

  const refreshAccessToken = async () => {
    if (!refreshToken) return null;

    if (!refreshPromise) {
      refreshPromise = (async () => {
        try {
          const res = await fetch(`${apiHost}/auth/refresh`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ refresh_token: refreshToken }),
          });

          if (!res.ok) {
            setAccessToken(null);
            setRefreshToken(null);
            return null;
          }

          const data = await res.json();
          if (!data.success) return null;

          setAccessToken(data.data.access_token);
          setRefreshToken(data.data.refresh_token);

          return data.data.access_token;
        } catch (err) {
          console.error("Refresh token error:", err);
          return null;
        } finally {
          refreshPromise = null;
        }
      })();
    }

    return refreshPromise;
  };


  /* =======================
     logout
     ======================= */
  const logout = async () => {
    try {
      if (refreshToken) {
        await fetch(`${apiHost}/auth/logout`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ refresh_token: refreshToken }),
        });
      }
    } catch (err) {
      console.error("Logout error:", err);
    } finally {
      setAccessToken(null);
      setRefreshToken(null);
      setSections([]);
      setUser(null);
      setRole(null);
      setEmployeeId(null);
      localStorage.clear();
    }
  };

  /* =======================
     load user info
     ======================= */
  const loadUser = async (token = accessToken) => {
    if (!token) return;

    try {
      const res = await fetch(`${apiHost}/auth/me`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`,
        },
      });

      if (res.status === 401) {
        const newToken = await refreshAccessToken();
        if (!newToken) {
          await logout();
          return;
        }
        return loadUser(newToken);
      }

      const data = await res.json();

      if (data.success) {
        setUser({ name: data.data.name });
        setSections(data.data.permissions || []);
        setRole({ role: data.data.role });
        setEmployeeId({ employee_id: data.data.employee_id });
      }
    } catch (err) {
      console.error("Load user error:", err);
      await logout();
    }
  };

  return (
    <AuthContext.Provider
      value={{
        accessToken,
        refreshToken,
        sections,
        user,
        role,
        employee_id,
        setAccessToken,
        setSections,
        setUser,
        setRole,
        refreshAccessToken,
        loadUser,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};
