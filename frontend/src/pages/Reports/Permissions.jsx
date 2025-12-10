import UniversalReport from "../../common/UniversalReport";
import { useEffect, useState } from "react";
import { useApi } from "../../apiRequest";

export default function ReportPermissions() {
  const [rows, setRows] = useState([]);
  const { apiRequest } = useApi();

  useEffect(() => {
    apiRequest("/report/interface_grants", "GET").then((resp) => {
      if (resp.success) setRows(resp.data.report);
    });
  }, []);

  return (
    <UniversalReport
      title="Права доступа по ролям"
      section="report_interface_grants"
      rows={rows}
      columns={[
        { key: "role", label: "Роль" },
        { key: "section", label: "Раздел" },
        {
          key: "permissions",
          label: "Права",
          format: (val) => val.join(", ")
        }
      ]}
    />
  );
}
