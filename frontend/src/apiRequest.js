import { AuthContext } from "./AuthContext";
import { useContext } from "react";

export function useApi() {
  const { accessToken, refreshAccessToken, logout } = useContext(AuthContext);

  async function apiRequest(url, options = {}) {
    const isFormData = options.body instanceof FormData;

    const headers = {
      ...(options.headers || {}),
      ...(isFormData ? {} : { "Content-Type": "application/json" }),
      Authorization: `Bearer ${accessToken}`,
    };

    let response = await fetch(`${apiHost}${url}`, {
      ...options,
      headers,
    });

    if (response.status === 401) {
      const newAccess = await refreshAccessToken();

      if (!newAccess) {
        logout();
        return { success: false, error: "Unauthorized" };
      }

      const retryHeaders = {
        ...(options.headers || {}),
        ...(isFormData ? {} : { "Content-Type": "application/json" }),
        Authorization: `Bearer ${newAccess}`,
      };

      response = await fetch(`${apiHost}${url}`, {
        ...options,
        headers: retryHeaders,
      });
    }

    try {
      return await response.json();
    } catch {
      return { success: false, error: "Invalid JSON response" };
    }
  }

  function getImageUrl(url) {
    return images + url;
  }

  return { apiRequest, getImageUrl };
}

export const apiHost = '/api';
export const images = '';
