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

const PAGE_SIZE = 8;

export default function ProductsCards() {
  const { apiRequest, getImageUrl } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "product" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "product" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "product" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "product" && s.permissions.includes("delete"));

  if (!hasSelect) {
    return (
      <Container style={{ padding: "40px" }}>
        <h2 style={{ color: "darkred" }}>Нет доступа</h2>
        <p>У вас нет прав для просмотра этого раздела.</p>
      </Container>
    );
  }

  const [products, setProducts] = useState([]);
  const [categories, setCategories] = useState([]);
  const [producers, setProducers] = useState([]);

  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState("");

  const [searchQuery, setSearchQuery] = useState("");
  const [filterCategory, setFilterCategory] = useState("");

  const [showModal, setShowModal] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);

  const [form, setForm] = useState({
    name: "",
    id_product_category: "",
    id_producer: "",
    image: null,
    existingImage: ""
  });

  const [saving, setSaving] = useState(false);

  // ================== DATA ==================

  const fetchData = async (pageNum = 1) => {
    setLoading(true);
    setError("");

    const offset = (pageNum - 1) * PAGE_SIZE;

    const params = new URLSearchParams({
      limit: PAGE_SIZE,
      offset
    });

    if (searchQuery) params.append("q", searchQuery);
    if (filterCategory) params.append("category_id", filterCategory);

    try {
      const [prodResp, catResp, prodResp2] = await Promise.all([
        apiRequest(`/products?${params.toString()}`),
        apiRequest("/product_categories"),
        apiRequest("/producers")
      ]);

      if (prodResp.success) {
        setProducts(prodResp.data.products || []);
        setTotal(prodResp.data.total || 0);
      } else {
        setError(prodResp.message || "Ошибка при загрузке продуктов");
      }

      if (catResp.success) setCategories(catResp.data.product_categories || []);
      if (prodResp2.success) setProducers(prodResp2.data.producers || []);
    } catch (err) {
      console.error(err);
      setError("Ошибка при запросе данных");
    } finally {
      setLoading(false);
    }
  };

  // ================== EFFECTS ==================

  useEffect(() => {
    fetchData(page);
  }, [page]);

  useEffect(() => {
    setPage(1);
    fetchData(1);
  }, [searchQuery, filterCategory]);

  // ================== HANDLERS ==================

  const handleSearchChange = (e) => setSearchQuery(e.target.value);
  const handleCategoryChange = (e) => setFilterCategory(e.target.value);

  const handleShowModal = (product = null) => {
    setEditingProduct(product);
    setForm({
      name: product?.name || "",
      id_product_category: product?.id_product_category || "",
      id_producer: product?.id_producer || "",
      image: null,
      existingImage: product?.image_url || ""
    });
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
    setEditingProduct(null);
    setForm({
      name: "",
      id_product_category: "",
      id_producer: "",
      image: null,
      existingImage: ""
    });
  };

  const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.name.trim()) return alert("Название обязательно");
    if (!form.id_product_category) return alert("Выберите категорию");
    if (!form.id_producer) return alert("Выберите производителя");

    setSaving(true);
    try {
      const payload = {
        name: form.name.trim(),
        id_product_category: Number(form.id_product_category),
        id_producer: Number(form.id_producer),
        ...(form.image ? {} : { image_url: form.existingImage })
      };

      let resp;
      if (editingProduct) {
        resp = await apiRequest(`/products/${editingProduct.id}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
      } else {
        resp = await apiRequest("/products", {
          method: "POST",
          body: JSON.stringify(payload)
        });
      }

      if (!resp.success) throw new Error(resp.message || "Ошибка сохранения");

      if (form.image) {
        const fd = new FormData();
        fd.append("image", form.image);
        await apiRequest(`/products/image/${resp.data?.id || editingProduct.id}`, {
          method: "POST",
          body: fd
        });
      }

      fetchData(page);
      handleCloseModal();
    } catch (err) {
      //alert(err.message);
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (product) => {
    if (!hasDelete) return;
    if (!window.confirm(`Удалить "${product.name}"? (все связанные данные будут удалены)`)) return;

    const resp = await apiRequest(`/products/${product.id}`, { method: "DELETE" });
    if (resp.success) {
      handleCloseModal();
      fetchData(page);
    }
    else alert(resp.message || "Ошибка удаления");
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  // ================== RENDER ==================

  return (
    <Container className="mt-4">
      <h2 className="pt-4">Склад: Продукты</h2>

      {/* FILTERS */}
      <Row className="mb-3">
        <Col md={4}>
          <Form.Control
            placeholder="Поиск по названию"
            value={searchQuery}
            onChange={handleSearchChange}
          />
        </Col>

        <Col md={4}>
          <Form.Select value={filterCategory} onChange={handleCategoryChange}>
            <option value="">Все категории</option>
            {categories.map(c => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </Form.Select>
        </Col>

        <Col md={4} className="text-end">
          {hasInsert && (
            <Button onClick={() => handleShowModal()}>
              <i className="fa-solid fa-plus pe-2" />
              Добавить продукт
            </Button>
          )}
        </Col>
      </Row>

      {loading ? (
        <Spinner animation="border" />
      ) : error ? (
        <Alert variant="danger">{error}</Alert>
      ) : products.length === 0 ? (
        <Alert variant="info">Продукты не найдены</Alert>
      ) : (
        <>
          <Row xs={1} md={3} lg={4} className="g-3">
            {products.map(prod => (
              <Col key={prod.id}>
                <Card className="h-100" onClick={() => handleShowModal(prod)} style={{ cursor: "pointer" }}>
                  <Card.Img
                    variant="top"
                    src={getImageUrl(prod.image_url)}
                    style={{ objectFit: "contain", height: "200px" }}
                    className="mt-3"
                  />
                  <Card.Body>
                    <Card.Title>{prod.name}</Card.Title>
                    <Card.Text>
                      Категория: {categories.find(c => c.id === prod.id_product_category)?.name || "-"}<br />
                      Производитель: {producers.find(p => p.id === prod.id_producer)?.name || "-"}
                    </Card.Text>
                  </Card.Body>
                </Card>
              </Col>
            ))}
          </Row>
          {products.length > 0 && <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
          * Для редактирования или удаления нажмите на карточку
        </p>}
          {totalPages > 1 && (
            <div className="d-flex justify-content-center mt-3">
              <Pagination>
                <Pagination.First onClick={() => setPage(1)} disabled={page === 1} />
                <Pagination.Prev onClick={() => setPage(p => Math.max(p - 1, 1))} disabled={page === 1} />
                {[...Array(totalPages)].map((_, i) => {
                  const p = i + 1;
                  if (p < page - 7 || p > page + 7) return null;
                  return (
                    <Pagination.Item key={p} active={page === p} onClick={() => setPage(p)}>
                      {p}
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

      {/* MODAL */}
      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
          <Modal.Title>{editingProduct ? "Редактировать продукт" : "Создать продукт"}</Modal.Title>
        </Modal.Header>

        <Modal.Body>
          <Form>
            <Form.Group className="mb-2">
              <Form.Label>Название</Form.Label>
              <Form.Control
                value={form.name}
                maxLenght={100}
                minLenght={1}
                onChange={e => setForm({ ...form, name: e.target.value })}
              />
            </Form.Group>

            <Form.Group className="mb-2">
              <Form.Label>Категория</Form.Label>
              <Form.Select
                value={form.id_product_category}
                onChange={e => setForm({ ...form, id_product_category: e.target.value })}
              >
                <option value="">Выберите категорию</option>
                {categories.map(c => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </Form.Select>
            </Form.Group>

            <Form.Group className="mb-2">
              <Form.Label>Производитель</Form.Label>
              <Form.Select
                value={form.id_producer}
                onChange={e => setForm({ ...form, id_producer: e.target.value })}
              >
                <option value="">Выберите производителя</option>
                {producers.map(p => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </Form.Select>
            </Form.Group>

            <Form.Group>
              <Form.Label>Картинка</Form.Label>
              <Form.Control
                type="file"
                accept="image/*"
                onChange={e => setForm({ ...form, image: e.target.files[0] })}
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
          {editingProduct && hasDelete && (
            <Button variant="danger" onClick={() => handleDelete(editingProduct)}>
              Удалить
            </Button>
          )}
        </Modal.Footer>
      </Modal>
    </Container>
  );
}
