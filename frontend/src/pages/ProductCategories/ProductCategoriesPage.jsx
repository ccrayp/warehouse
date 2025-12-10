import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import ProductCategoriesTable from "./ProductCategoriesTable";

export default function ProductsCategoriesPage() {
  return (
    <ProtectedPage section="product">
      <ProductCategoriesTable />
    </ProtectedPage>
  );
}
