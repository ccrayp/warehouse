package models

import "time"

type Document struct {
	ID                 int       `json:"id"`
	Date               time.Time `json:"date"`
	IdEmployee         int       `json:"id_employee"`
	IdDocumentCategory int       `json:"id_document_category"`
}

type DocumentRequest struct {
	Date               time.Time `json:"date"`
	IdEmployee         int       `json:"id_employee"`
	IdDocumentCategory int       `json:"id_document_category"`
}
