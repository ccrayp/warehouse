import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportSystemUsers() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/system_users", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Пользователи системы"
      section="report_system_users"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "role", label: "Роль" },
        { key: "surname", label: "Фамилия" },
        { key: "firstname", label: "Имя" },
        { key: "patronymic", label: "Отчество" },
        { key: "position", label: "Должность" },
      ]}
    />
  );
}
