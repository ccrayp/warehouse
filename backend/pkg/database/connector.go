package database

import (
	"context"
	"fmt"
	"warehouse/pkg/config"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Connector struct {
	Pools map[string]*pgxpool.Pool
}

func NewConnector(cfg *config.Config) (*Connector, error) {
	pools := make(map[string]*pgxpool.Pool)

	roles := map[string]string{
		"admin":     fmt.Sprintf("postgres://%s:%s@%s:%d/%s", cfg.User.AdminLogin, cfg.User.AdminPassword, cfg.Database.Host, cfg.Database.Port, cfg.Database.Name),
		"moderator": fmt.Sprintf("postgres://%s:%s@%s:%d/%s", cfg.User.ModeratorLogin, cfg.User.ModeratorPassword, cfg.Database.Host, cfg.Database.Port, cfg.Database.Name),
		"manager":   fmt.Sprintf("postgres://%s:%s@%s:%d/%s", cfg.User.ManagerLogin, cfg.User.ManagerPassword, cfg.Database.Host, cfg.Database.Port, cfg.Database.Name),
	}

	for role, connStr := range roles {
		pool, err := pgxpool.New(context.Background(), connStr)
		if err != nil {
			return nil, fmt.Errorf("cannot create pool for role %s: %w", role, err)
		}
		pools[role] = pool
	}

	return &Connector{Pools: pools}, nil
}

func (c *Connector) GetPool(role string) (*pgxpool.Pool, error) {
	pool, ok := c.Pools[role]
	if !ok {
		return nil, fmt.Errorf("pool for role %s not found", role)
	}
	return pool, nil
}

func (c *Connector) GetAdminPool() (*pgxpool.Pool, error) {
	return c.GetPool("admin")
}

func (c *Connector) GetModeratorPool() (*pgxpool.Pool, error) {
	return c.GetPool("moderator")
}

func (c *Connector) GetManagerPool() (*pgxpool.Pool, error) {
	return c.GetPool("manager")
}
