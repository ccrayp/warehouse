import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportNonFixedBacthes() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/non_fixed_batches", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Непринятые партии"
      section="report_non_fixed_batches"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "id_batch", label: "ID партии" },
        { key: "id_product", label: "ID товара" },
        { key: "product_name", label: "Название товара" },
      ]}
    />
  );
}
