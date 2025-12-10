import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportNoProducts() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/no_products", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Отсутствующие товары"
      section="report_no_products"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "id", label: "ID" },
        { key: "product_name", label: "Название товара" },
        { key: "producer_name", label: "Производитель" },
      ]}
    />
  );
}
