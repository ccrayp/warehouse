package documentcategory

import (
	"context"
	"warehouse/pkg/database"
)

type DocumentCategoryRepository struct {
	db *database.Connector
}

func NewDocumentCategoryRepository(db *database.Connector) *DocumentCategoryRepository {
	return &DocumentCategoryRepository{
		db: db,
	}
}

func (r *DocumentCategoryRepository) GetPagination(limit, offset int, role string) ([]DocumentCategory, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var documentCategories []DocumentCategory

	rows, err := pool.Query(context.Background(), "SELECT * FROM document_category LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		var documentCategory DocumentCategory

		err := rows.Scan(&documentCategory.Id, &documentCategory.Name, &documentCategory.Description)
		if err != nil {
			return nil, err
		}

		documentCategories = append(documentCategories, documentCategory)
	}

	return documentCategories, nil
}

func (r *DocumentCategoryRepository) GetById(id int, role string) (*DocumentCategory, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var documentCategory DocumentCategory
	err = pool.QueryRow(context.Background(), "SELECT * FROM document_category WHERE id = $1", id).
		Scan(&documentCategory.Id, &documentCategory.Name, &documentCategory.Description)
	if err != nil {
		return nil, err
	}

	return &documentCategory, nil
}

func (r *DocumentCategoryRepository) Create(req DocumentCategoryRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO document_category (id, name, description) VALUES (DEFAULT, $1, $2) RETURNING id", req.Name, req.Description).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *DocumentCategoryRepository) Update(req DocumentCategoryRequest, id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil
	}

	_, err = pool.Exec(context.Background(), "UPDATE document_category SET name = $1, description = $2 WHERE id = $3", req.Name, req.Description, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *DocumentCategoryRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM document_category WHERE id = $1", id)
	if err != nil {
		return err
	}

	return nil
}
