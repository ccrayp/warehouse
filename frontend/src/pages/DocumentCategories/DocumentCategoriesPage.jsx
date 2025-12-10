import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import DocumentCategoriesTable from "./DocumentCategoriesTable";

export default function DocumentCategoriesPage() {
  return (
    <ProtectedPage section="product">
      <DocumentCategoriesTable />
    </ProtectedPage>
  );
}
