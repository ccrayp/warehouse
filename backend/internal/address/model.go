package address

type Address struct {
	Id       int    `json:"id"`
	Subject  string `json:"subject"`  // varchar(100)
	Region   string `json:"region"`   // varchar(100)
	City     string `json:"city"`     // varchar(100)
	Street   string `json:"street"`   // varchar(100)
	Building int    `json:"building"` // varchar(100)
}

type AddressRequest struct {
	Subject  string `json:"subject"`  // varchar(100)
	Region   string `json:"region"`   // varchar(100)
	City     string `json:"city"`     // varchar(100)
	Street   string `json:"street"`   // varchar(100)
	Building int    `json:"building"` // varchar(100)
}
