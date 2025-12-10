import React, { useEffect, useState, useContext } from "react";
import { Container, Table, Button, Modal, Form, Spinner, Pagination } from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

export default function EmployeesTable() {
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "employee" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "employee" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "employee" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "employee" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [employees, setEmployees] = useState([]);
  const [genders, setGenders] = useState([]);
  const [addresses, setAddresses] = useState([]);
  const [positions, setPositions] = useState([]);
  const [loading, setLoading] = useState(true);

  const PAGE_SIZE = 10;
  const [page, setPage] = useState(1);
  const [totalEmployees, setTotalEmployees] = useState(0);

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

  const fetchData = async (pageNumber = 1) => {
    setLoading(true);
    const offset = (pageNumber - 1) * PAGE_SIZE;

    try {
      const [empResp, genderResp, addrResp, posResp] = await Promise.all([
        apiRequest(`/employees?limit=${PAGE_SIZE}&offset=${offset}`),
        apiRequest("/genders"),
        apiRequest("/addresses"),
        apiRequest("/positions")
      ]);

      if (empResp.success) {
        setEmployees(empResp.data.employees || []);
        setTotalEmployees(empResp.data.total || 0);
      }
      if (genderResp.success) setGenders(genderResp.data.genders || []);
      if (addrResp.success) setAddresses(addrResp.data.addresses || []);
      if (posResp.success) setPositions(posResp.data.positions || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(page);
  }, [page]);

  const handleShowModal = (employee = null) => {
    setEditingEmployee(employee);
    setForm({
      surname: employee?.surname || "",
      firstname: employee?.firstname || "",
      patronymic: employee?.patronymic || "",
      id_gender: employee?.id_gender || "",
      inn: employee?.inn || "",
      phone_number: employee?.phone_number || "",
      id_address: employee?.id_address || "",
      birth_date: employee?.birth_date?.split("T")[0] || "",
      id_position: employee?.id_position || ""
    });
    setShowModal(true);
  };

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

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.id_gender || !genders.some(g => g.id === Number(form.id_gender))) {
      alert("Выберите корректный пол");
      return;
    }
    if (!form.id_address || !addresses.some(a => a.id === Number(form.id_address))) {
      alert("Выберите корректный адрес");
      return;
    }
    if (!form.id_position || !positions.some(p => p.id === Number(form.id_position))) {
      alert("Выберите корректную должность");
      return;
    }

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
        resp = await apiRequest(`/employees/${editingEmployee.id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
      } else {
        resp = await apiRequest("/employees", {
          method: "POST",
          body: JSON.stringify(payload),
        });
      }

      if (resp.success) {
        fetchData(page);
        handleCloseModal();
      } else {
        alert(resp.message || "Ошибка при сохранении сотрудника");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при сохранении сотрудника");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (employee) => {
    if (!hasDelete) {
      alert("Нет прав на удаление");
      return;
    }
    if (!window.confirm(`Удалить сотрудника "${employee.surname} ${employee.firstname}"?`)) return;
    try {
      const resp = await apiRequest(`/employees/${employee.id}`, { method: "DELETE" });
      if (resp.success) {
        fetchData(page);
        handleCloseModal();
      }
      else alert(resp.message || "Ошибка при удалении сотрудника");
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении сотрудника");
    }
  };

  const getGenderSign = (id) => genders.find(g => g.id === id)?.sign || "-";
  const getAddressStr = (id) => {
    const addr = addresses.find(a => a.id === id);
    if (!addr) return "-";
    return `${addr.subject}, ${addr.region}, ${addr.city}, ${addr.street}, ${addr.building}`;
  };
  const getPositionName = (id) => positions.find(p => p.id === id)?.name || "-";

  const totalPages = Math.ceil(totalEmployees / PAGE_SIZE);

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Справочник: Сотрудники</h2>
      {hasInsert && (
        <Button className="mb-3" onClick={() => handleShowModal()}>
          Добавить сотрудника
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
                <th>Фамилия</th>
                <th>Имя</th>
                <th>Отчество</th>
                <th>Пол</th>
                <th>ИНН</th>
                <th>Телефон</th>
                <th>Адрес</th>
                <th>Дата рождения</th>
                <th>Должность</th>
              </tr>
            </thead>
            <tbody>
              {employees.map(emp => (
                <tr key={emp.id} onClick={() => handleShowModal(emp)} style={{ cursor: "pointer" }}>
                  <td>{emp.id}</td>
                  <td>{emp.surname}</td>
                  <td>{emp.firstname}</td>
                  <td>{emp.patronymic}</td>
                  <td>{getGenderSign(emp.id_gender)}</td>
                  <td>{emp.inn}</td>
                  <td>{emp.phone_number}</td>
                  <td>{getAddressStr(emp.id_address)}</td>
                  <td>{emp.birth_date?.split("T")[0]}</td>
                  <td>{getPositionName(emp.id_position)}</td>
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
          <Modal.Title>{editingEmployee ? "Редактировать сотрудника" : "Создать сотрудника"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <Form>
            <Form.Group className="mb-3">
              <Form.Label>Фамилия</Form.Label>
              <Form.Control
                type="text"
                value={form.surname}
                onChange={e => setForm({ ...form, surname: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Имя</Form.Label>
              <Form.Control
                type="text"
                value={form.firstname}
                onChange={e => setForm({ ...form, firstname: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Отчество</Form.Label>
              <Form.Control
                type="text"
                value={form.patronymic}
                onChange={e => setForm({ ...form, patronymic: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Пол</Form.Label>
              <Form.Select
                value={form.id_gender}
                onChange={e => setForm({ ...form, id_gender: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              >
                <option value="">Выберите пол</option>
                {genders.map(g => (
                  <option key={g.id} value={g.id}>{g.sign}</option>
                ))}
              </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>ИНН</Form.Label>
              <Form.Control
                type="text"
                value={form.inn}
                onChange={e => setForm({ ...form, inn: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                placeholder="12 цифр"
                pattern="\d{12}"
                title="Введите 12 цифр"
                maxLength={12}
                minLength={12}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Телефон</Form.Label>
              <Form.Control
                type="text"
                value={form.phone_number}
                onChange={e => setForm({ ...form, phone_number: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                placeholder="+7 911 123-45-67"
                pattern="\+\d \d{3} \d{3}-\d{2}-\d{2}"
                title="Введите номер в формате +7 911 123-45-67"
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
            <Form.Group className="mb-3">
              <Form.Label>Дата рождения</Form.Label>
              <Form.Control
                type="date"
                value={form.birth_date || ""}
                onChange={e => setForm({ ...form, birth_date: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              />
            </Form.Group>
            <Form.Group className="mb-3">
              <Form.Label>Должность</Form.Label>
              <Form.Select
                value={form.id_position}
                onChange={e => setForm({ ...form, id_position: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
              >
                <option value="">Выберите должность</option>
                {positions.map(p => (
                  <option key={p.id} value={p.id}>{p.name}</option>
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
          {editingEmployee && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingEmployee)}>Удалить</Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
