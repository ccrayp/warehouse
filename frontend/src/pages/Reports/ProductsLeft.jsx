import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportProductsLeft() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/products_left", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Остатки товаров"
      section="report_products_left"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "product_name", label: "Название товара" },
        { key: "procuder_name", label: "Производитель" },
        { key: "left_quantity", label: "Остаток на складе" },
      ]}
    />
  );
}
