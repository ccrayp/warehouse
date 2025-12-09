import React, { createContext, useState, useEffect } from "react";
import { apiHost } from "./apiRequest";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [accessToken, setAccessToken] = useState(localStorage.getItem("access_token"));
  const [refreshToken, setRefreshToken] = useState(localStorage.getItem("refresh_token"));
  const [sections, setSections] = useState(JSON.parse(localStorage.getItem("sections") || "[]"));
  const [user, setUser] = useState(JSON.parse(localStorage.getItem("user") || "null"));
  const [role, setRole] = useState(JSON.parse(localStorage.getItem("role") || "null"));

  useEffect(() => {
    if (accessToken) localStorage.setItem("access_token", accessToken);
    if (refreshToken) localStorage.setItem("refresh_token", refreshToken);
    localStorage.setItem("sections", JSON.stringify(sections));
    localStorage.setItem("user", JSON.stringify(user));
    localStorage.setItem("role", JSON.stringify(role));
  }, [accessToken, refreshToken, sections, user, role]);

  const refreshAccessToken = async () => {
    try {
      const res = await fetch(`${apiHost}/auth/refresh`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refresh_token: refreshToken }),
      });
      const data = await res.json();
      if (data.success) {
        setAccessToken(data.data.access_token);
        setRefreshToken(data.data.refresh_token);
        return data.data.access_token;
      } else {
        throw new Error("Refresh failed");
      }
    } catch (err) {
      console.error(err);
      await logout();
      return null;
    }
  };

  const logout = async () => {
    const tokenToSend = localStorage.getItem("refresh_token");
    const access = localStorage.getItem("access_token");

    try {
      if (tokenToSend) {
        const res = await fetch(`${apiHost}/auth/logout`, {
          method: "POST",
          headers: { 
            "Content-Type": "application/json",
            Authorization: `Bearer ${access}`,
           },
          body: JSON.stringify({ refresh_token: tokenToSend }),
        });
        if (!res.ok) console.error("Logout request failed");
      }
    } catch (err) {
      console.error("Logout error:", err);
    } finally {
      // Очистка состояния и localStorage
      setAccessToken(null);
      setRefreshToken(null);
      setSections([]);
      setUser(null);
      setRole(null);
      localStorage.clear();
    }
  };

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
      const data = await res.json();

      if (data.success) {
        setUser({ name: data.data.name });
        setSections(data.data.permissions || []);
        setRole({role: data.data.role});
      } else {
        await logout();
      }
    } catch {
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
        setAccessToken,
        setSections,
        setUser,
        setRole,
        refreshAccessToken,
        logout,
        loadUser,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};