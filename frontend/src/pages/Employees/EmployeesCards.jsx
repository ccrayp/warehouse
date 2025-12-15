import React, { useEffect, useState, useContext } from "react";
import {
  Container,
  Row,
  Col,
  Card,
  Button,
  Modal,
  Form,
  Spinner,
  Pagination,
  Alert
} from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

const PAGE_SIZE = 12;

export default function EmployeesCards() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "employee" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "employee" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "employee" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "employee" && s.permissions.includes("delete"));

  if (!hasSelect) return (
    <Container style={{ padding: "40px" }}>
      <h2 style={{ color: "darkred" }}>Нет доступа</h2>
      <p>У вас нет прав для просмотра этого раздела.</p>
    </Container>
  );

  const [employees, setEmployees] = useState([]);
  const [positions, setPositions] = useState([]);
  const [genders, setGenders] = useState([]);
  const [addresses, setAddresses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState("");

  const [searchQuery, setSearchQuery] = useState("");
  const [filterPosition, setFilterPosition] = useState("");

  const [showModal, setShowModal] = useState(false);
  const [editingEmployee, setEditingEmployee] = useState(null);
  const [form, setForm] = useState({
    surname: "",
    firstname: "",
    patronymic: "",
    id_gender: "",
    inn: "",
    phone_number: "",
    id_address: "",
    birth_date: "",
    id_position: ""
  });
  const [saving, setSaving] = useState(false);

  const fetchData = async (pageNum = 1) => {
    setLoading(true);
    setError("");
    const offset = (pageNum - 1) * PAGE_SIZE;

    try {
      const [empResp, posResp, genderResp, addrResp] = await Promise.all([
        apiRequest(`/employees?limit=${PAGE_SIZE}&offset=${offset}${searchQuery ? `&q=${encodeURIComponent(searchQuery)}` : ""}`),
        apiRequest("/positions"),
        apiRequest("/genders"),
        apiRequest("/addresses")
      ]);

      if (empResp.success) {
        setEmployees(empResp.data.employees || []);
        setTotal(empResp.data.total || 0);
      } else setError(empResp.message || "Ошибка при загрузке сотрудников");

      if (posResp.success) setPositions(posResp.data.positions || []);
      if (genderResp.success) setGenders(genderResp.data.genders || []);
      if (addrResp.success) setAddresses(addrResp.data.addresses || []);
    } catch (err) {
      console.error(err);
      setError("Ошибка при запросе данных");
    } finally { setLoading(false); }
  };

  useEffect(() => { fetchData(page); }, [page, searchQuery]);

  const filteredEmployees = filterPosition
    ? employees.filter(emp => emp.id_position === Number(filterPosition))
    : employees;

  const handleSearchChange = e => { setSearchQuery(e.target.value); setPage(1); };
  const handlePositionChange = e => { setFilterPosition(e.target.value); };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingEmployee(null);
    setForm({
      surname: "",
      firstname: "",
      patronymic: "",
      id_gender: "",
      inn: "",
      phone_number: "",
      id_address: "",
      birth_date: "",
      id_position: ""
    });
  };

  const handleShowModal = emp => {
    setEditingEmployee(emp);
    setForm({
      surname: emp?.surname || "",
      firstname: emp?.firstname || "",
      patronymic: emp?.patronymic || "",
      id_gender: emp?.id_gender || "",
      inn: emp?.inn || "",
      phone_number: emp?.phone_number || "",
      id_address: emp?.id_address || "",
      birth_date: emp?.birth_date?.split("T")[0] || "",
      id_position: emp?.id_position || ""
    });
    setShowModal(true);
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.surname.trim() || !form.firstname.trim()) return alert("ФИО обязательно");
    if (!form.id_gender || !genders.some(g => g.id === Number(form.id_gender))) return alert("Выберите пол");
    if (!form.id_address || !addresses.some(a => a.id === Number(form.id_address))) return alert("Выберите адрес");
    if (!form.id_position || !positions.some(p => p.id === Number(form.id_position))) return alert("Выберите должность");

    setSaving(true);
    try {
      const payload = {
        ...form,
        id_gender: Number(form.id_gender),
        id_address: Number(form.id_address),
        id_position: Number(form.id_position),
        birth_date: form.birth_date ? new Date(form.birth_date).toISOString() : null
      };

      let resp;
      if (editingEmployee) {
        resp = await apiRequest(`/employees/${editingEmployee.id}`, { method: "PUT", body: JSON.stringify(payload) });
      } else {
        resp = await apiRequest("/employees", { method: "POST", body: JSON.stringify(payload) });
      }

      if (!resp.success) throw new Error(resp.message || "Ошибка при сохранении сотрудника");
      fetchData(page);
      handleCloseModal();
    } catch (err) {
      console.error(err);
      alert(err.message || "Ошибка при сохранении сотрудника");
    } finally { setSaving(false); }
  };

  const handleDelete = async emp => {
    if (!hasDelete) return alert("Нет прав на удаление");
    if (!window.confirm(`Удалить сотрудника "${emp.surname} ${emp.firstname}" (все связанные данные будут удалены)?`)) return;

    try {
      const resp = await apiRequest(`/employees/${emp.id}`, { method: "DELETE" });
      if (!resp.success) throw new Error(resp.message || "Ошибка при удалении");
      fetchData(page);
      handleCloseModal();
    } catch (err) {
      console.error(err);
      alert(err.message || "Ошибка при удалении сотрудника");
    }
  };

  const getGenderSign = id => genders.find(g => g.id === id)?.sign || "-";
  const getAddressStr = id => {
    const addr = addresses.find(a => a.id === id);
    if (!addr) return "-";
    return `${addr.subject}, ${addr.region}, ${addr.city}, ${addr.street}, ${addr.building}`;
  };
  const getPositionName = id => positions.find(p => p.id === id)?.name || "-";

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const renderPagination = () => (
    <Pagination className="mt-2">
      <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
      <Pagination.Prev onClick={() => setPage(p => Math.max(p - 1, 1))} disabled={page === 1} />
      {[...Array(totalPages)].map((_, idx) => {
        const pageNum = idx + 1;
        if (pageNum < page - 7 || pageNum > page + 7) return null;
        return <Pagination.Item key={pageNum} active={page === pageNum} onClick={() => setPage(pageNum)}>{pageNum}</Pagination.Item>;
      })}
      <Pagination.Next onClick={() => setPage(p => Math.min(p + 1, totalPages))} disabled={page === totalPages} />
      <Pagination.Last onClick={() => setPage(totalPages)} disabled={page === totalPages} />
    </Pagination>
  );

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Справочник: Сотрудники</h2>

      <Row className="mb-3">
        <Col md={4}><Form.Control placeholder="Поиск по ФИО" value={searchQuery} onChange={handleSearchChange} /></Col>
        <Col md={4}>
          <Form.Select value={filterPosition} onChange={handlePositionChange}>
            <option value="">Все должности</option>
            {positions.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
          </Form.Select>
        </Col>
        <Col md={4} className="text-end">
          {hasInsert && <Button onClick={() => handleShowModal()}><i class="fa-solid fa-plus pe-2"></i>Добавить сотрудника</Button>}
        </Col>
      </Row>

      {loading ? <Spinner animation="border" /> :
      error ? <Alert variant="danger">{error}</Alert> :
      filteredEmployees.length === 0 ? <Alert variant="info">Сотрудники не найдены</Alert> :
      <>
        <Row xs={1} md={2} lg={3} className="g-3">
          {filteredEmployees.map(emp => (
            <Col key={emp.id}>
              <Card className="h-100" onClick={() => handleShowModal(emp)} style={{ cursor: "pointer" }}>
                <Card.Body>
                  <Card.Title>{`${emp.surname} ${emp.firstname} ${emp.patronymic}`}</Card.Title>
                  <Card.Subtitle className="mt-1 mb-2 text-muted">{getPositionName(emp.id_position)}</Card.Subtitle>
                  <Card.Text>
                    Телефон: {emp.phone_number}<br />
                  </Card.Text>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>
        {employees.length > 0 && <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
          * Для редактирования или удаления нажмите на карточку
        </p>}
        {totalPages > 1 && <div className="d-flex justify-content-center mt-2">{renderPagination()}</div>}
      </>}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>{editingEmployee ? "Редактировать сотрудника" : "Создать сотрудника"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3"><Form.Label>ID</Form.Label>
              <Form.Control type="text" value={editingEmployee?.id || ""} disabled /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Фамилия</Form.Label>
              <Form.Control type="text" maxLength={50} value={form.surname} onChange={e => setForm({...form, surname: e.target.value})} disabled={!hasInsert && !hasUpdate} /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Имя</Form.Label>
              <Form.Control type="text" maxLength={50} value={form.firstname} onChange={e => setForm({...form, firstname: e.target.value})} disabled={!hasInsert && !hasUpdate} /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Отчество</Form.Label>
              <Form.Control type="text" maxLength={50} value={form.patronymic} onChange={e => setForm({...form, patronymic: e.target.value})} disabled={!hasInsert && !hasUpdate} /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Пол</Form.Label>
              <Form.Select value={form.id_gender} onChange={e => setForm({...form, id_gender: e.target.value})} disabled={!hasInsert && !hasUpdate}>
                <option value="">Выберите пол</option>
                {genders.map(g => <option key={g.id} value={g.id}>{g.sign}</option>)}
              </Form.Select>
            </Form.Group>

            <Form.Group className="mb-3"><Form.Label>ИНН</Form.Label>
              <Form.Control type="text" value={form.inn} onChange={e => setForm({...form, inn: e.target.value})} disabled={!hasInsert && !hasUpdate} maxLength={12} minLength={12} /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Телефон</Form.Label>
              <Form.Control type="text" value={form.phone_number} onChange={e => setForm({...form, phone_number: e.target.value})} placeholder="+7 911 123-45-67"
                pattern="\+\d \d{3} \d{3}-\d{2}-\d{2}"
                title="Введите номер в формате +7 911 123-45-67"
                maxLength={16}
                minLength={16}
                disabled={!hasInsert && !hasUpdate} /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Адрес</Form.Label>
              <Form.Select value={form.id_address} onChange={e => setForm({...form, id_address: e.target.value})} disabled={!hasInsert && !hasUpdate}>
                <option value="">Выберите адрес</option>
                {addresses.map(a => <option key={a.id} value={a.id}>{`${a.subject}, ${a.region}, ${a.city}, ${a.street}, ${a.building}`}</option>)}
              </Form.Select>
            </Form.Group>

            <Form.Group className="mb-3"><Form.Label>Дата рождения</Form.Label>
              <Form.Control type="date" value={form.birth_date || ""} onChange={e => setForm({...form, birth_date: e.target.value})} disabled={!hasInsert && !hasUpdate} /></Form.Group>

            <Form.Group className="mb-3"><Form.Label>Должность</Form.Label>
              <Form.Select value={form.id_position} onChange={e => setForm({...form, id_position: e.target.value})} disabled={!hasInsert && !hasUpdate}>
                <option value="">Выберите должность</option>
                {positions.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
              </Form.Select>
            </Form.Group>
          </Form>
        </Modal.Body>
        <Modal.Footer>
          <Button variant="secondary" onClick={handleCloseModal}><i class="fa-solid fa-arrow-right-from-bracket pe-2"></i>Отмена</Button>
          {(hasInsert || hasUpdate) && <Button variant="primary" onClick={handleSave} disabled={saving}><i class="fa-solid fa-floppy-disk pe-2"></i>{saving ? "Сохраняем..." : "Сохранить"}</Button>}
          {editingEmployee && hasDelete && <Button variant="danger" onClick={() => handleDelete(editingEmployee)}><i class="fa-solid fa-trash pe-2"></i>Удалить</Button>}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
