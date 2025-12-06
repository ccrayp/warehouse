package product

// product
type Product struct {
	ID                int    `json:"id"`
	Name              string `json:"name"`
	IdProductCategory int    `json:"id_product_category"`
	IdProducer        int    `json:"id_producer"`
	ImageURL          string `json:"image_url"`
}

type ProductCreateRequest struct {
	Name              string `json:"name"`
	IdProductCategory int    `json:"id_product_category"`
	IdProducer        int    `json:"id_producer"`
	ImageURL          string `json:"image_url"`
}

type ProductUpdateRequest struct {
	Name              string `json:"name"`
	IdProductCategory int    `json:"id_product_category"`
	IdProducer        int    `json:"id_producer"`
	ImageURL          string `json:"image_url"`
}

type ProductDeleteRequest struct {
	ID int `json:"id"`
}
