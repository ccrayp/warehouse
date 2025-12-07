package models

type Content struct {
	Id         int `json:"id"`
	IdDocument int `json:"id_document"`
	IdBatch    int `json:"id_batch"`
	Quantity   int `json:"quantity"`
}

type ContentRequest struct {
	IdDocument int `json:"id_document"`
	IdBatch    int `json:"id_batch"`
	Quantity   int `json:"quantity"`
}
