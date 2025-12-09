package position

import (
	"context"
	"warehouse/pkg/database"
)

type PositionRepository struct {
	db *database.Connector
}

func NewPositionRepository(db *database.Connector) *PositionRepository {
	return &PositionRepository{
		db: db,
	}
}

func (r *PositionRepository) GetAll(role string) ([]Position, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var positions []Position

	rows, err := pool.Query(context.Background(), "SELECT * FROM position")
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		var position Position

		err := rows.Scan(&position.Id, &position.Name, &position.Description)
		if err != nil {
			return nil, err
		}

		positions = append(positions, position)
	}

	return positions, nil
}

func (r *PositionRepository) GetPagination(limit, offset int, role string) ([]Position, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var positions []Position

	rows, err := pool.Query(context.Background(), "SELECT * FROM position LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		var position Position

		err := rows.Scan(&position.Id, &position.Name, &position.Description)
		if err != nil {
			return nil, err
		}

		positions = append(positions, position)
	}

	return positions, nil
}

func (r *PositionRepository) GetById(id int, role string) (*Position, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var position Position
	err = pool.QueryRow(context.Background(), "SELECT * FROM position WHERE id = $1", id).
		Scan(&position.Id, &position.Name, &position.Description)
	if err != nil {
		return nil, err
	}

	return &position, nil
}

func (r *PositionRepository) Create(req PositionRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO position (id, name, description) VALUES (DEFAULT, $1, $2) RETURNING id", req.Name, req.Description).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *PositionRepository) Update(req PositionRequest, id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil
	}

	_, err = pool.Exec(context.Background(), "UPDATE position SET name = $1, description = $2 WHERE id = $3", req.Name, req.Description, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *PositionRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM position WHERE id = $1", id)
	if err != nil {
		return err
	}

	return nil
}
