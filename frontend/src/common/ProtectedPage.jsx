import React, { useContext } from "react";
import { Container, Spinner } from "react-bootstrap";
import { AuthContext } from "../AuthContext";

export default function ProtectedPage({ section, children }) {
  const { sections } = useContext(AuthContext);

  if (!sections) {
    return (
      <Container className="text-center mt-5">
        <Spinner animation="border" /> Загрузка...
      </Container>
    );
  }

  const hasAccess = sections.some(
    (s) => s.section === section && s.permissions.includes("select")
  );

  if (!hasAccess) {
    return (
      <Container className="mt-4">
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этой страницы.</p>
      </Container>
    );
  }

  return <>{children}</>;
}
