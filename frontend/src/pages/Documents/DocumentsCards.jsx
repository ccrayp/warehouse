import { useEffect, useState, useContext } from "react";
import {
  Card,
  Button,
  Spinner,
  Pagination,
  Container,
  Row,
  Col,
  Form
} from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

const PAGE_SIZE = 6;

export default function DocumentsCards() {
  const navigate = useNavigate();
  const { apiRequest } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(
    s => s.section === "document" && s.permissions.includes("select")
  );
  const hasInsert = sections?.some(
    s => s.section === "document" && s.permissions.includes("insert")
  );

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра документов.</p>
      </Container>
    );
  }

  const [documents, setDocuments] = useState([]);
  const [employees, setEmployees] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [filterType, setFilterType] = useState("");

  const fetchDocuments = async (pageNum = 1, type = filterType) => {
    setLoading(true);
    const offset = (pageNum - 1) * PAGE_SIZE;

    try {
      const resp = await apiRequest(
        `/documents?limit=${PAGE_SIZE}&offset=${offset}${type ? `&type=${type}` : ""}`
      );

      if (resp.success) {
        setDocuments(resp.data.document || []);
        setTotal(resp.data.total || 0);
      }
    } finally {
      setLoading(false);
    }
  };

  const fetchMeta = async () => {
    const [empResp, catResp] = await Promise.all([
      apiRequest("/employees"),
      apiRequest("/document_categories")
    ]);

    if (empResp.success) setEmployees(empResp.data.employees || []);
    if (catResp.success) setCategories(catResp.data.document_categories || []);
  };

  useEffect(() => {
    fetchMeta();
  }, []);

  useEffect(() => {
    fetchDocuments(page);
  }, [page, filterType]);

  const openDocument = id => navigate(`/document/${id}`);
  const createDocument = () => navigate("/document/new");

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const getEmployeeName = id => {
    const emp = employees.find(e => e.id === id);
    if (!emp) return id;
    return `${emp.surname} ${emp.firstname} ${emp.patronymic}`;
  };

  const getCategoryName = id =>
    categories.find(c => c.id === id)?.name || id;

  const renderPagination = () => (
    <Pagination className="mt-3">
      <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
      <Pagination.Prev onClick={() => setPage(p => Math.max(p - 1, 1))} disabled={page === 1} />
      {[...Array(totalPages)].map((_, idx) => {
        const pageNum = idx + 1;
        if (pageNum < page - 5 || pageNum > page + 5) return null;
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
  );

  return (
    <Container className="mt-4">
      <div className="d-flex justify-content-between align-items-center mb-3">
        <h2 className="pt-4">Склад: Документы</h2>
        {hasInsert && (
            <div className="pt-4">
          <Button variant="primary" onClick={createDocument}>
            <i class="fa-solid fa-plus pe-2"></i>Создать документ
          </Button>
          </div>
        )}
      </div>

      <Row className="mb-3">
        <Col md={4}>
          <Form.Select
            value={filterType}
            onChange={e => {
              setFilterType(e.target.value);
              setPage(1);
            }}
          >
            <option value="">Все типы документов</option>
            {categories.map(c => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </Form.Select>
        </Col>
      </Row>

      {loading ? (
        <Spinner animation="border" />
      ) : (
        <>
          <Row xs={1} md={2} lg={3} className="g-3">
            {documents.map(doc => (
              <Col key={doc.id}>
                <Card className="h-100">
                  <Card.Body>
                    <Card.Title>Документ №{doc.id}</Card.Title>
                    <Card.Text>
                      <strong>Дата:</strong>{" "}
                      {new Date(doc.date).toLocaleDateString()}
                      <br />
                      <strong>Сотрудник:</strong> {getEmployeeName(doc.id_employee)}
                      <br />
                      <strong>Тип документа:</strong> {getCategoryName(doc.id_document_category)}
                    </Card.Text>
                  </Card.Body>
                  <Card.Footer className="text-end">
                    <Button size="sm" onClick={() => openDocument(doc.id)}>
                      Открыть
                    </Button>
                  </Card.Footer>
                </Card>
              </Col>
            ))}
          </Row>

          {totalPages > 1 && (
            <div className="d-flex justify-content-center">{renderPagination()}</div>
          )}
        </>
      )}
    </Container>
  );
}
