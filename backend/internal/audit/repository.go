package audit

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"warehouse/pkg/database"

	"github.com/jackc/pgx/v5/pgconn"
)

type AuditRepository struct {
	db *database.Connector
}

func NewAuditRepository(db *database.Connector) *AuditRepository {
	return &AuditRepository{
		db: db,
	}
}

func (r *AuditRepository) GetPagination(limit int, offset int, role string) ([]Audit, string, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, role, err
	}

	var logs []Audit

	rows, err := pool.Query(context.Background(), `
        SELECT * FROM audit_log ORDER BY changed_at DESC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		var pgErr *pgconn.PgError
		if errors.As(err, &pgErr) {
			if pgErr.Code == "42501" {
				return nil, role, fmt.Errorf("permission denied: %s", pgErr.Message)
			}
			return nil, role, fmt.Errorf("PostgreSQL error %s: %s", pgErr.Code, pgErr.Message)
		}
		return nil, role, err
	}
	defer rows.Close()

	for rows.Next() {
		var log Audit
		var oldData, newData []byte

		if err := rows.Scan(&log.ID, &log.TableName, &log.Action, &oldData, &newData, &log.ChangedBy, &log.ChangetAt); err != nil {
			return nil, role, err
		}

		if len(oldData) > 0 {
			var o any
			_ = json.Unmarshal(oldData, &o)
			log.OldData = o
		}
		if len(newData) > 0 {
			var n any
			_ = json.Unmarshal(newData, &n)
			log.NewData = n
		}

		logs = append(logs, log)
	}

	return logs, role, nil
}
