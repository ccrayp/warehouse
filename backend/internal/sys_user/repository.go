package sys_user

import (
	"context"
	"fmt"
	"warehouse/pkg/database"
)

type SysUserRepository struct {
	db        *database.Connector
	TableName string
}

func NewSysUserRepository(db *database.Connector) *SysUserRepository {
	return &SysUserRepository{
		db:        db,
		TableName: "sys_user",
	}
}

func (r *SysUserRepository) GetAll(role string) ([]SysUser, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), `SELECT id, login, password_hash, id_role, id_employee FROM sys_user ORDER BY login ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var users []SysUser
	for rows.Next() {
		var u SysUser
		if err := rows.Scan(&u.ID, &u.Login, &u.PasswordHash, &u.IdRole, &u.IdEmployee); err != nil {
			return nil, err
		}
		users = append(users, u)
	}

	return users, nil
}

func (r *SysUserRepository) GetPagination(limit int, offset int, role string) ([]SysUser, *int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, nil, err
	}

	var total int
	_ = pool.QueryRow(context.Background(), "SELECT COUNT(*) AS total FROM sys_user").Scan(&total)

	rows, err := pool.Query(context.Background(), `SELECT id, login, password_hash, id_role, id_employee FROM sys_user ORDER BY login ASC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var users []SysUser
	for rows.Next() {
		var u SysUser
		if err := rows.Scan(&u.ID, &u.Login, &u.PasswordHash, &u.IdRole, &u.IdEmployee); err != nil {
			return nil, nil, err
		}
		users = append(users, u)
	}

	return users, &total, nil
}

func (r *SysUserRepository) GetById(id int, role string) (*SysUser, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var u SysUser
	err = pool.QueryRow(context.Background(), `SELECT id, login, password_hash, id_role, id_employee FROM sys_user WHERE id=$1`, id).
		Scan(&u.ID, &u.Login, &u.PasswordHash, &u.IdRole, &u.IdEmployee)
	if err != nil {
		return nil, err
	}

	return &u, nil
}

func (r *SysUserRepository) Create(user SysUserCreateRequest, role string, hash string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), `
		INSERT INTO sys_user (login, password_hash, id_role, id_employee)
		VALUES ($1, $2, $3, $4)
		RETURNING id
	`, user.Login, hash, user.IdRole, user.IdEmployee).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *SysUserRepository) Update(id int, user SysUserCreateUpdateRequest, role string, hash string) (*SysUser, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, fmt.Errorf("failed to get db pool: %w", err)
	}

	const queryUpdate = `
		UPDATE sys_user SET
			login = $1,
			password_hash = $2,
			id_role = $3,
			id_employee = $4
		WHERE id = $5
	`
	cmdTag, err := pool.Exec(context.Background(), queryUpdate, user.Login, hash, user.IdRole, user.IdEmployee, id)
	if err != nil {
		return nil, fmt.Errorf("failed to update sys_user: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		return nil, fmt.Errorf("no sys_user found with id %d", id)
	}

	return r.GetById(id, role)
}

func (r *SysUserRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	cmdTag, err := pool.Exec(context.Background(), `DELETE FROM sys_user WHERE id=$1`, id)
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return fmt.Errorf("no sys_user with id=%d", id)
	}

	return nil
}
