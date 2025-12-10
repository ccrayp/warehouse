import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportDocumentsByEmployee() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/documents_by_employee", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Документы по сотрудникам"
      section="report_documents_by_employee"
      rows={rows}
      columns={[
        { key: "employee_number", label: "Табельный номер" },
        { key: "employee", label: "Сотрудник" },
        { key: "position", label: "Должность" },
        { key: "document_category", label: "Категория документа" },
        { key: "documents", label: "Количество документов" },
      ]}
    />
  );
}
