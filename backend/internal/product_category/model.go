package models

// product_category
type ProductCategory struct {
	ID   int    `json:"id"`
	Name string `json:"name"`
}

type ProductCategoryCreateRequest struct {
	Name string `json:"name"`
}

type ProductCategoryUpdateRequest struct {
	Name string `json:"name"`
}

type ProductCategoryDeleteRequest struct {
	ID int `json:"id"`
}
