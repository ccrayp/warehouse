import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import EmployeesTable from "./EmployeesTable";

export default function EmployeesPage() {
  return (
    <ProtectedPage section="employee">
      <EmployeesTable />
    </ProtectedPage>
  );
}
