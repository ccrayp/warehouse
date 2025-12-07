package report

import "time"

type ReportBatches struct {
	Id             int       `json:"id"`
	Name           string    `json:"name"`
	Cost           float32   `json:"cost"`
	ProductionDate time.Time `json:"production_date"`
	ExpirationDate time.Time `json:"expiration_date"`
}

type ReportDocumentsByEmployee struct {
	EmpoloyeeNumber  int    `json:"employee_number"`
	Employee         string `json:"employee"`
	Position         string `json:"position"`
	DocumentCategory string `json:"document_category"`
	Documents        int    `json:"documents"`
}

type ReportEmployees struct {
	Number      int       `json:"number"`
	Surname     string    `json:"surname"`
	Firstname   string    `json:"firstname"`
	Patronymic  string    `json:"patronymic"`
	Position    string    `json:"position"`
	PhoneNumber string    `json:"phone_number"`
	BirthDate   time.Time `json:"birth_date"`
}

type ReportExpiredBatches struct {
	Number            int       `json:"number"`
	BatchId           int       `json:"batch_id"`
	ProductName       string    `json:"product_name"`
	ExpirationDate    time.Time `json:"expiration_date"`
	RemainingQuantity int       `json:"remaining_quantity"`
}

type ReportGrants struct {
	Number     int    `json:"number"`
	Grantee    string `json:"grantee"`
	TableName  string `json:"table_name"`
	Privileges string `json:"privileges"`
}

type ReportNoProducts struct {
	Number       int    `json:"number"`
	Id           int    `json:"id"`
	ProductName  string `json:"product_name"`
	ProducerName string `json:"producer_name"`
}

type ReportProducerSubjectStatistics struct {
	Number           int    `json:"number"`
	Subject          string `json:"subject"`
	ProducerQuantity int    `json:"producers_quantity"`
	ProducerName     string `json:"producer_name"`
}

type ReportProductsLeft struct {
	Number       int    `json:"number"`
	IdProduct    int    `json:"id_product"`
	ProductName  string `json:"product_name"`
	ProducerName string `json:"procuder_name"`
	LeftQuantity int    `json:"left_quantity"`
}

type ReportSystemUsers struct {
	Number     int    `json:"number"`
	Role       string `json:"role"`
	Surname    string `json:"surname"`
	Firstname  string `json:"firstname"`
	Patronymic string `json:"patronymic"`
	Position   string `json:"position"`
}

type ReportTableActivityPerHour struct {
	Hour        int    `json:"hour"`
	ActionCount int    `json:"action_count"`
	Actors      string `json:"actors"`
}

type ReportTablesActivity struct {
	Number         int    `json:"number"`
	TableName      string `json:"table_name"`
	Action         string `json:"action"`
	Actors         string `json:"actors"`
	ActionQuantity int    `json:"action_quantity"`
}
