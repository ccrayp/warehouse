import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportGrants() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/grants", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Привилегии пользователей"
      section="report_grants"
      rows={rows}
      columns={[
        { key: "table_name", label: "Таблица" },
        { key: "admin", label: "Администратор" },
        { key: "manager", label: "Менеджер" },
        { key: "moderator", label: "Модератор" },
      ]}
    />
  );
}
