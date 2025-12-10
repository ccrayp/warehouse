import React, { useEffect, useState, useContext } from "react";
import { Container, Table, Button, Modal, Form, Spinner, Pagination } from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

export default function ProducersTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "producer" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "producer" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "producer" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "producer" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const PAGE_SIZE = 10;
  const [producers, setProducers] = useState([]);
  const [addresses, setAddresses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  const [showModal, setShowModal] = useState(false);
  const [editingProducer, setEditingProducer] = useState(null);
  const [form, setForm] = useState({
    name: "",
    id_address: "",
    inn: "",
    surname: "",
    firstname: "",
    patronymic: ""
  });
  const [saving, setSaving] = useState(false);

  const fetchData = async (pageNum = 1) => {
    setLoading(true);
    const offset = (pageNum - 1) * PAGE_SIZE;

    try {
      const [prodResp, addrResp] = await Promise.all([
        apiRequest(`/producers?limit=${PAGE_SIZE}&offset=${offset}`),
        apiRequest("/addresses")
      ]);

      if (prodResp.success) {
        setProducers(prodResp.data.producers || []);
        setTotal(prodResp.data.total || 0);
      }
      if (addrResp.success) setAddresses(addrResp.data.addresses || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(page);
  }, [page]);

  const handleShowModal = (producer = null) => {
    setEditingProducer(producer);
    setForm({
      name: producer?.name || "",
      id_address: producer?.id_address || "",
      inn: producer?.inn || "",
      surname: producer?.surname || "",
      firstname: producer?.firstname || "",
      patronymic: producer?.patronymic || ""
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingProducer(null);
    setForm({ name: "", id_address: "", inn: "", surname: "", firstname: "", patronymic: "" });
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.name.trim()) {
      alert("Название обязательно");
      return;
    }
    if (!form.id_address || !addresses.some(a => a.id === Number(form.id_address))) {
      alert("Выберите корректный адрес");
      return;
    }

    setSaving(true);
    try {
      const payload = {
        ...form,
        id_address: Number(form.id_address)
      };

      let resp;
      if (editingProducer) {
        resp = await apiRequest(`/producers/${editingProducer.id}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
      } else {
        resp = await apiRequest("/producers", {
          method: "POST",
          body: JSON.stringify(payload)
        });
      }

      if (!resp.success) throw new Error(resp.message || "Ошибка при сохранении производителя");

      fetchData(page);
      handleCloseModal();
    } catch (err) {
      console.error(err);
      alert(err.message || "Ошибка при сохранении производителя");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (producer) => {
    if (!hasDelete) {
      alert("Нет прав на удаление");
      return;
    }
    if (!window.confirm(`Удалить производителя "${producer.name}"?`)) return;

    try {
      const resp = await apiRequest(`/producers/${producer.id}`, { method: "DELETE" });
      if (resp.success) {
        fetchData(page);
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при удалении производителя");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении производителя");
    }
  };

  const getAddressStr = (id) => {
    const addr = addresses.find(a => a.id === id);
    if (!addr) return "-";
    return `${addr.subject}, ${addr.region}, ${addr.city}, ${addr.street}, ${addr.building}`;
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Склад: Производители</h2>
      {hasInsert && (
        <Button className="mb-3" onClick={() => handleShowModal()}>
          Добавить производителя
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
                <th>ИНН</th>
                <th>Контактное лицо</th>
                <th>Адрес</th>
              </tr>
            </thead>
            <tbody>
              {producers.map(prod => (
                <tr key={prod.id} onClick={() => handleShowModal(prod)} style={{ cursor: "pointer" }}>
                  <td>{prod.id}</td>
                  <td>{prod.name}</td>
                  <td>{prod.inn}</td>
                  <td>{`${prod.surname} ${prod.firstname} ${prod.patronymic}`}</td>
                  <td>{getAddressStr(prod.id_address)}</td>
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
                    <Pagination.Item key={pageNum} active={page === pageNum} onClick={() => setPage(pageNum)}>
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
          <Modal.Title>{editingProducer ? "Редактировать производителя" : "Создать производителя"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Название</Form.Label>
              <Form.Control
                type="text"
                value={form.name}
                onChange={e => setForm({ ...form, name: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                maxLength={100}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>ИНН</Form.Label>
              <Form.Control
                type="text"
                value={form.inn}
                onChange={e => setForm({ ...form, inn: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                maxLength={10}
                minLength={10}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Фамилия</Form.Label>
              <Form.Control
                type="text"
                value={form.surname}
                onChange={e => setForm({ ...form, surname: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                maxLength={50}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Имя</Form.Label>
              <Form.Control
                type="text"
                value={form.firstname}
                onChange={e => setForm({ ...form, firstname: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                maxLength={50}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Отчество</Form.Label>
              <Form.Control
                type="text"
                value={form.patronymic}
                onChange={e => setForm({ ...form, patronymic: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                maxLength={50}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Адрес</Form.Label>
              <Form.Select
                value={form.id_address}
                onChange={e => setForm({ ...form, id_address: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              >
                <option value="">Выберите адрес</option>
                {addresses.map(a => (
                  <option key={a.id} value={a.id}>
                    {`${a.subject}, ${a.region}, ${a.city}, ${a.street}, ${a.building}`}
                  </option>
                ))}
              </Form.Select>
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
          {editingProducer && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingProducer)}>Удалить</Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
