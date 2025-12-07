package producer

type Producer struct {
	ID         int    `json:"id"`
	Name       string `json:"name"`
	IdAddress  int    `json:"id_address"`
	INN        string `json:"inn"`        // char(10)
	Surname    string `json:"surname"`    // varchar(50)
	Firstname  string `json:"firstname"`  // varchar(50)
	Patronymic string `json:"patronymic"` // varchar(50)
}

type ProducerRequest struct {
	Name       string `json:"name"`
	IdAddress  int    `json:"id_address"`
	INN        string `json:"inn"`        // char(10)
	Surname    string `json:"surname"`    // varchar(50)
	Firstname  string `json:"firstname"`  // varchar(50)
	Patronymic string `json:"patronymic"` // varchar(50)
}

type ProducerDeleteRequst struct {
	ID int `json:"id"`
}
