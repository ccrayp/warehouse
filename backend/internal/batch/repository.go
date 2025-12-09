package batch

import (
	"context"
	"fmt"
	"warehouse/pkg/database"
)

type BatchRepository struct {
	db *database.Connector
}

func NewBatchRepository(db *database.Connector) *BatchRepository {
	return &BatchRepository{
		db: db,
	}
}

func (r *BatchRepository) GetAll(role string) ([]Batch, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM batch ORDER BY created_at DESC")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var batches []Batch

	for rows.Next() {
		var batch Batch

		err = rows.Scan(&batch.ID, &batch.Cost, &batch.ProductionDate, &batch.ExpirationDate, &batch.IdProduct, &batch.CreatedAt)
		if err != nil {
			return nil, err
		}

		batches = append(batches, batch)
	}

	return batches, nil
}

func (r *BatchRepository) GetPagination(limit, offset int, role string) ([]Batch, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM batch ORDER BY created_at DESC LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var batches []Batch

	for rows.Next() {
		var batch Batch

		err = rows.Scan(&batch.ID, &batch.Cost, &batch.ProductionDate, &batch.ExpirationDate, &batch.IdProduct, &batch.CreatedAt)
		if err != nil {
			return nil, err
		}

		batches = append(batches, batch)
	}

	return batches, nil
}

func (r *BatchRepository) GetById(id int, role string) (*Batch, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var batch Batch
	err = pool.QueryRow(context.Background(), "SELECT * FROM batch WHERE id=$1", id).Scan(&batch.ID, &batch.Cost, &batch.ProductionDate, &batch.ExpirationDate, &batch.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &batch, nil
}

func (r *BatchRepository) Create(batch BatchCreateRequest, role string) (*Batch, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var newBatch Batch
	err = pool.QueryRow(context.Background(), "INSERT INTO batch VALUES (DEFAULT, $1, $2, $3, $4, DEFAULT) RETURNING id, cost, production_date, expiration_date, id_product, created_at", batch.Cost, batch.ProductionDate, batch.ExpirationDate, batch.IdProduct).
		Scan(&newBatch.ID, &newBatch.Cost, &newBatch.ProductionDate, &newBatch.ExpirationDate, &newBatch.IdProduct, &newBatch.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &newBatch, nil
}

func (r *BatchRepository) Update(batch BacthUpdateRequest, id int, role string) (*Batch, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var updatedBatch Batch
	err = pool.QueryRow(context.Background(),
		"UPDATE batch SET cost=$1, production_date=$2, expiration_date=$3, id_product=$4 WHERE id=$5 RETURNING id, cost, production_date, expiration_date, id_product, created_at", batch.Cost, batch.ProductionDate, batch.ExpirationDate, batch.IdProduct, id).
		Scan(&updatedBatch.ID, &updatedBatch.Cost, &updatedBatch.ProductionDate, &updatedBatch.ExpirationDate, &updatedBatch.IdProduct, &updatedBatch.CreatedAt)

	if err != nil {
		return nil, err
	}

	return &updatedBatch, nil
}

func (r *BatchRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	cmd, err := pool.Exec(context.Background(), "DELETE FROM batch WHERE id=$1", id)
	if err != nil {
		return err
	}

	if cmd.RowsAffected() == 0 {
		return fmt.Errorf("ERROR: no rows were affected")
	}

	return nil
}

func (r *BatchRepository) LeftIn(id int, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var quantity int
	err = pool.QueryRow(context.Background(), "SELECT left_quantity FROM report_products_left_by_batch WHERE id_batch = $1", id).Scan(&quantity)
	if err != nil {
		return nil, err
	}

	return &quantity, nil
}
