package employee

import "time"

type Employee struct {
	ID          int       `json:"id"`
	Surname     string    `json:"surname"`
	Firstname   string    `json:"firstname"`
	Patronymic  string    `json:"patronymic"`
	IdGender    int       `json:"id_gender"`
	INN         string    `json:"inn"`
	PhoneNumber string    `json:"phone_number"`
	IdAddress   int       `json:"id_address"`
	BirthDate   time.Time `json:"birth_date"`
	IdPosition  int       `json:"id_position"`
}
