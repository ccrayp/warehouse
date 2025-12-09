import React from "react";
import { Container } from "react-bootstrap";

function Footer() {
  return (
    <footer className="bg-light py-3 mt-auto no-print">
      <Container className="text-center text-muted">
        © {new Date().getFullYear()} Склад — Курсовой проект. Михайлов Роман •{" "}
        <a 
          href="https://github.com/ccrayp" 
          target="_blank" 
          rel="noopener noreferrer"
          className="text-decoration-none"
        >
          GitHub
        </a>
      </Container>
    </footer>
  );
}

export default Footer;
