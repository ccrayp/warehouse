import React, { useEffect, useState, useContext } from "react";
import { Container, Table, Button, Modal, Form, Spinner, Pagination } from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

const PAGE_SIZE = 10;

export default function ProductCategoriesTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "product_category" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "product_category" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "product_category" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "product_category" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [showModal, setShowModal] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [form, setForm] = useState({ id: "", name: "" });
  const [saving, setSaving] = useState(false);

  const fetchData = async (pageNumber = 1) => {
    setLoading(true);
    const offset = (pageNumber - 1) * PAGE_SIZE;

    try {
      const resp = await apiRequest(`/product_categories?limit=${PAGE_SIZE}&offset=${offset}`);
      if (resp.success) {
        setCategories(resp.data.product_categories || []);
        setTotal(resp.data.total || resp.data.product_categories.length || 0);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(page);
  }, [page]);

  const handleShowModal = (category = null) => {
    setEditingCategory(category);
    setForm({
      id: category?.id || "",
      name: category?.name || ""
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingCategory(null);
    setForm({ id: "", name: "" });
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;
    if (!form.name.trim()) {
      alert("Название обязательно");
      return;
    }

    setSaving(true);
    try {
      const payload = { name: form.name.trim() };
      let resp;

      if (editingCategory) {
        resp = await apiRequest(`/product_categories/${editingCategory.id}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
      } else {
        resp = await apiRequest("/product_categories", {
          method: "POST",
          body: JSON.stringify(payload)
        });
      }

      if (resp.success) {
        fetchData(page);
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при сохранении категории");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при сохранении категории");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (category) => {
    if (!hasDelete) return;
    if (!window.confirm(`Удалить категорию "${category.name}"?`)) return;

    try {
      const resp = await apiRequest(`/product_categories/${category.id}`, { method: "DELETE" });
      if (resp.success) {
        fetchData(page);
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при удалении категории");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении категории");
    }
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Справочник: Категории продуктов</h2>
      {hasInsert && (
        <Button className="mb-3" onClick={() => handleShowModal()}>
          Добавить категорию
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
              </tr>
            </thead>
            <tbody>
              {categories.map(cat => (
                <tr key={cat.id} onClick={() => handleShowModal(cat)} style={{ cursor: "pointer" }}>
                  <td>{cat.id}</td>
                  <td>{cat.name}</td>
                </tr>
              ))}
            </tbody>
          </Table>

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
          <Modal.Title>{editingCategory ? "Редактировать категорию" : "Создать категорию"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>ID</Form.Label>
              <Form.Control type="text" value={form.id} disabled />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Название</Form.Label>
              <Form.Control
                type="text"
                value={form.name}
                onChange={e => setForm({ ...form, name: e.target.value })}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}>Отмена</Button>
          {(hasInsert || hasUpdate) && (
            <Button variant="primary" onClick={handleSave} disabled={saving}>
              {saving ? "Сохраняем..." : "Сохранить"}
            </Button>
          )}
          {editingCategory && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingCategory)}>Удалить</Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
