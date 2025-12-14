import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportProductsTotalSum() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/products_total_sum", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Суммарная стоимость товаров"
      section="report_products_total_sum"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "id_batch", label: "ID партии" },
        { key: "product_name", label: "Название товара" },
        { key: "cost", label: "Стоимость за 1 У.е." },
        { key: "left_quantity", label: "Остаток на складе" },
        { key: "total", label: "Суммарная стоимость" },
      ]}
    />
  );
}
