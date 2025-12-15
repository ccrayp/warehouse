import React, { useEffect, useState, useContext } from "react";
import {
  Container,
  Table,
  Button,
  Modal,
  Form,
  Spinner,
  Pagination
} from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

const PAGE_SIZE = 10;

export default function BatchesTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "batch" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "batch" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "batch" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "batch" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container className="mt-4">
        <h3 style={{ color: "darkred" }}>Нет доступа</h3>
        <p>Вы не можете просматривать партии товаров.</p>
      </Container>
    );
  }

  const [batches, setBatches] = useState([]);
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState("");

  const [showModal, setShowModal] = useState(false);
  const [editingBatch, setEditingBatch] = useState(null);
  const [saving, setSaving] = useState(false);

  const [form, setForm] = useState({
    cost: "",
    production_date: "",
    expiration_date: "",
    id_product: ""
  });

  const fetchData = async (pageNum = 1, q = "") => {
    setLoading(true);
    const offset = (pageNum - 1) * PAGE_SIZE;
    const query = q ? `&q=${encodeURIComponent(q)}` : "";

    try {
      const [batchResp, prodResp] = await Promise.all([
        apiRequest(`/batches?limit=${PAGE_SIZE}&offset=${offset}${query}`),
        apiRequest("/products")
      ]);

      if (batchResp.success) {
        setBatches(batchResp.data.batches || []);
        setTotal(batchResp.data.total || 0);
      }

      if (prodResp.success) {
        setProducts(prodResp.data.products || []);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(page, search);
  }, [page, search]);

  const handleShowModal = batch => {
    setEditingBatch(batch);
    setForm({
      cost: batch?.cost || "",
      production_date: batch?.production_date?.slice(0, 10) || "",
      expiration_date: batch?.expiration_date?.slice(0, 10) || "",
      id_product: batch?.id_product || ""
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingBatch(null);
    setForm({ cost: "", production_date: "", expiration_date: "", id_product: "" });
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.cost || !form.id_product) {
      alert("Заполните обязательные поля");
      return;
    }

    setSaving(true);
    try {
      const payload = {
        cost: Number(form.cost),
        production_date: form.production_date,
        expiration_date: form.expiration_date,
        id_product: Number(form.id_product)
      };

      let resp;
      if (editingBatch) {
        resp = await apiRequest(`/batches/${editingBatch.id}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
      } else {
        resp = await apiRequest("/batches", {
          method: "POST",
          body: JSON.stringify(payload)
        });
      }

      if (!resp.success) throw new Error(resp.message || "Ошибка сохранения");

      fetchData(page, search);
      handleCloseModal();
    } catch (e) {
      console.error(e);
      alert(e.message || "Ошибка при сохранении");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async batch => {
    if (!hasDelete) return;
    if (!window.confirm(`Удалить партию №${batch.id} (все связанные данные будут удалены)?`)) return;

    try {
      const resp = await apiRequest(`/batches/${batch.id}`, { method: "DELETE" });
      if (resp.success) fetchData(page, search);
      else alert(resp.message || "Ошибка удаления");
    } catch (e) {
      console.error(e);
      alert("Ошибка удаления");
    }
  };

  const getProductName = id =>
    products.find(p => p.id === id)?.name || `Товар #${id}`;

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <Container className="mt-4">
      <h2 className="pt-3">Склад: Партии товаров</h2>

      <div className="d-flex justify-content-between mb-3">
        <Form.Control
          style={{ maxWidth: "300px" }}
          placeholder="Поиск по товару"
          value={search}
          onChange={e => {
            setSearch(e.target.value);
            setPage(1);
          }}
        />
        {hasInsert && (
          <Button onClick={() => handleShowModal()}><i class="fa-solid fa-plus pe-2"></i>Добавить партию</Button>
        )}
      </div>

      {loading ? (
        <Spinner animation="border" />
      ) : (
        <>
          <Table striped bordered hover>
            <thead>
              <tr>
                <th>ID</th>
                <th>Товар</th>
                <th>Стоимость за 1 у.е.</th>
                <th>Дата производства</th>
                <th>Срок годности</th>
                <th>Создано</th>
              </tr>
            </thead>
            <tbody>
              {batches.map(b => (
                <tr
                  key={b.id}
                  onClick={() => handleShowModal(b)}
                  style={{ cursor: "pointer" }}
                >
                  <td>{b.id}</td>
                  <td>{getProductName(b.id_product)}</td>
                  <td>{b.cost}</td>
                  <td>{b.production_date?.slice(0, 10)}</td>
                  <td>{b.expiration_date?.slice(0, 10)}</td>
                  <td>{b.created_at?.slice(0, 10)}</td>
                </tr>
              ))}
            </tbody>
          </Table>

          {totalPages > 1 && (
            <Pagination className="justify-content-center">
              <Pagination.Prev
                disabled={page === 1}
                onClick={() => setPage(p => p - 1)}
              />
              {[...Array(totalPages)].map((_, i) => (
                <Pagination.Item
                  key={i + 1}
                  active={page === i + 1}
                  onClick={() => setPage(i + 1)}
                >
                  {i + 1}
                </Pagination.Item>
              ))}
              <Pagination.Next
                disabled={page === totalPages}
                onClick={() => setPage(p => p + 1)}
              />
            </Pagination>
          )}
        </>
      )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>
            {editingBatch ? "Редактировать партию" : "Создать партию"}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-2">
              <Form.Label>Товар</Form.Label>
              <Form.Select
                value={form.id_product}
                onChange={e => setForm({ ...form, id_product: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              >
                <option value="">Выберите товар</option>
                {products.map(p => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </Form.Select>
            </Form.Group>

            <Form.Group className="mb-2">
              <Form.Label>Стоимость</Form.Label>
              <Form.Control
                type="number"
                value={form.cost}
                onChange={e => setForm({ ...form, cost: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>

            <Form.Group className="mb-2">
              <Form.Label>Дата производства</Form.Label>
              <Form.Control
                type="date"
                value={form.production_date}
                onChange={e => setForm({ ...form, production_date: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>

            <Form.Group className="mb-2">
              <Form.Label>Срок годности</Form.Label>
              <Form.Control
                type="date"
                value={form.expiration_date}
                onChange={e => setForm({ ...form, expiration_date: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}><i class="fa-solid fa-arrow-right-from-bracket pe-2"></i>Отмена</Button>
          {(hasInsert || hasUpdate) && (
            <Button variant="primary" onClick={handleSave} disabled={saving}>
              <i class="fa-solid fa-floppy-disk pe-2"></i>{saving ? "Сохраняем..." : "Сохранить"}
            </Button>
          )}
          {editingBatch && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingBatch)}>
              <i class="fa-solid fa-trash pe-2"></i>Удалить
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
