import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import PositionsTable from "./PositionsTable";

export default function PositionsPage() {
  return (
    <ProtectedPage section="position">
      <PositionsTable />
    </ProtectedPage>
  );
}
