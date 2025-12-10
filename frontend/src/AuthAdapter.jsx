import { useEffect, useContext } from "react";
import { useLocation } from "react-router-dom";
import { AuthContext } from "./AuthContext";

export default function AuthUpdater() {
  const location = useLocation();
  const { loadUser } = useContext(AuthContext);

  useEffect(() => {
    loadUser();
  }, [location.pathname]);
  return null;
}
