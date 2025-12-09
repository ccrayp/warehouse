import React from "react";
import { Container, Button } from "react-bootstrap";
import { Link } from "react-router-dom";

function NotFound() {
  return (
    <Container className="d-flex flex-column justify-content-center align-items-center" style={{ height: "70vh" }}>
      <h1 className="display-4 mb-3">404</h1>
      <p className="text-muted mb-4">Страница не найдена</p>

      <Button as={Link} to="/" variant="primary">
        Вернуться на главную
      </Button>
    </Container>
  );
}

export default NotFound;
