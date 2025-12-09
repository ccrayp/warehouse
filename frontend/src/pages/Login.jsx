import { useState, useContext } from "react";
import { Card, Button, Form, Container, Row, Col, Spinner, Alert, InputGroup } from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import { AuthContext } from "../AuthContext";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEye, faEyeSlash } from "@fortawesome/free-solid-svg-icons";
import { apiHost, useApi } from "../apiRequest";

export default function Login() {
  const navigate = useNavigate();
  const { setAccessToken, setSections, setUser, setRole } = useContext(AuthContext);

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const { apiRequest } = useApi();

  const toggleShowPassword = () => setShowPassword(!showPassword);

  async function handleLogin(e) {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await fetch(`${apiHost}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username, password }),
      });

      const data = await res.json()

      if (!data.success) {
        localStorage.removeItem("access_token");
        localStorage.removeItem("refresh_token");

        setAccessToken(null);
        setSections([]);

        setError("Неверный логин или пароль");
        setLoading(false);
        return;
      }

      const { access_token, refresh_token } = data.data;

      localStorage.setItem("access_token", access_token);
      localStorage.setItem("refresh_token", refresh_token);

      setAccessToken(access_token);

      const meRes = await fetch(`${apiHost}/auth/me`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${access_token}`,
        },
      });

      const meData = await meRes.json()

      if (meData.success) {
        setUser({ name: meData.data.name });
        setSections(meData.data.permissions || []);
        setRole({role: meData.data.role});
      } else {
        setAccessToken(null);
        setSections([]);
        localStorage.removeItem("access_token");
        localStorage.removeItem("refresh_token");
        localStorage.removeItem("sections");
        setError("Ошибка при получении данных пользователя");
        setLoading(false);
        return;
      }

      navigate("/");
    } catch (err) {
      console.error("Login error:", err);
      setError("Ошибка соединения с сервером");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Container style={{ marginTop: "120px" }}>
      <Row className="justify-content-center">
        <Col xs={12} sm={10} md={6} lg={4}>
          <Card className="shadow p-4">
            <h3 className="mb-3 text-center">Вход в систему</h3>

            {error && <Alert variant="danger">{error}</Alert>}

            <Form onSubmit={handleLogin}>
              <Form.Group className="mb-3">
                <Form.Label>Логин</Form.Label>
                <Form.Control
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Введите логин"
                  required
                />
              </Form.Group>

              <Form.Group className="mb-4">
                <Form.Label>Пароль</Form.Label>
                <InputGroup>
                  <Form.Control
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Введите пароль"
                    required
                  />
                  <Button variant="outline-secondary" onClick={toggleShowPassword}>
                    <FontAwesomeIcon icon={showPassword ? faEyeSlash : faEye} />
                  </Button>
                </InputGroup>
              </Form.Group>

              <Button type="submit" className="w-100" disabled={loading}>
                {loading ? <Spinner animation="border" size="sm" /> : "Войти"}
              </Button>
            </Form>
          </Card>
        </Col>
      </Row>
    </Container>
  );
}
