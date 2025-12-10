// pages/Admin/RolesTable.jsx
import React, { useEffect, useState, useContext } from "react";
import { Container, Table, Button, Modal, Form, Spinner } from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

export default function RolesTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  // Проверка доступа к компоненту
  const hasAccess = sections?.some(s => s.section === "role" && s.permissions.includes("select"));
  if (!hasAccess) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [roles, setRoles] = useState([]);
  const [loading, setLoading] = useState(true);

  const [showModal, setShowModal] = useState(false);
  const [editingRole, setEditingRole] = useState(null);
  const [form, setForm] = useState({ name: "", description: "", sys_role: "" });
  const [saving, setSaving] = useState(false);

  const fetchRoles = async () => {
    setLoading(true);
    try {
      const resp = await apiRequest("/roles", { method: "GET" });
      if (resp.success) setRoles(resp.data.roles || []);
      else console.error(resp.message);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRoles();
  }, []);

  const handleShowModal = (role = null) => {
    setEditingRole(role);
    setForm({
      name: role?.name || "",
      description: role?.description || "",
      sys_role: role?.sys_role || "",
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingRole(null);
    setForm({ name: "", description: "", sys_role: "" });
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      let resp;
      if (editingRole) {
        // редактирование
        resp = await apiRequest(`/roles/${editingRole.id}`, {
          method: "PUT",
          body: JSON.stringify(form),
        });
      } else {
        // создание
        resp = await apiRequest("/roles", {
          method: "POST",
          body: JSON.stringify(form),
        });
      }

      if (resp.success) {
        fetchRoles();
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при сохранении роли");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при сохранении роли");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!editingRole) return;
    if (!window.confirm(`Удалить роль "${editingRole.name}"?`)) return;

    try {
      const resp = await apiRequest(`/roles/${editingRole.id}`, { method: "DELETE" });
      if (resp.success) {
        fetchRoles();
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при удалении роли");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении роли");
    }
  };

  return (
    <Container className="mt-4">
      <h2>Роли пользователей</h2>
      <Button className="mb-3" onClick={() => handleShowModal()}>
        Добавить роль
      </Button>

      {loading ? (
        <Spinner animation="border" />
        ) : (
        <>
            <Table striped bordered hover>
            <thead>
                <tr>
                <th>ID</th>
                <th>Название</th>
                <th>Описание</th>
                <th>Системная роль</th>
                </tr>
            </thead>
            <tbody>
                {roles.map((role) => (
                <tr key={role.id} onClick={() => handleShowModal(role)} style={{ cursor: "pointer" }}>
                    <td>{role.id}</td>
                    <td>{role.name}</td>
                    <td>{role.description}</td>
                    <td>{role.sys_role}</td>
                </tr>
                ))}
            </tbody>
            </Table>
            {roles.length > 0 && (
            <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
                * Для редактирования или удаления роли нажмите на соответствующую строку
            </p>
            )}
        </>
        )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>{editingRole ? "Редактировать роль" : "Создать роль"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Название</Form.Label>
              <Form.Control
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Описание</Form.Label>
              <Form.Control
                type="text"
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Системная роль</Form.Label>
              <Form.Control
                type="text"
                value={form.sys_role}
                onChange={(e) => setForm({ ...form, sys_role: e.target.value })}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          {editingRole && (
            <Button variant="danger" onClick={handleDelete}>
              Удалить
            </Button>
          )}
          <Button variant="secondary" onClick={handleCloseModal}>
            Отмена
          </Button>
          <Button variant="primary" onClick={handleSave} disabled={saving}>
            {saving ? "Сохраняем..." : "Сохранить"}
          </Button>
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
