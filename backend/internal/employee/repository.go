package employee

import (
	"context"
	"fmt"
	"warehouse/pkg/database"

	"github.com/jackc/pgx/v5/pgconn"
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

func (r *EmployeeRepository) GetById(id int, role string) (*Employee, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var employee Employee

	err = pool.QueryRow(context.Background(), `SELECT * FROM employee WHERE id=$1`, id).Scan(&employee.ID, &employee.Surname, &employee.Firstname, &employee.Patronymic, &employee.IdGender, &employee.INN, &employee.PhoneNumber, &employee.IdAddress, &employee.BirthDate, &employee.IdPosition)

	if err != nil {
		var message string
		if pgErr, ok := err.(*pgconn.PgError); ok {
			if pgErr.Code == "42501" {
				message = "Ошибка доступа: у вашей роли нет прав на эту таблицу"
			} else {
				message = fmt.Sprintf("PostgreSQL ошибка: %s, %s\n", pgErr.Code, pgErr.Message)
			}
		}
		return nil, fmt.Errorf(message)
	}

	return &employee, nil
}

func (r *EmployeeRepository) Create(employee Employee, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
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
		return nil, err
	}

	return &id, nil
}

func (r *EmployeeRepository) Update(employee Employee, role string) (*Employee, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, fmt.Errorf("failed to get db pool: %w", err)
	}

	const queryUpdate = `
		UPDATE employee SET
			surname      = $1,
			firstname    = $2,
			patronymic   = $3,
			id_gender    = $4,
			inn          = $5,
			phone_number = $6,
			id_address   = $7,
			birth_date   = $8,
			id_position  = $9
		WHERE id = $10
	`

	cmdTag, err := pool.Exec(context.Background(), queryUpdate,
		employee.Surname,
		employee.Firstname,
		employee.Patronymic,
		employee.IdGender,
		employee.INN,
		employee.PhoneNumber,
		employee.IdAddress,
		employee.BirthDate,
		employee.IdPosition,
		employee.ID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update employee: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		return nil, fmt.Errorf("no employee found with id %d", employee.ID)
	}

	const querySelect = `
		SELECT id, surname, firstname, patronymic, id_gender,
		       inn, phone_number, id_address, birth_date, id_position
		FROM employee WHERE id = $1
	`

	var updated Employee
	err = pool.QueryRow(context.Background(), querySelect, employee.ID).Scan(
		&updated.ID,
		&updated.Surname,
		&updated.Firstname,
		&updated.Patronymic,
		&updated.IdGender,
		&updated.INN,
		&updated.PhoneNumber,
		&updated.IdAddress,
		&updated.BirthDate,
		&updated.IdPosition,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch updated employee: %w", err)
	}

	return &updated, nil
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
