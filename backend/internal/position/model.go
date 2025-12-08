package position

type Position struct {
	Id          int    `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type PositionRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}
