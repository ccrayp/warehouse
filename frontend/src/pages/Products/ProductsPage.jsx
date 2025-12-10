import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import ProductsCards from "./ProductsCards";

export default function ProductsPage() {
  return (
    <ProtectedPage section="product">
      <ProductsCards />
    </ProtectedPage>
  );
}
