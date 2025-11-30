package gender

import (
	"context"
	"warehouse/pkg/database"
)

type GenderRepository struct {
	db *database.Connector
}

func NewGenderRepository(db *database.Connector) *GenderRepository {
	return &GenderRepository{
		db: db,
	}
}

func (r *GenderRepository) GetAll(role string) ([]Gender, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM gender")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var genders []Gender
	for rows.Next() {
		var gender Gender
		err := rows.Scan(&gender.ID, &gender.Sign)
		if err != nil {
			return nil, err
		}

		genders = append(genders, gender)
	}

	return genders, nil
}

func (r *GenderRepository) GetById(id int, role string) (*Gender, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var gender Gender
	err = pool.QueryRow(context.Background(), "SELECT * FROM gender WHERE id=$1", id).Scan(&gender.ID, &gender.Sign)
	if err != nil {
		return nil, err
	}

	return &gender, err
}
