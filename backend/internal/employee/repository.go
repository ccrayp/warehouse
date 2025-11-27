package employee

import (
	"context"
	"fmt"
	"warehouse/pkg/database"
)

type EmployeeRepository struct {
	db        *database.Connector
	TableName string
}

func NewEmployeeRepository(db *database.Connector) *EmployeeRepository {
	return &EmployeeRepository{
		db:        db,
		TableName: "employee",
	}
}

func (r *EmployeeRepository) GetPagination(limit int, offset int, role string) ([]Employee, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var employees []Employee

	rows, err := pool.Query(context.Background(), `SELECT * FROM employee ORDER BY surname, firstname, patronymic ASC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var employee Employee

		err := rows.Scan(&employee.ID, &employee.Surname, &employee.Firstname, &employee.Patronymic, &employee.IdGender, &employee.INN, &employee.PhoneNumber, &employee.IdAddress, &employee.BirthDate, &employee.IdPosition)
		if err != nil {
			return nil, err
		}

		employees = append(employees, employee)
	}

	return employees, nil
}

func (r *EmployeeRepository) GetById(id int, role string) (Employee, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return Employee{}, err
	}

	var employee Employee

	err = pool.QueryRow(context.Background(), `SELECT * FROM employee WHERE id=$1`, id).Scan(&employee.ID, &employee.Surname, &employee.Firstname, &employee.Patronymic, &employee.IdGender, &employee.INN, &employee.PhoneNumber, &employee.IdAddress, &employee.BirthDate, &employee.IdPosition)

	if err != nil {
		return Employee{}, err
	}

	return employee, nil
}

func (r *EmployeeRepository) Create(employee Employee, role string) (int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return -1, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO employee (surname, firstname, patronymic, id_gender, inn, phone_number, id_address, birth_date, id_position) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING id",
		employee.Surname,
		employee.Firstname,
		employee.Patronymic,
		employee.IdGender,
		employee.INN,
		employee.PhoneNumber,
		employee.IdAddress,
		employee.BirthDate,
		employee.IdPosition,
	).Scan(&id)
	if err != nil {
		return -1, err
	}

	return id, nil
}

func (r *EmployeeRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	cmdTag, err := pool.Exec(context.Background(), "DELETE FROM employee WHERE id=$1", id)
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return fmt.Errorf("no employee with id=%d", id)
	}

	return nil
}
