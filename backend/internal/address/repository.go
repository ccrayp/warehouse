package address

import (
	"context"
	"warehouse/pkg/database"
)

type AddressRepository struct {
	db *database.Connector
}

func NewAddressRepository(db *database.Connector) *AddressRepository {
	return &AddressRepository{
		db: db,
	}
}

func (r *AddressRepository) GetPagination(limit, offset int, role string) ([]Address, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM address LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}

	var addresses []Address

	for rows.Next() {
		var address Address

		err := rows.Scan(&address.Id, &address.Subject, &address.Region, &address.City, &address.Street, &address.Building)
		if err != nil {
			return nil, err
		}

		addresses = append(addresses, address)
	}

	return addresses, nil
}

func (r *AddressRepository) GetById(id int, role string) (*Address, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var address Address
	err = pool.QueryRow(context.Background(), "SELECT * FROM address WHERE id=$1", id).
		Scan(&address.Id, &address.Subject, &address.Region, &address.City, &address.Street, &address.Building)
	if err != nil {
		return nil, err
	}

	return &address, nil
}

func (r *AddressRepository) Create(req AddressRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO address (id, subject, region, city, street, building) VALUES (DEFAULT, $1, $2, $3, $4, $5) RETURNING id",
		req.Subject, req.Region, req.City, req.Street, req.Building).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *AddressRepository) Update(req AddressRequest, id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "UPDATE address SET subject=$1, region=$2, city=$3, street=$4, building=$5 WHERE id=$6", req.Subject, req.Region, req.City, req.Street, req.Building, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *AddressRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM address WHERE id=$1", id)
	if err != nil {
		return err
	}

	return nil
}
