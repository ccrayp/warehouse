import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import GenderTable from "./GendersTable";

export default function GendersPage() {
  return (
    <ProtectedPage section="gender">
      <GenderTable />
    </ProtectedPage>
  );
}
