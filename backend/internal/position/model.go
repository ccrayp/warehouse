package position

type Position struct {
	Id          int    `json:"in"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type PositionRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}
