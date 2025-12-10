import React, { useEffect, useState, useContext } from "react";
import { Container, Table, Button, Modal, Form, Spinner, Pagination } from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

export default function PositionsTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "position" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "position" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "position" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "position" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [positions, setPositions] = useState([]);
  const [loading, setLoading] = useState(true);

  const PAGE_SIZE = 10;
  const [page, setPage] = useState(1);
  const [totalPositions, setTotalPositions] = useState(0);

  const [showModal, setShowModal] = useState(false);
  const [editingPosition, setEditingPosition] = useState(null);
  const [form, setForm] = useState({ name: "", description: "" });
  const [saving, setSaving] = useState(false);

  const fetchPositions = async (pageNumber = 1) => {
    setLoading(true);
    const offset = (pageNumber - 1) * PAGE_SIZE;

    try {
      const resp = await apiRequest(`/positions?limit=${PAGE_SIZE}&offset=${offset}`);
      if (resp.success) {
        setPositions(resp.data.positions || []);
        setTotalPositions(resp.data.total || 0);
      } else {
        console.error(resp.message);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPositions(page);
  }, [page]);

  const handleShowModal = (position = null) => {
    setEditingPosition(position);
    setForm({
      name: position?.name || "",
      description: position?.description || "",
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingPosition(null);
    setForm({ name: "", description: "" });
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;
    setSaving(true);
    try {
      let resp;
      if (editingPosition) {
        if (!hasUpdate) {
          alert("Нет прав на редактирование");
          return;
        }
        resp = await apiRequest(`/positions/${editingPosition.id}`, {
          method: "PUT",
          body: JSON.stringify(form),
        });
      } else {
        if (!hasInsert) {
          alert("Нет прав на создание");
          return;
        }
        resp = await apiRequest("/positions", {
          method: "POST",
          body: JSON.stringify(form),
        });
      }

      if (resp.success) {
        fetchPositions(page);
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при сохранении должности");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при сохранении должности");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (position) => {
    if (!hasDelete) {
      alert("Нет прав на удаление");
      return;
    }
    if (!window.confirm(`Удалить должность "${position.name}"?`)) return;
    try {
      const resp = await apiRequest(`/positions/${position.id}`, { method: "DELETE" });
      if (resp.success) {
        fetchPositions(page);
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при удалении должности");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении должности");
    }
  };

  const totalPages = Math.ceil(totalPositions / PAGE_SIZE);

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Справочник: Должности</h2>
      {hasInsert && (
        <Button className="mb-3" onClick={() => handleShowModal()}>
          Добавить должность
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
                <th>Название</th>
                <th>Описание</th>
              </tr>
            </thead>
            <tbody>
              {positions.map((pos) => (
                <tr
                  key={pos.id}
                  onClick={() => handleShowModal(pos)}
                  style={{ cursor: "pointer" }}
                >
                  <td>{pos.id}</td>
                  <td>{pos.name}</td>
                  <td>{pos.description}</td>
                </tr>
              ))}
            </tbody>
          </Table>
              
          {positions.length > 0 && (
            <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
              * Для редактирования или удаления нажмите на соответствующую строку
            </p>
          )}
          
          {totalPages > 1 && (
            <div className="d-flex justify-content-center mt-3 mb-4">
              <Pagination>
                <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
                <Pagination.Prev onClick={() => setPage(p => Math.max(p - 1, 1))} disabled={page === 1} />

                {[...Array(totalPages)].map((_, idx) => {
                  const pageNum = idx + 1;
                  if (pageNum < page - 7 || pageNum > page + 7) return null;
                  return (
                    <Pagination.Item
                      key={pageNum}
                      active={page === pageNum}
                      onClick={() => setPage(pageNum)}
                    >
                      {pageNum}
                    </Pagination.Item>
                  );
                })}

                <Pagination.Next onClick={() => setPage(p => Math.min(p + 1, totalPages))} disabled={page === totalPages} />
                <Pagination.Last onClick={() => setPage(totalPages)} disabled={page === totalPages} />
              </Pagination>
            </div>
          )}
        </>
      )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>{editingPosition ? "Редактировать должность" : "Создать должность"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Название</Form.Label>
              <Form.Control
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Описание</Form.Label>
              <Form.Control
                type="text"
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
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
          {editingPosition && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingPosition)}>
              Удалить
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
