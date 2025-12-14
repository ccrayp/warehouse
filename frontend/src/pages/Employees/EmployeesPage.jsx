import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import EemployeesCard from "./EmployeesCards";

export default function EmployeesPage() {
  return (
    <ProtectedPage section="employee">
      <EemployeesCard />
    </ProtectedPage>
  );
}
