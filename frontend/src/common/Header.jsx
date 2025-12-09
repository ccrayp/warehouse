import React, { useContext } from "react";
import { Navbar, Container, Button, Dropdown } from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import { AuthContext } from "../AuthContext";

export default function Header() {
  const navigate = useNavigate();
  const { accessToken, user, logout } = useContext(AuthContext);

  const handleLogin =  () => navigate("/login");
  const handleLogout = async () => {
    await logout();
    navigate("/");
  };

  return (
    <Navbar bg="light" variant="light" fixed="top" className="shadow-sm no-print">
      <Container>
        <Navbar.Brand>
          <Button
            variant="light"
            style={{ color: "#0d6efd", fontWeight: 700, fontSize: "1.25rem"}}
            onClick={() => navigate("/")}
          >
            Склад
          </Button>
        </Navbar.Brand>

        <div>
          {!accessToken ? (
            <Button variant="primary" onClick={handleLogin}>
              Вход
            </Button>
          ) : (
            <Dropdown align="end">
              <Dropdown.Toggle variant="light" id="user-dropdown" className="d-flex align-items-center">
                <span style={{ fontWeight: 600, color: "#212529" }}>
                  {user?.name || "Пользователь"}
                </span>
              </Dropdown.Toggle>

              <Dropdown.Menu>
                <Dropdown.Item onClick={() => navigate("/profile")}>Профиль</Dropdown.Item>
                <Dropdown.Divider />
                <Dropdown.Item onClick={handleLogout}>Выйти</Dropdown.Item>
              </Dropdown.Menu>
            </Dropdown>
          )}
        </div>
      </Container>
    </Navbar>
  );
}
