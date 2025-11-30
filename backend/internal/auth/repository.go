package auth

import (
	"context"
	"warehouse/pkg/database"
)

type AuthRepository struct {
	Db *database.Connector
}

func NewAuthRepository(db *database.Connector) *AuthRepository {
	return &AuthRepository{
		Db: db,
	}
}

func (r *AuthRepository) SaveRefreshToken(token, username, role string) error {
	pool, err := r.Db.GetAdminPool()
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(),
		`INSERT INTO refresh_tokens(token, username, role, created_at) 
         VALUES($1,$2,$3,NOW())`,
		token, username, role,
	)
	return err
}

func (r *AuthRepository) GetRefreshToken(token string) (*RefreshTokens, error) {
	pool, err := r.Db.GetAdminPool()
	if err != nil {
		return nil, err
	}

	var rt RefreshTokens
	err = pool.QueryRow(context.Background(),
		`SELECT id, token, username, role, created_at 
         FROM refresh_tokens WHERE token=$1`,
		token,
	).Scan(&rt.ID, &rt.Token, &rt.Username, &rt.Role, &rt.CreatedAt)
	if err != nil {
		return nil, err
	}

	return &rt, nil
}

func (r *AuthRepository) DeleteRefreshToken(token string) error {
	pool, err := r.Db.GetAdminPool()
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(),
		`DELETE FROM refresh_tokens WHERE token=$1`, token)
	return err
}

func (r *AuthRepository) GetPassword(username string) ([]byte, error) {
	pool, err := r.Db.GetAdminPool()
	if err != nil {
		return nil, err
	}

	var password []byte
	err = pool.QueryRow(context.Background(),
		`SELECT password_hash FROM sys_user WHERE login=$1`, username,
	).Scan(&password)
	if err != nil {
		return nil, err
	}

	return password, nil
}

func (r *AuthRepository) GetRoleByUsername(username string) (string, error) {
	pool, err := r.Db.GetAdminPool()
	if err != nil {
		return "", err
	}

	var role string
	err = pool.QueryRow(context.Background(),
		`SELECT r.sys_role FROM sys_user AS su JOIN role AS r ON su.id_role = r.id WHERE login=$1`, username,
	).Scan(&role)
	if err != nil {
		return "", err
	}

	return role, nil
}
