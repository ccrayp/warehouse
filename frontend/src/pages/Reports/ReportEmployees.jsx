import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportEmployees() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/employees", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Сотрудники"
      section="report_employees"
      rows={rows}
      columns={[
        { key: "number", label: "№" },
        { key: "surname", label: "Фамилия" },
        { key: "firstname", label: "Имя" },
        { key: "patronymic", label: "Отчество" },
        { key: "position", label: "Должность" },
        { key: "phone_number", label: "Телефон" },
        {
          key: "birth_date",
          label: "Дата рождения",
          format: (v) => new Date(v).toLocaleDateString("ru-RU"),
        },
      ]}
    />
  );
}
