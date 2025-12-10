import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportProductsLeftByBatch() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/products_left_by_batch", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Остатки продуктов по партиям"
      section="report_products_left_by_batch"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "id_batch", label: "ID партии" },
        { key: "id_product", label: "ID продукта" },
        { key: "product_name", label: "Наименование продукта" },
        { key: "left_quantity", label: "Остаток" },
      ]}
    />
  );
}
