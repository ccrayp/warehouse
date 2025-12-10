// pages/Admin/GendersTable.jsx
import React, { useEffect, useState, useContext } from "react";
import { Container, Table, Button, Modal, Form, Spinner } from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

export default function GendersTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "gender" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "gender" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "gender" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "gender" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [genders, setGenders] = useState([]);
  const [loading, setLoading] = useState(true);

  const [showModal, setShowModal] = useState(false);
  const [editingGender, setEditingGender] = useState(null);
  const [form, setForm] = useState({
    sign: ""
  });
  const [saving, setSaving] = useState(false);

  const fetchData = async () => {
    setLoading(true);
    try {
      const resp = await apiRequest("/genders");
      if (resp.success) setGenders(resp.data.genders || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleShowModal = (gender = null) => {
    setEditingGender(gender);
    setForm({
      sign: gender?.sign || ""
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setEditingGender(null);
    setShowModal(false);
    setForm({ sign: "" });
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.sign.trim()) {
      alert("Введите значение");
      return;
    }

    setSaving(true);
    try {
      const payload = { sign: form.sign };

      let resp;
      if (editingGender) {
        resp = await apiRequest(`/genders/${editingGender.id}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
      } else {
        resp = await apiRequest(`/genders`, {
          method: "POST",
          body: JSON.stringify(payload)
        });
      }

      if (resp.success) {
        fetchData();
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при сохранении");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при сохранении");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (gender) => {
    if (!hasDelete) {
      alert("Нет прав на удаление");
      return;
    }

    if (!window.confirm(`Удалить "${gender.sign}"?`)) return;

    try {
      const resp = await apiRequest(`/genders/${gender.id}`, {
        method: "DELETE"
      });

      if (resp.success) {
        fetchData();
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка удаления");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка удаления");
    }
  };

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Справочник: Пол</h2>

      {hasInsert && (
        <Button className="mb-3" onClick={() => handleShowModal()}>
          Добавить запись
        </Button>
      )}

      {loading ? (
        <Spinner animation="border" />
      ) : (
        <>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Обозначение</th>
              </tr>
            </thead>
            <tbody>
              {genders.map(g => (
                <tr
                  key={g.id}
                  onClick={() => handleShowModal(g)}
                  style={{ cursor: "pointer" }}
                >
                  <td>{g.id}</td>
                  <td>{g.sign}</td>
                </tr>
              ))}
            </tbody>
          </Table>

          {/* {genders.length > 0 && (
            <p style={{ fontSize: "14px", color: "#666" }}>
              * Нажмите на строку для редактирования или удаления
            </p>
          )} */}
        </>
      )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            {editingGender ? "Редактировать" : "Создать запись"}
          </Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Обозначение</Form.Label>
              <Form.Control
                type="text"
                value={form.sign}
                maxlength={5}
                onChange={e => setForm({ ...form, sign: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                placeholder="Пример: М / Ж / -"
              />
            </Form.Group>
          </Form>
        </Modal.Body>

        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>
            Отмена
          </Button>

          {(hasInsert || hasUpdate) && (
            <Button variant="primary" onClick={handleSave} disabled={saving}>
              {saving ? "Сохраняем..." : "Сохранить"}
            </Button>
          )}

          {editingGender && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingGender)}>
              Удалить
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
