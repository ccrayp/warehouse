import React from "react";
import { Navbar, Container, Button } from "react-bootstrap";

function Header() {
  return (
    <Navbar bg="light" variant="light" fixed="top" className="shadow-sm">
      <Container>
        <Navbar.Brand>
          <Button variant="light" style={{color: "#0d6efd", fontWeight: "bold"}} href="/">Склад</Button>
        </Navbar.Brand>
        <Button variant="primary">Вход</Button>
      </Container>
    </Navbar>
  );
}

export default Header;
