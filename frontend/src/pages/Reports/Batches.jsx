import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportBatches() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/batches", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Принятые партии"
      section="report_batches"
      rows={rows}
      columns={[
        { key: "id", label: "ID" },
        { key: "name", label: "Название товара" },
        { key: "cost", label: "Стоимость" },
        {
          key: "production_date",
          label: "Дата производства",
          format: (v) => new Date(v).toLocaleDateString("ru-RU"),
        },
        {
          key: "expiration_date",
          label: "Срок годности",
          format: (v) => new Date(v).toLocaleDateString("ru-RU"),
        },
      ]}
    />
  );
}
