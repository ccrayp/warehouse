package productcategory

import (
	"context"
	"warehouse/pkg/database"
)

type ProductCategoryRepository struct {
	db *database.Connector
}

func NewProductCategoryRepository(db *database.Connector) *ProductCategoryRepository {
	return &ProductCategoryRepository{
		db: db,
	}
}

func (r *ProductCategoryRepository) GetPagination(limit, offset int, role string) ([]ProductCategory, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var productCategoies []ProductCategory

	rows, err := pool.Query(context.Background(), "SELECT id, name FROM product_category")
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		var productCategory ProductCategory

		err := rows.Scan(&productCategory.ID, &productCategory.Name)
		if err != nil {
			return nil, err
		}

		productCategoies = append(productCategoies, productCategory)
	}

	return productCategoies, nil
}

func (r *ProductCategoryRepository) GetById(id int, role string) (*ProductCategory, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var productCategory ProductCategory

	err = pool.QueryRow(context.Background(), "SELECT id, name FROM product_category WHERE id = $1", id).
		Scan(&productCategory.ID, &productCategory.Name)

	if err != nil {
		return nil, err
	}

	return &productCategory, nil
}

func (r *ProductCategoryRepository) Create(req ProductCategoryCreateRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO product_category (name) VALUES ($1) RETURNING id", req.Name).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *ProductCategoryRepository) Update(id int, req ProductCategoryUpdateRequest, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "UPDATE product_category SET name = $1 WHERE id = $2", req.Name, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *ProductCategoryRepository) DeleteById(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM product_category WHERE id=$1", id)
	if err != nil {
		return err
	}

	return nil
}
