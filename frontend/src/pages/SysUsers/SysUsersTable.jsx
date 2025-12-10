import React, { useEffect, useState } from "react";
import { Container, Table, Button, Modal, Form, Spinner, Pagination } from "react-bootstrap";
import { useApi } from "../../apiRequest";

export default function SysUsersTable() {
  const { apiRequest } = useApi();

  const [users, setUsers] = useState([]);
  const [roles, setRoles] = useState([]);
  const [employees, setEmployees] = useState([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const pageSize = 10;

  const [showModal, setShowModal] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [form, setForm] = useState({ login: "", password: "", id_role: "", id_employee: "" });
  const [saving, setSaving] = useState(false);

  const fetchUsers = async (page = 1) => {
    setLoading(true);
    try {
      const offset = (page - 1) * pageSize;
      const resp = await apiRequest(`/sys_users?limit=${pageSize}&offset=${offset}`, { method: "GET" });
      if (resp.success) {
        setUsers(resp.data.users || []);
        setTotal(resp.data.total || resp.data.users.length);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchRoles = async () => {
    try {
      const resp = await apiRequest("/roles", { method: "GET" });
      if (resp.success) setRoles(resp.data.roles || []);
    } catch (err) {
      console.error(err);
    }
  };

  const fetchEmployees = async () => {
    try {
      const resp = await apiRequest("/employees", { method: "GET" });
      if (resp.success) setEmployees(resp.data.employees || []);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    fetchRoles();
    fetchEmployees();
  }, []);

  useEffect(() => {
    fetchUsers(page);
  }, [page]);

  const handleShowModal = (user = null) => {
    setEditingUser(user);
    setForm({
      login: user?.login || "",
      password: "",
      id_role: user?.id_role || "",
      id_employee: user?.id_employee || "",
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingUser(null);
    setForm({ login: "", password: "", id_role: "", id_employee: "" });
  };

  const handleSave = async () => {
    setSaving(true);
    try {
        const payload = {
        login: form.login,
        id_role: Number(form.id_role),
        id_employee: Number(form.id_employee),
        };
        if (form.password) payload.password = form.password;

        let resp;
        if (editingUser) {
        resp = await apiRequest(`/sys_users/${editingUser.id}`, {
            method: "PUT",
            body: JSON.stringify(payload),
        });
        } else {
        resp = await apiRequest("/sys_users", {
            method: "POST",
            body: JSON.stringify(payload),
        });
        }

        if (resp.success) {
        fetchUsers(page);
        handleCloseModal();
        } else {
        alert(resp.message || "Ошибка при сохранении пользователя");
        }
    } catch (err) {
        console.error(err);
        alert("Ошибка при сохранении пользователя");
    } finally {
        setSaving(false);
    }
    };


  const handleDelete = async (user) => {
    if (!window.confirm(`Удалить пользователя "${user.login}"?`)) return;
    try {
        const resp = await apiRequest(`/sys_users/${user.id}`, { method: "DELETE" });
        if (resp.success) {
        fetchUsers(page);
        handleCloseModal();
        } else {
        alert(resp.message || "Ошибка при удалении пользователя");
        }
    } catch (err) {
        console.error(err);
        alert("Ошибка при удалении пользователя");
    }
    };

  const totalPages = Math.ceil(total / pageSize);

  return (
    <Container className="mt-4">
      <h2>Администрирование: Пользователи системы</h2>
      <Button className="mb-3" onClick={() => handleShowModal()}>
        Добавить пользователя
      </Button>

      {loading ? (
        <Spinner animation="border" />
      ) : (
        <>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Логин</th>
                <th>Роль</th>
                <th>Сотрудник</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => {
                const role = roles.find((r) => r.id === user.id_role)?.name || user.id_role;
                const emp = employees.find((e) => e.id === user.id_employee);
                const empName = emp ? `${emp.surname} ${emp.firstname} ${emp.patronymic}` : user.id_employee;

                return (
                  <tr key={user.id} onClick={() => handleShowModal(user)} style={{ cursor: "pointer" }}>
                    <td>{user.id}</td>
                    <td>{user.login}</td>
                    <td>{role}</td>
                    <td>{empName}</td>
                  </tr>
                );
              })}
            </tbody>
          </Table>
          {users.length > 0 && (
            <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
              * Для редактирования или удаления пользователя нажмите на соответствующую строку
            </p>
          )}

          {totalPages > 1 && (
            <Pagination className="mt-3">
              <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
              <Pagination.Prev onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1} />
              {[...Array(totalPages)].map((_, idx) => (
                <Pagination.Item key={idx + 1} active={page === idx + 1} onClick={() => setPage(idx + 1)}>
                  {idx + 1}
                </Pagination.Item>
              ))}
              <Pagination.Next onClick={() => setPage((p) => Math.min(totalPages, p + 1))} disabled={page === totalPages} />
              <Pagination.Last onClick={() => setPage(totalPages)} disabled={page === totalPages} />
            </Pagination>
          )}
        </>
      )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>{editingUser ? "Редактировать пользователя" : "Создать пользователя"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Логин</Form.Label>
              <Form.Control
                type="text"
                value={form.login}
                onChange={(e) => setForm({ ...form, login: e.target.value })}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Пароль {editingUser ? "(оставьте пустым чтобы не менять)" : ""}</Form.Label>
              <Form.Control
                type="password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Роль</Form.Label>
              <Form.Select
                value={form.id_role}
                onChange={(e) => setForm({ ...form, id_role: e.target.value })}
              >
                <option value="">Выберите роль</option>
                {roles.map((r) => (
                  <option key={r.id} value={r.id}>
                    {r.name}
                  </option>
                ))}
              </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Сотрудник</Form.Label>
              <Form.Select
                value={form.id_employee}
                onChange={(e) => setForm({ ...form, id_employee: e.target.value })}
              >
                <option value="">Выберите сотрудника</option>
                {employees.map((e) => (
                  <option key={e.id} value={e.id}>
                    {e.surname} {e.firstname} {e.patronymic}
                  </option>
                ))}
              </Form.Select>
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Отмена
          </Button>
          <Button variant="primary" onClick={handleSave} disabled={saving}>
            {saving ? "Сохраняем..." : "Сохранить"}
          </Button>
          {editingUser && (
            <Button variant="danger" onClick={() => handleDelete(editingUser)}>
              Удалить
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
