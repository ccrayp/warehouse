package product

import (
	"context"
	"warehouse/pkg/database"
)

type ProductRepository struct {
	db *database.Connector
}

func NewProductRepository(db *database.Connector) *ProductRepository {
	return &ProductRepository{
		db: db,
	}
}

func (r *ProductRepository) GetPagination(limit, offset int, role string) ([]Product, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var products []Product

	rows, err := pool.Query(context.Background(), "SELECT id, name, id_product_category, id_producer, image_url FROM product ORDER BY id ASC")
	if err != nil {
		return nil, err
	}

	for rows.Next() {
		var product Product

		err := rows.Scan(&product.ID, &product.Name, &product.IdProductCategory, &product.IdProducer, &product.ImageURL)
		if err != nil {
			return nil, err
		}

		products = append(products, product)
	}

	return products, nil
}

func (r *ProductRepository) GetById(id int, role string) (*Product, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var product Product
	err = pool.QueryRow(context.Background(), "SELECT id, name, id_product_category, id_producer, image_url FROM product WHERE id=$1", id).
		Scan(&product.ID,
			&product.Name,
			&product.IdProductCategory,
			&product.IdProducer,
			&product.ImageURL)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

func (r *ProductRepository) Create(req ProductCreateRequest, role string) (int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return 0, err
	}

	var id int
	err = pool.QueryRow(context.Background(),
		`INSERT INTO product (name, id_product_category, id_producer, image_url) 
		 VALUES ($1, $2, $3, $4) RETURNING id`,
		req.Name, req.IdProductCategory, req.IdProducer, req.ImageURL,
	).Scan(&id)

	return id, err
}

func (r *ProductRepository) Update(id int, req ProductUpdateRequest, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(),
		`UPDATE product 
		 SET name=$1, id_product_category=$2, id_producer=$3, image_url=$4
		 WHERE id=$5`,
		req.Name, req.IdProductCategory, req.IdProducer, req.ImageURL, id,
	)

	return err
}

func (r *ProductRepository) DeleteById(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM product WHERE id=$1", id)
	if err != nil {
		return err
	}

	return nil
}

func (r *ProductRepository) UpdateImage(id int, imageURL string, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(),
		`UPDATE product SET image_url=$1 WHERE id=$2`,
		imageURL, id,
	)

	return err
}
