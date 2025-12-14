import { useState, useEffect, useContext } from "react";
import {
  Table,
  Spinner,
  Container,
  Pagination,
  Button,
  Modal,
  Form,
  Alert
} from "react-bootstrap";
import { AuthContext } from "../../AuthContext";
import { useApi } from "../../apiRequest";

const PAGE_SIZE = 10;

export default function AddressesTable() {
  const { sections } = useContext(AuthContext);
  const { apiRequest } = useApi();

  const hasSelect = sections?.some(s => s.section === "address" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "address" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "address" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "address" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [addresses, setAddresses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState("");

  const [showModal, setShowModal] = useState(false);
  const [editingAddress, setEditingAddress] = useState(null);
  const [form, setForm] = useState({
    subject: "",
    region: "",
    city: "",
    street: "",
    building: ""
  });
  const [saving, setSaving] = useState(false);

  const fetchAddresses = async (pageNum = 1) => {
    setLoading(true);
    setError("");
    const offset = (pageNum - 1) * PAGE_SIZE;

    try {
      const resp = await apiRequest(`/addresses?limit=${PAGE_SIZE}&offset=${offset}`);
      if (resp.success) {
        setAddresses(resp.data.addresses || []);
        setTotal(resp.data.total || 0);
      } else {
        setError(resp.message || "Ошибка при загрузке адресов");
      }
    } catch (err) {
      console.error(err);
      setError("Ошибка при запросе адресов");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAddresses(page);
  }, [page]);

  const handleShowModal = (address = null) => {
    setEditingAddress(address);
    setForm({
      subject: address?.subject || "",
      region: address?.region || "",
      city: address?.city || "",
      street: address?.street || "",
      building: address?.building || ""
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingAddress(null);
    setForm({
      subject: "",
      region: "",
      city: "",
      street: "",
      building: ""
    });
  };

  const validateForm = () => {
    if (!form.subject.trim()) return "Субъект обязателен";
    if (!form.city.trim()) return "Город обязателен";
    if (!form.street.trim()) return "Улица обязательна";
    if (!form.building.toString().trim()) return "Дом обязателен";
    if (isNaN(Number(form.building))) return "Дом должен быть числом";
    return null;
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    const errorMsg = validateForm();
    if (errorMsg) {
      alert(errorMsg);
      return;
    }

    setSaving(true);
    try {
      const url = editingAddress ? `/addresses/${editingAddress.id}` : "/addresses";
      const method = editingAddress ? "PUT" : "POST";

      const payload = {
        subject: form.subject.trim(),
        region: form.region.trim(),
        city: form.city.trim(),
        street: form.street.trim(),
        building: Number(form.building)
      };

      const resp = await apiRequest(url, { method, body: JSON.stringify(payload) });
      if (resp.success) {
        handleCloseModal();
        fetchAddresses(page);
      } else {
        alert(resp.message || "Ошибка при сохранении адреса");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при сохранении адреса");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!hasDelete || !editingAddress) return;
    if (!window.confirm(`Удалить адрес "${editingAddress.subject}, ${editingAddress.city}" (все связанные данные будут удалены)?`)) return;

    try {
      const resp = await apiRequest(`/addresses/${editingAddress.id}`, { method: "DELETE" });
      if (resp.success) {
        handleCloseModal();
        fetchAddresses(page);
      } else {
        alert(resp.message || "Ошибка при удалении адреса");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении адреса");
    }
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const renderPagination = () => (
    <Pagination>
      <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
      <Pagination.Prev onClick={() => setPage(p => Math.max(p - 1, 1))} disabled={page === 1} />
      {[...Array(totalPages)].map((_, idx) => {
        const pageNum = idx + 1;
        if (pageNum < page - 7 || pageNum > page + 7) return null;
        return (
          <Pagination.Item key={pageNum} active={page === pageNum} onClick={() => setPage(pageNum)}>
            {pageNum}
          </Pagination.Item>
        );
      })}
      <Pagination.Next onClick={() => setPage(p => Math.min(p + 1, totalPages))} disabled={page === totalPages} />
      <Pagination.Last onClick={() => setPage(totalPages)} disabled={page === totalPages} />
    </Pagination>
  );

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Справочник: Адреса</h2>

      {hasInsert && <Button className="mb-3" onClick={() => handleShowModal()}>Добавить адрес</Button>}

      {loading ? (
        <Spinner animation="border" />
      ) : error ? (
        <Alert variant="danger">{error}</Alert>
      ) : addresses.length === 0 ? (
        <Alert variant="info">Адреса не найдены</Alert>
      ) : (
        <>
          <Table striped bordered hover responsive>
            <thead>
              <tr>
                <th>ID</th>
                <th>Субъект</th>
                <th>Район</th>
                <th>Город</th>
                <th>Улица</th>
                <th>Дом</th>
              </tr>
            </thead>
            <tbody>
              {addresses.map(addr => (
                <tr key={addr.id} style={{ cursor: "pointer" }} onClick={() => handleShowModal(addr)}>
                  <td>{addr.id}</td>
                  <td>{addr.subject}</td>
                  <td>{addr.region}</td>
                  <td>{addr.city}</td>
                  <td>{addr.street}</td>
                  <td>{addr.building}</td>
                </tr>
              ))}
            </tbody>
          </Table>
          
        {addresses.length > 0 && (
            <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
              * Для редактирования или удаления нажмите на соответствующую строку
            </p>
          )}

          {totalPages > 1 && <div className="d-flex justify-content-center mt-2">{renderPagination()}</div>}
        </>
      )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>{editingAddress ? "Редактировать адрес" : "Создать адрес"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-2">
              <Form.Label>Субъект</Form.Label>
              <Form.Control value={form.subject} onChange={e => setForm({ ...form, subject: e.target.value })} />
            </Form.Group>
            <Form.Group className="mb-2">
              <Form.Label>Район</Form.Label>
              <Form.Control value={form.region} onChange={e => setForm({ ...form, region: e.target.value })} />
            </Form.Group>
            <Form.Group className="mb-2">
              <Form.Label>Город</Form.Label>
              <Form.Control value={form.city} onChange={e => setForm({ ...form, city: e.target.value })} />
            </Form.Group>
            <Form.Group className="mb-2">
              <Form.Label>Улица</Form.Label>
              <Form.Control value={form.street} onChange={e => setForm({ ...form, street: e.target.value })} />
            </Form.Group>
            <Form.Group className="mb-2">
              <Form.Label>Дом</Form.Label>
              <Form.Control type="number" value={form.building} onChange={e => setForm({ ...form, building: e.target.value })} />
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          {editingAddress && hasDelete && <Button variant="danger" onClick={handleDelete}>Удалить</Button>}
          <Button variant="secondary" onClick={handleCloseModal}>Отмена</Button>
          {(hasInsert || hasUpdate) && <Button variant="primary" onClick={handleSave} disabled={saving}>{saving ? "Сохраняем..." : "Сохранить"}</Button>}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
