package producer

import (
	"context"
	"warehouse/pkg/database"
)

type ProducerRepository struct {
	db *database.Connector
}

func NewProducerRepository(db *database.Connector) *ProducerRepository {
	return &ProducerRepository{
		db: db,
	}
}

func (r *ProducerRepository) GetPagination(limit, offset int, role string) ([]Producer, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM producer LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}

	var producers []Producer

	for rows.Next() {
		var producer Producer

		err := rows.Scan(&producer.ID, &producer.Name, &producer.IdAddress, &producer.INN, &producer.Surname, &producer.Firstname, &producer.Patronymic)
		if err != nil {
			return nil, err
		}

		producers = append(producers, producer)
	}

	return producers, nil
}

func (r *ProducerRepository) GetById(id int, role string) (*Producer, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var producer Producer
	err = pool.QueryRow(context.Background(), "SELECT * FROM producer WHERE id = $1", id).Scan(&producer.ID, &producer.Name, &producer.IdAddress, &producer.INN, &producer.Surname, &producer.Firstname, &producer.Patronymic)
	if err != nil {
		return nil, err
	}

	return &producer, nil
}

func (r *ProducerRepository) Create(req ProducerRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(),
		"INSERT INTO producer (id, name, id_address, inn, surname, firstname, patronymic) VALUES (DEFAULT, $1, $2, $3, $4, $5, $6) RETURNING id",
		req.Name, req.IdAddress, req.INN, req.Surname, req.Firstname, req.Patronymic).
		Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *ProducerRepository) Update(req ProducerRequest, id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "UPDATE producer SET name = $1, id_address = $2, inn = $3, surname = $4, firstname = $5, patronymic = $6 WHERE id = $7",
		req.Name, req.IdAddress, req.INN, req.Surname, req.Firstname, req.Patronymic, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *ProducerRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM producer WHERE id = $1", id)
	if err != nil {
		return err
	}

	return nil
}
