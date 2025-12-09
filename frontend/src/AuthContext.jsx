import React, { createContext, useState, useEffect } from "react";
import { apiHost } from "./utils";

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [accessToken, setAccessToken] = useState(localStorage.getItem("access_token"));
  const [refreshToken, setRefreshToken] = useState(localStorage.getItem("refresh_token"));
  const [sections, setSections] = useState(JSON.parse(localStorage.getItem("sections") || "[]"));

  useEffect(() => {
    if (accessToken) localStorage.setItem("access_token", accessToken);
    if (refreshToken) localStorage.setItem("refresh_token", refreshToken);
    localStorage.setItem("sections", JSON.stringify(sections));
  }, [accessToken, refreshToken, sections]);

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
      logout();
      return null;
    }
  };

  const logout = () => {
    setAccessToken(null);
    setRefreshToken(null);
    setSections([]);
    localStorage.clear();
  };

  return (
    <AuthContext.Provider value={{ accessToken, refreshToken, sections, setAccessToken, setSections, refreshAccessToken, logout }}>
      {children}
    </AuthContext.Provider>
  );
};
