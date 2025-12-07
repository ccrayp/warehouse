package documentcategory

type DocumentCategory struct {
	Id          int    `json:"id"`
	Name        string `json:"name"` // varchar(50)
	Description string `json:"description"`
}

type DocumentCategoryRequest struct {
	Name        string `json:"name"` // varchar(50)
	Description string `json:"description"`
}
