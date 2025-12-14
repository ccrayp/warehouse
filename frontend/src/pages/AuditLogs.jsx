import { useState, useEffect, useContext, useMemo } from "react";
import { Table, Spinner, Container, Pagination, Alert, Form, Row, Col } from "react-bootstrap";
import { AuthContext } from "../AuthContext";
import { useApi } from "../apiRequest";

const PAGE_SIZE = 10;

export default function AuditLogs() {
  const { role } = useContext(AuthContext);
  const { apiRequest } = useApi();

  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [totalLogs, setTotalLogs] = useState(0);
  const [error, setError] = useState("");

  const [filterRole, setFilterRole] = useState("");
  const [filterAction, setFilterAction] = useState("");
  const [filterTable, setFilterTable] = useState("");

  const fetchLogs = async (pageNumber = 1) => {
    if (role && role["role"] !== "admin") return;
    setLoading(true);
    setError("");
    const offset = (pageNumber - 1) * PAGE_SIZE;

    try {
      const data = await apiRequest(`/audit?limit=${PAGE_SIZE}&offset=${offset}`);
      if (data.success) {
        setLogs(data.data.logs || []);
        setTotalLogs(data.data.total || 0);
      } else {
        setError("Не удалось загрузить логи");
      }
    } catch (err) {
      console.error(err);
      setError("Ошибка при загрузке логов");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs(page);
  }, [page, role]);

  if (role && role["role"] !== "admin") {
    return (
      <Container>
        <Alert variant="danger" className="text-center mt-4">
          Доступ к логам только для администратора
        </Alert>
      </Container>
    );
  }

  // Фильтрация на фронтенде
  const filteredLogs = useMemo(() => {
    return logs.filter((log) => {
        const matchesRole = filterRole ? log.changer_by.toLowerCase().includes(filterRole.trim().toLowerCase()) : true;
        const matchesAction = filterAction ? log.action.toLowerCase().includes(filterAction.trim().toLowerCase()) : true;
        const matchesTable = filterTable ? log.table_name.toLowerCase().includes(filterTable.trim().toLowerCase()) : true;
        return matchesRole && matchesAction && matchesTable;
    });
    }, [logs, filterRole, filterAction, filterTable]);

  const totalPages = Math.ceil(totalLogs / PAGE_SIZE);

  return (
    <Container className="mt-2">
      <h2 className="pt-4 mb-3">Администрирование: Логи изменений</h2>

      {/* Фильтры */}
      <Form className="mb-3">
        <Row>
          <Col md={4} className="mb-2">
            <Form.Control
              placeholder="Фильтр по роли"
              value={filterRole}
              onChange={(e) => setFilterRole(e.target.value)}
            />
          </Col>
          <Col md={4} className="mb-2">
            <Form.Control
              placeholder="Фильтр по действию (INSERT, UPDATE, DELETE)"
              value={filterAction}
              onChange={(e) => setFilterAction(e.target.value)}
            />
          </Col>
          <Col md={4} className="mb-2">
            <Form.Control
              placeholder="Фильтр по таблице"
              value={filterTable}
              onChange={(e) => setFilterTable(e.target.value)}
            />
          </Col>
        </Row>
      </Form>

      {loading ? (
        <div className="d-flex justify-content-center py-5">
          <Spinner animation="border" />
        </div>
      ) : error ? (
        <Alert variant="danger">{error}</Alert>
      ) : filteredLogs.length === 0 ? (
        <Alert variant="info">Логи не найдены</Alert>
      ) : (
        <>
        {totalPages > 1 && (
            <div className="d-flex justify-content-center mt-2 mb-3">
                <Pagination>
                <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
                <Pagination.Prev onClick={() => setPage((p) => Math.max(p - 1, 1))} disabled={page === 1} />
                {[...Array(totalPages)].map((_, idx) => {
                    const pageNum = idx + 1;
                    if (pageNum < page - 7 || pageNum > page + 7) return null;
                    return (
                    <Pagination.Item key={pageNum} active={page === pageNum} onClick={() => setPage(pageNum)}>
                        {pageNum}
                    </Pagination.Item>
                    );
                })}

                <Pagination.Next onClick={() => setPage((p) => Math.min(p + 1, totalPages))} disabled={page === totalPages} />
                <Pagination.Last onClick={() => setPage(totalPages)} disabled={page === totalPages} />
                </Pagination>
            </div>
            )}
          <Table striped bordered hover responsive>
            <thead>
                <tr>
                <th>ID</th>
                <th>Таблица</th>
                <th>Действие</th>
                <th>Старые данные</th>
                <th>Новые данные</th>
                <th>Изменил</th>
                <th>Время изменения</th>
                </tr>
            </thead>
            <tbody>
                {filteredLogs.map((log) => (
                <tr key={log.id}>
                    <td>{log.id}</td>
                    <td>{log.table_name}</td>
                    <td>{log.action}</td>
                    <td style={{ maxWidth: "200px", wordBreak: "break-word" }}>
                    <pre style={{ whiteSpace: "pre-wrap", wordBreak: "break-word" }}>
                        {log.old_data ? JSON.stringify(log.old_data, null, 2) : "-"}
                    </pre>
                    </td>
                    <td style={{ maxWidth: "200px", wordBreak: "break-word" }}>
                    <pre style={{ whiteSpace: "pre-wrap", wordBreak: "break-word" }}>
                        {log.new_data ? JSON.stringify(log.new_data, null, 2) : "-"}
                    </pre>
                    </td>
                    <td>{log.changer_by}</td>
                    <td>
                      {new Date(log.changer_at).toLocaleString('ru-RU', {
                        hour12: false,
                        timeZone: 'UTC'
                      })}
                    </td>
                </tr>
                ))}
            </tbody>
            </Table>

          {totalPages > 1 && (
            <div className="d-flex justify-content-center mt-2 mb-3">
                <Pagination>
                <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
                <Pagination.Prev onClick={() => setPage((p) => Math.max(p - 1, 1))} disabled={page === 1} />
                {[...Array(totalPages)].map((_, idx) => {
                    const pageNum = idx + 1;
                    if (pageNum < page - 7 || pageNum > page + 7) return null;
                    return (
                    <Pagination.Item key={pageNum} active={page === pageNum} onClick={() => setPage(pageNum)}>
                        {pageNum}
                    </Pagination.Item>
                    );
                })}

                <Pagination.Next onClick={() => setPage((p) => Math.min(p + 1, totalPages))} disabled={page === totalPages} />
                <Pagination.Last onClick={() => setPage(totalPages)} disabled={page === totalPages} />
                </Pagination>
            </div>
            )}
        </>
      )}
    </Container>
  );
}
