import { useState, useContext } from "react";
import { Link, useLocation } from "react-router-dom";
import { Offcanvas, Nav, Button, Alert } from "react-bootstrap";
import { AuthContext } from "../AuthContext";

export default function Sidebar() {
  const location = useLocation();
  const { loadUser, sections, role } = useContext(AuthContext);

  const [show, setShow] = useState(false);
  const handleShow = async () => {
    //await loadUser()
    setShow(true);
  }
  const handleClose = () => setShow(false);

  const sectionNames = {
    address: "Адреса",
    batch: "Партии",
    document: "Документы",
    document_category: "Категории документов",
    product: "Продукты",
    product_category: "Категории продуктов",
    producer: "Производители",
    employee: "Сотрудники",
    gender: "Пол",
    position: "Должности",
    sys_user: "Пользователи",
    role: "Роли",
    audit_log: "Логи"
  };

  const categories = [
    {
      title: "Склад",
      items: ["batch", "document", "product", "producer"]
    },
    {
      title: "Справочники",
      items: ["address", "employee", "gender", "position", "document_category", "product_category"]
    }
  ];

  // Администрирование доступно только admin
  const isAdmin = role && role["role"] === "admin";
  const adminCategory = {
    title: "Администрирование",
    items: ["sys_user", "role"]
  };

  const hasPermission = (sectionName) => sections.some(s => s.section === sectionName);

  if (sections.length !== 0) {
    return (
      <>
        <Button
          className="no-print"
          variant="outline-primary"
          onClick={handleShow}
          style={{ position: "fixed", top: 85, left: 15, zIndex: 100 }}
        >
          ☰
        </Button>

        <Offcanvas show={show} onHide={handleClose}>
          <Offcanvas.Header closeButton>
            <Offcanvas.Title>Меню</Offcanvas.Title>
          </Offcanvas.Header>
          <Offcanvas.Body>
            {sections.length === 0 ? (
              <Alert variant="info" className="text-center">
                Авторизуйтесь для доступа к меню
              </Alert>
            ) : (
              <Nav className="flex-column">
                {categories.map((cat, i) => {
                  const visibleItems = cat.items.filter(hasPermission);
                  if (visibleItems.length === 0) return null;

                  return (
                    <div key={i} style={{ marginBottom: "1rem" }}>
                      <strong className="mb-2 d-block">{cat.title}</strong>
                      {visibleItems.map((item, idx) => (
                        <Nav.Link
                          key={idx}
                          as={Link}
                          to={`/${item}`}
                          active={location.pathname === `/${item}`}
                          onClick={handleClose}
                          className="ps-3"
                        >
                          {sectionNames[item] || item}
                        </Nav.Link>
                      ))}
                    </div>
                  );
                })}

                {/* Отчеты */}
                {sections.some(s => s.section.startsWith("report_")) && (
                  <div style={{ marginBottom: "1rem" }}>
                    <strong className="mb-2 d-block">Отчеты</strong>
                    <Nav.Link
                      as={Link}
                      to="/report"
                      active={location.pathname === "/report"}
                      onClick={handleClose}
                      className="ps-3"
                    >
                      Все отчеты
                    </Nav.Link>
                  </div>
                )}

                {/* Администрирование */}
                {isAdmin && (
                  <>
                    <div style={{ marginBottom: "1rem" }}>
                      <strong className="mb-2 d-block">{adminCategory.title}</strong>
                      {adminCategory.items.filter(hasPermission).map((item, idx) => (
                        <Nav.Link
                          key={idx}
                          as={Link}
                          to={`/${item}`}
                          active={location.pathname === `/${item}`}
                          onClick={handleClose}
                          className="ps-3"
                        >
                          {sectionNames[item] || item}
                        </Nav.Link>
                      ))}
                    </div>

                    {/* Логи */}
                    {hasPermission("audit_log") && (
                      <div style={{ marginBottom: "1rem" }}>
                        <strong className="mb-2 d-block">Логи</strong>
                        <Nav.Link
                          as={Link}
                          to="/audit_log"
                          active={location.pathname === "/audit_log"}
                          onClick={handleClose}
                          className="ps-3"
                        >
                          Просмотр логов
                        </Nav.Link>
                      </div>
                    )}
                  </>
                )}
              </Nav>
            )}
          </Offcanvas.Body>
        </Offcanvas>
      </>
    );
  }
}
