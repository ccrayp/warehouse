package batch

import "time"

type Batch struct {
	ID             int       `json:"id"`
	Cost           float32   `json:"cost"`
	ProductionDate time.Time `json:"production_date"`
	ExpirationDate time.Time `json:"expiration_date"`
	IdProduct      int       `json:"id_product"`
	CreatedAt      time.Time `json:"created_at"`
}

type BatchCreateRequest struct {
	Cost           float32   `json:"cost"`
	ProductionDate time.Time `json:"production_date"`
	ExpirationDate time.Time `json:"expiration_date"`
	IdProduct      int       `json:"id_product"`
	CreatedAt      time.Time `json:"created_at"`
}

type BacthUpdateRequest struct {
	Cost           float32   `json:"cost"`
	ProductionDate time.Time `json:"production_date"`
	ExpirationDate time.Time `json:"expiration_date"`
	IdProduct      int       `json:"id_product"`
	CreatedAt      time.Time `json:"created_at"`
}

type BatchDeleteRequest struct {
	ID int `json:"int"`
}
