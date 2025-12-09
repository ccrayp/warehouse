import React, { useEffect, useState, useContext } from "react";
import { Container, Card, Spinner, Alert } from "react-bootstrap";
import { AuthContext } from "../AuthContext";
import { useApi } from "../apiRequest";

export default function Profile() {
  const { accessToken } = useContext(AuthContext);
  const [employee, setEmployee] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const { apiRequest } = useApi();

  useEffect(() => {
    const loadProfile = async () => {
      if (!accessToken) {
        setError("Пользователь не авторизован");
        setLoading(false);
        return;
      }

      try {
        const res = await apiRequest(`/info/me`, {
          headers: { Authorization: `Bearer ${accessToken}` },
        });
        const data = res

        if (data.success) {
          setEmployee(data.data.employee);
        } else {
          setError("Не удалось загрузить данные пользователя");
        }
      } catch (err) {
        console.error(err);
        setError("Ошибка соединения с сервером");
      } finally {
        setLoading(false);
      }
    };

    loadProfile();
  }, [accessToken]);

  if (loading) {
    return (
      <div className="d-flex justify-content-center py-5">
        <Spinner animation="border" />
      </div>
    );
  }

  if (error) {
    return (
      <Container style={{ marginTop: "120px" }}>
        <Alert variant="danger">{error}</Alert>
      </Container>
    );
  }

  if (!employee) return null;

  return (
    <Container style={{ marginTop: "120px", maxWidth: "600px" }}>
      <Card className="shadow p-4">
        <h3 className="mb-4 text-center">Профиль пользователя</h3>

        <p><strong>Фамилия:</strong> {employee.surname}</p>
        <p><strong>Имя:</strong> {employee.firstname}</p>
        <p><strong>Отчество:</strong> {employee.patronymic}</p>
        <p><strong>Должность:</strong> {employee.position}</p>
        <p><strong>Адрес:</strong> {employee.address}</p>
      </Card>
    </Container>
  );
}
