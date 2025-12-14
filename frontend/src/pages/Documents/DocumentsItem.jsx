import { useEffect, useState, useContext, useMemo } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  Container,
  Button,
  Form,
  Table,
  Spinner,
  Alert
} from "react-bootstrap";
import { useApi } from "../../apiRequest";
import { AuthContext } from "../../AuthContext";

export default function DocumentsItemPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { apiRequest } = useApi();
  const { employee_id, sections } = useContext(AuthContext);

  /* ================= PERMISSIONS ================= */

  const hasSelect = sections?.some(
    s => s.section === "document" && s.permissions.includes("select")
  );
  const hasInsert = sections?.some(
    s => s.section === "document" && s.permissions.includes("insert")
  );
  const hasUpdate = sections?.some(
    s => s.section === "document" && s.permissions.includes("update")
  );
  const hasDelete = sections?.some(
    s => s.section === "document" && s.permissions.includes("delete")
  );

  if (!hasSelect) {
    return (
      <Container className="mt-4">
        <h3 style={{ color: "darkred" }}>Нет доступа</h3>
        <p>У вас нет прав для просмотра документов.</p>
      </Container>
    );
  }

  /* ================= STATE ================= */

  const isNew = id === "new";

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const [document, setDocument] = useState({
    date: new Date().toISOString().slice(0, 10),
    id_employee: Number(employee_id.employee_id),
    id_document_category: "",
  });

  const [categories, setCategories] = useState([]);
  const [contents, setContents] = useState([]);

  const [products, setProducts] = useState([]);
  const [batches, setBatches] = useState([]);
  const [batchesReport, setBatchesReport] = useState([]);

  const [newRow, setNewRow] = useState({
    id_batch: "",
    quantity: "",
    new_cost: "",
  });

  /* ================= LOADERS ================= */

  useEffect(() => {
    loadCategories();
    loadProducts();
    loadBatches();

    if (!isNew) {
      loadDocument();
      loadContents();
    }
  }, [id]);

  useEffect(() => {
    if (!document.id_document_category) return;
    loadBatchesByType();
  }, [document.id_document_category]);

  const loadCategories = async () => {
    const r = await apiRequest("/document_categories");
    setCategories(r.data?.document_categories || []);
  };

  const loadProducts = async () => {
    const r = await apiRequest("/products");
    setProducts(r.data?.products || []);
  };

  const loadBatches = async () => {
    const r = await apiRequest("/batches");
    setBatches(r.data?.batches || []);
  };

  const loadDocument = async () => {
    setLoading(true);
    const r = await apiRequest(`/documents/${id}`);
    const d = r.data.document;
    setDocument({
      date: d.date.slice(0, 10),
      id_employee: Number(d.id_employee),
      id_document_category: Number(d.id_document_category),
    });
    setLoading(false);
  };

  const loadContents = async () => {
    const r = await apiRequest(`/documents/${id}/contents`);
    setContents(r.data?.document_contens || []);
  };

  const loadBatchesByType = async () => {
    // Приёмка
    if (document.id_document_category === 1) {
      const r = await apiRequest("/report/non_fixed_batches");
      setBatchesReport(r.data?.report || []);
      return;
    }

    // Списание / Переоценка
    const r = await apiRequest("/report/products_left_by_batch");
    setBatchesReport(
      (r.data?.report || []).filter(b => b.left_quantity > 0)
    );
  };

  /* ================= HELPERS ================= */

  const productMap = useMemo(
    () => Object.fromEntries(products.map(p => [p.id, p.name])),
    [products]
  );

  const batchMap = useMemo(
    () => Object.fromEntries(batches.map(b => [b.id, b])),
    [batches]
  );

  const batchLabel = (id_batch) => {
    const b = batchMap[id_batch];
    if (!b) return `№${id_batch}`;
    return `№${id_batch} — ${productMap[b.id_product]} | ${b.cost} ₽`;
  };

  /* ================= SAVE DOCUMENT ================= */

  const saveDocument = async () => {
    if (isNew && !hasInsert) return alert("Нет прав на создание");
    if (!isNew && !hasUpdate) return alert("Нет прав на редактирование");

    const payload = {
      id_employee: document.id_employee,
      id_document_category: document.id_document_category,
      date: new Date(document.date).toISOString(),
    };

    if (isNew) {
      const r = await apiRequest("/documents", {
        method: "POST",
        body: JSON.stringify(payload),
      });
      navigate(`/documents/${r.data.id}`);
    } else {
      await apiRequest(`/documents/${id}`, {
        method: "PUT",
        body: JSON.stringify(payload),
      });
    }
  };

  /* ================= DELETE DOCUMENT ================= */

  const deleteDocument = async () => {
    if (!hasDelete) return alert("Нет прав на удаление");
    if (!window.confirm("Удалить документ (все связанные данные будут удалены)?")) return;

    await apiRequest(`/documents/${id}`, { method: "DELETE" });
    navigate("/documents");
  };

  /* ================= ADD ROW ================= */

  const addRow = async () => {
    if (!hasUpdate) return alert("Нет прав на изменение");

    const batch = batchesReport.find(
      b => String(b.id_batch) === String(newRow.id_batch)
    );
    if (!batch) return setError("Партия не найдена");

    let quantity = Number(newRow.quantity);

    // Переоценка → всё количество остатка
    if (document.id_document_category === 3) {
      quantity = batch.left_quantity;
    }

    await apiRequest("/documents/contents", {
      method: "POST",
      body: JSON.stringify({
        id_document: Number(id),
        id_batch: Number(newRow.id_batch),
        quantity,
      }),
    });

    // Переоценка → обновляем цену партии
    if (document.id_document_category === 3) {
      await apiRequest(`/batches/${newRow.id_batch}`, {
        method: "PUT",
        body: JSON.stringify({
          ...batchMap[newRow.id_batch],
          cost: Number(newRow.new_cost),
        }),
      });
    }

    setNewRow({ id_batch: "", quantity: "", new_cost: "" });
    loadContents();
    loadBatches();
    loadBatchesByType();
  };

  if (loading) return <Spinner />;

  /* ================= RENDER ================= */

  return (
    <Container className="mt-4">
      <h2 className="pt-4">{isNew ? "Склад: Создание документа" : `Склад: Документ №${id}`}</h2>

      {error && <Alert variant="danger">{error}</Alert>}

      <Form className="mb-4">
        <Form.Group className="mb-3">
          <Form.Label>Дата</Form.Label>
          <Form.Control
            type="date"
            value={document.date}
            disabled={!hasUpdate && !hasInsert}
            onChange={e => setDocument({ ...document, date: e.target.value })}
          />
        </Form.Group>

        <Form.Group className="mb-3">
          <Form.Label>Тип документа</Form.Label>
          <Form.Select
            value={document.id_document_category}
            disabled={!hasUpdate && !hasInsert}
            onChange={e =>
              setDocument({ ...document, id_document_category: Number(e.target.value) })
            }
          >
            <option value="">Выберите тип</option>
            {categories.map(c => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
          </Form.Select>
        </Form.Group>

        {(hasInsert || hasUpdate) && (
          <Button className="me-2" onClick={saveDocument}>Сохранить</Button>
        )}
        {!isNew && hasDelete && (
          <Button variant="danger" onClick={deleteDocument}>Удалить</Button>
        )}
      </Form>

      {!isNew && (
        <>
          <h4>Содержимое</h4>

          <Table bordered>
            <thead>
              <tr>
                <th>Партия</th>
                <th>Количество</th>
                {document.id_document_category === 3 && <th>Новая цена</th>}
              </tr>
            </thead>
            <tbody>
              {contents.map(c => (
                <tr key={c.id}>
                  <td>{batchLabel(c.id_batch)}</td>
                  <td>{c.quantity}</td>
                  {document.id_document_category === 3 && <td>—</td>}
                </tr>
              ))}

              {hasUpdate && (
                <tr>
                  <td>
                    <Form.Select
                      value={newRow.id_batch}
                      onChange={e => setNewRow({ ...newRow, id_batch: e.target.value })}
                    >
                      <option value="">Партия</option>
                      {batchesReport.map(b => (
                        <option key={b.id_batch} value={b.id_batch}>
                          {batchLabel(b.id_batch)}
                        </option>
                      ))}
                    </Form.Select>
                  </td>

                  <td>
                    {document.id_document_category === 3 ? "Авто" : (
                      <Form.Control
                        type="number"
                        value={newRow.quantity}
                        onChange={e =>
                          setNewRow({ ...newRow, quantity: e.target.value })
                        }
                      />
                    )}
                  </td>

                  {document.id_document_category === 3 && (
                    <td>
                      <Form.Control
                        type="number"
                        placeholder="Новая цена"
                        value={newRow.new_cost}
                        onChange={e =>
                          setNewRow({ ...newRow, new_cost: e.target.value })
                        }
                      />
                    </td>
                  )}
                </tr>
              )}
            </tbody>
          </Table>

          {hasUpdate && <Button onClick={addRow}>Добавить строку</Button>}
        </>
      )}
    </Container>
  );
}
