import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportExpiredBatches() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/expired_batches", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Просроченные партии"
      section="report_expired_batches"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "product_name", label: "Название товара" },
        {
          key: "expiration_date",
          label: "Срок годности",
          format: (v) => new Date(v).toLocaleDateString("ru-RU"),
        },
        { key: "remaining_quantity", label: "Остаток" },
      ]}
    />
  );
}
