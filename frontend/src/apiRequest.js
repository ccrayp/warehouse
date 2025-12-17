import { AuthContext } from "./AuthContext";
import { useContext } from "react";

export const apiHost = "/api";
export const images = "";

export function useApi() {
  const { accessToken, refreshAccessToken, logout } = useContext(AuthContext);

  async function apiRequest(url, options = {}) {
    const isFormData = options.body instanceof FormData;

    const makeHeaders = (token) => ({
      ...(options.headers || {}),
      ...(isFormData ? {} : { "Content-Type": "application/json" }),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    });

    // 1. первый запрос
    let response = await fetch(`${apiHost}${url}`, {
      ...options,
      headers: makeHeaders(accessToken),
    });

    // 2. если access токен истёк — пробуем refresh
    if (response.status === 401) {
      console.warn("401 received, trying to refresh access token");

      const newAccess = await refreshAccessToken();

      if (!newAccess) {
        logout();
        throw new Error("Unauthorized");
      }

      // 3. повтор запроса с новым access токеном
      response = await fetch(`${apiHost}${url}`, {
        ...options,
        headers: makeHeaders(newAccess),
      });
    }

    // 4. если даже после refresh не ок — ошибка
    if (!response.ok) {
      let errorBody = null;
      try {
        errorBody = await response.json();
      } catch {}

      throw {
        status: response.status,
        body: errorBody,
      };
    }

    // 5. успешный ответ
    return await response.json();
  }

  function getImageUrl(url) {
    return images + url;
  }

  return { apiRequest, getImageUrl };
}