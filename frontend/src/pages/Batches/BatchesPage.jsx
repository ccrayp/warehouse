import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import BatchesTable from "./BatchesTable";

export default function BatchesPage() {
  return (
    <ProtectedPage section="batch">
      <BatchesTable />
    </ProtectedPage>
  );
}
