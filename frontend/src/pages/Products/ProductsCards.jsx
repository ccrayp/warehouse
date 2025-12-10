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

export default function ProductsCards() {
  const { apiRequest, getImageUrl } = useApi();
  const { sections } = useContext(AuthContext);

  const hasSelect = sections?.some(s => s.section === "product" && s.permissions.includes("select"));
  const hasInsert = sections?.some(s => s.section === "product" && s.permissions.includes("insert"));
  const hasUpdate = sections?.some(s => s.section === "product" && s.permissions.includes("update"));
  const hasDelete = sections?.some(s => s.section === "product" && s.permissions.includes("delete"));

  if (!hasSelect) return (
    <Container style={{ padding: "40px" }}>
      <h2 style={{ color: "darkred" }}>Нет доступа</h2>
      <p>У вас нет прав для просмотра этого раздела.</p>
    </Container>
  );

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
    image: null
  });
  const [saving, setSaving] = useState(false);

  const fetchData = async (pageNum = 1) => {
    setLoading(true);
    setError("");
    const offset = (pageNum - 1) * PAGE_SIZE;

    try {
      const [prodResp, catResp, prodcrResp] = await Promise.all([
        apiRequest(`/products?limit=${PAGE_SIZE}&offset=${offset}` + (searchQuery ? `&q=${encodeURIComponent(searchQuery)}` : "")),
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
      if (prodcrResp.success) setProducers(prodcrResp.data.producers || []);
    } catch (err) {
      console.error(err);
      setError("Ошибка при запросе данных");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData(page);
  }, [page, searchQuery]);

  const filteredProducts = filterCategory
    ? products.filter(p => p.id_product_category === Number(filterCategory))
    : products;

  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value);
    setPage(1);
  };

  const handleCategoryChange = (e) => {
    setFilterCategory(e.target.value);
  };


  const handleCloseModal = () => {
    setShowModal(false);
    setEditingProduct(null);
    setForm({ name: "", id_product_category: "", id_producer: "", image: null });
  };

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

    const handleSave = async () => {
    if (!(hasInsert || hasUpdate)) return;

    if (!form.name.trim()) {
        alert("Название обязательно");
        return;
    }
    if (!form.id_product_category || !categories.some(c => c.id === Number(form.id_product_category))) {
        alert("Выберите корректную категорию");
        return;
    }
    if (!form.id_producer || !producers.some(p => p.id === Number(form.id_producer))) {
        alert("Выберите корректного производителя");
        return;
    }

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

        if (!resp.success) throw new Error(resp.message || "Ошибка при сохранении продукта");

        if (form.image) {
        const formData = new FormData();
        formData.append("image", form.image);
        await apiRequest(`/products/image/${resp.data?.id || editingProduct.id}`, {
            method: "POST",
            body: formData
        });
        }

        fetchData(page);
        handleCloseModal();
    } catch (err) {
        console.error(err);
        alert(err.message || "Ошибка при сохранении продукта");
    } finally {
        setSaving(false);
    }
    };

  const handleDelete = async (product) => {
    if (!hasDelete) return;
    if (!window.confirm(`Удалить продукт "${product.name}"?`)) return;

    try {
      const resp = await apiRequest(`/products/${product.id}`, { method: "DELETE" });
      if (resp.success) {
        handleCloseModal()
        fetchData(page);
      } else {
        alert(resp.message || "Ошибка при удалении продукта");
      }
    } catch (err) {
      console.error(err);
      alert("Ошибка при удалении продукта");
    }
  };

  const totalPages = Math.ceil(total / PAGE_SIZE);

  const renderPagination = () => (
    <Pagination className="mt-2">
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
      <h2 className="pt-4">Склад: Продукты</h2>

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
            {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
          </Form.Select>
        </Col>
        <Col md={4} className="text-end">
          {hasInsert && <Button onClick={() => handleShowModal()}>Добавить продукт</Button>}
        </Col>
      </Row>

      {loading ? (
        <Spinner animation="border" />
      ) : error ? (
        <Alert variant="danger">{error}</Alert>
      ) : filteredProducts.length === 0 ? (
        <Alert variant="info">Продукты не найдены</Alert>
      ) : (
        <>
          <Row xs={1} md={3} lg={4} className="g-3">
            {filteredProducts.map(prod => (
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
            {products.length > 0 && (
            <p style={{ color: "#666", fontSize: "14px", marginTop: "8px" }}>
              * Для получения ID, редактирования или удаления нажмите на соответствующую карточку
            </p>
          )}
          {totalPages > 1 && <div className="d-flex justify-content-center mt-2">{renderPagination()}</div>}
        </>
      )}

      <Modal show={showModal} onHide={handleCloseModal}>
        <Modal.Header closeButton>
            <Modal.Title>{editingProduct ? "Редактировать продукт" : "Создать продукт"}</Modal.Title>
        </Modal.Header>
        <Modal.Body>
            <Form>
                <Form.Group className="mb-3">
                <Form.Label>ID</Form.Label>
                <Form.Control
                type="text"
                value={editingProduct?.id || ""}
                disabled
                />
            </Form.Group>
            <Form.Group className="mb-3">
                <Form.Label>Название</Form.Label>
                <Form.Control
                type="text"
                value={form.name}
                onChange={e => setForm({ ...form, name: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                />
            </Form.Group>
            <Form.Group className="mb-3">
                <Form.Label>Категория</Form.Label>
                <Form.Select
                value={form.id_product_category}
                onChange={e => setForm({ ...form, id_product_category: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                >
                <option value="">Выберите категорию</option>
                {categories.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
                <Form.Label>Производитель</Form.Label>
                <Form.Select
                value={form.id_producer}
                onChange={e => setForm({ ...form, id_producer: e.target.value })}
                disabled={!hasInsert && !hasUpdate}
                >
                <option value="">Выберите производителя</option>
                {producers.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </Form.Select>
            </Form.Group>
            <Form.Group className="mb-3">
                <Form.Label>Картинка</Form.Label>
                <Form.Control
                type="file"
                accept="image/*"
                onChange={e => setForm({ ...form, image: e.target.files[0] })}
                disabled={!hasInsert && !hasUpdate}
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
            <Button variant="danger" onClick={() => handleDelete(editingProduct)}>Удалить</Button>
            )}
        </Modal.Footer>
        </Modal>
    </Container>
  );
}
