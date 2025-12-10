import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import AddressesTable from "./AddressesTable";

export default function AddressesPage() {
  return (
    <ProtectedPage section="address">
      <AddressesTable />
    </ProtectedPage>
  );
}
