import React from "react";
import ProtectedPage from "../../common/ProtectedPage";
import DocumentsItem from "./DocumentsItem";

export default function DocumentsItemPage() {
  return (
    <ProtectedPage section="document_content">
      <DocumentsItem />
    </ProtectedPage>
  );
}
