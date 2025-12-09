import React, { useState } from "react";
import { Container, Row, Col, Card, Button, Form } from "react-bootstrap";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faTable, faChartBar } from "@fortawesome/free-solid-svg-icons";

const reports = [
  { id: "report_batches", name: "Принятые партии", description: "Информация о принятых партиях товара", type: "table" },
  { id: "report_documents_by_employee", name: "Документы по сотрудникам", description: "Список сотрудников и количество документов, оформленных ими", type: "table" },
  { id: "report_employees", name: "Сотрудники", description: "Информация о сотрудниках компании", type: "table" },
  { id: "report_expired_batches", name: "Просроченные партии", description: "Информация о просроченных партиях товара", type: "table" },
  { id: "report_grants", name: "Права ролей", description: "Права для ролей в информационной системе", type: "table" },
  { id: "report_interface_grants", name: "Доступные разделы", description: "Доступные разделы и права пользователей", type: "table" },
  { id: "report_no_products", name: "Отсутствующие товары", description: "Список товаров, которых нет на складе", type: "table" },
  { id: "report_producer_subject_statistics", name: "Производители по регионам", description: "Количество производителей по регионам", type: "chart" },
  { id: "report_products_left", name: "Остатки продукции", description: "Остатки продукции на складе", type: "table" },
  { id: "report_products_left_by_batch", name: "Остатки по партиям", description: "Остаток продукции из каждой партии", type: "table" },
  { id: "report_system_users", name: "Пользователи системы", description: "Список пользователей системы", type: "table" },
  { id: "report_tables_activity", name: "Активность по таблицам", description: "Активность по таблицам за последние 7 дней", type: "chart" },
  { id: "report_tables_activity_per_hour", name: "Активность по часам", description: "Активность по таблицам за каждый час за последний месяц", type: "chart" },
];

export default function ReportsPage() {
  const [filterType, setFilterType] = useState("all");
  const [search, setSearch] = useState("");

  const filteredReports = reports.filter((r) => {
    const matchesType = filterType === "all" || r.type === filterType;
    const matchesSearch = r.name.toLowerCase().includes(search.toLowerCase()) 
                          || r.description.toLowerCase().includes(search.toLowerCase());
    return matchesType && matchesSearch;
  });

  return (
    <Container className="mt-4">
      <h2>Выберите отчет</h2>

      <Row className="mb-4 gx-3">
        <Col md={4} lg={3}>
          <Form.Control
            placeholder="Поиск по названию или описанию"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </Col>
        <Col md={4} lg={3}>
          <Form.Select value={filterType} onChange={(e) => setFilterType(e.target.value)}>
            <option value="all">Все типы</option>
            <option value="table">Таблица</option>
            <option value="chart">Диаграмма</option>
          </Form.Select>
        </Col>
      </Row>

      <Row>
        {filteredReports.map((report) => (
          <Col md={4} lg={3} className="mb-4" key={report.id}>
            <Card className="h-100">
              <Card.Body className="d-flex flex-column">
                <div className="mb-3 text-start">
                  <FontAwesomeIcon
                    icon={report.type === "table" ? faTable : faChartBar}
                    size="3x"
                  />
                </div>
                <Card.Title>{report.name}</Card.Title>
                <Card.Text style={{ flexGrow: 1 }}>{report.description}</Card.Text>
                <Card.Text>
                  <strong>Тип:</strong> {report.type === "table" ? "Таблица" : "Диаграмма"}
                </Card.Text>
                <Button
                  variant="primary"
                  href={`/reports/${report.id}`}
                  className="mt-auto"
                >
                  Открыть отчет
                </Button>
              </Card.Body>
            </Card>
          </Col>
        ))}
      </Row>
    </Container>
  );
}
