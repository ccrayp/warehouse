package role

import (
	"context"
	"fmt"
	"warehouse/pkg/database"
)

type RoleRepository struct {
	db        *database.Connector
	TableName string
}

func NewRoleRepository(db *database.Connector) *RoleRepository {
	return &RoleRepository{
		db:        db,
		TableName: "role",
	}
}

func (r *RoleRepository) GetAll(role string) ([]Role, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), `SELECT id, name, description, sys_role FROM role ORDER BY name ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var roles []Role
	for rows.Next() {
		var rl Role
		if err := rows.Scan(&rl.ID, &rl.Name, &rl.Description, &rl.SysRole); err != nil {
			return nil, err
		}
		roles = append(roles, rl)
	}

	return roles, nil
}

func (r *RoleRepository) GetPagination(limit int, offset int, role string) ([]Role, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), `SELECT id, name, description, sys_role FROM role ORDER BY name ASC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var roles []Role
	for rows.Next() {
		var rl Role
		if err := rows.Scan(&rl.ID, &rl.Name, &rl.Description, &rl.SysRole); err != nil {
			return nil, err
		}
		roles = append(roles, rl)
	}

	return roles, nil
}

func (r *RoleRepository) GetById(id int, role string) (*Role, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var rl Role
	err = pool.QueryRow(context.Background(), `SELECT id, name, description, sys_role FROM role WHERE id=$1`, id).
		Scan(&rl.ID, &rl.Name, &rl.Description, &rl.SysRole)
	if err != nil {
		return nil, err
	}

	return &rl, nil
}

func (r *RoleRepository) Create(req RoleCreateRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), `
		INSERT INTO role (name, description, sys_role)
		VALUES ($1, $2, $3)
		RETURNING id
	`, req.Name, req.Description, req.SysRole).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *RoleRepository) Update(id int, req RoleUpdateRequest, role string) (*Role, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, fmt.Errorf("failed to get db pool: %w", err)
	}

	const queryUpdate = `
		UPDATE role SET
			name = $1,
			description = $2,
			sys_role = $3
		WHERE id = $4
	`

	cmdTag, err := pool.Exec(context.Background(), queryUpdate, req.Name, req.Description, req.SysRole, id)
	if err != nil {
		return nil, fmt.Errorf("failed to update role: %w", err)
	}

	if cmdTag.RowsAffected() == 0 {
		return nil, fmt.Errorf("no role found with id %d", id)
	}

	return r.GetById(id, role)
}

func (r *RoleRepository) Delete(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	cmdTag, err := pool.Exec(context.Background(), `DELETE FROM role WHERE id=$1`, id)
	if err != nil {
		return err
	}

	if cmdTag.RowsAffected() == 0 {
		return fmt.Errorf("no role with id=%d", id)
	}

	return nil
}
