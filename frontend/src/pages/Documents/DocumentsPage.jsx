import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import DocumentsCards from "./DocumentsCards";

export default function DocumentsPage() {
  return (
    <ProtectedPage section="document">
      <DocumentsCards />
    </ProtectedPage>
  );
}
