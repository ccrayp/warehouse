import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import ProducersTable from "./ProducersTable";

export default function ProducersPage() {
  return (
    <ProtectedPage section="product">
      <ProducersTable />
    </ProtectedPage>
  );
}
