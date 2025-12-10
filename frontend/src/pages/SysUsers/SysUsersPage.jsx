import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import SysUsersTable from "./SysUsersTable";

export default function SysUsersPage() {
  return (
    <ProtectedPage section="sys_user">
      <SysUsersTable />
    </ProtectedPage>
  );
}
