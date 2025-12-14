import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import ProducersCards from "./ProducersCards";

export default function ProducersPage() {
  return (
    <ProtectedPage section="product">
      <ProducersCards />
    </ProtectedPage>
  );
}
