// pages/Admin/Roles.jsx
import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import RolesTable from "./RolesTable";

export default function RolesPage() {
  return (
    <ProtectedPage section="role">
      <RolesTable />
    </ProtectedPage>
  );
}
