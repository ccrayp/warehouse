package audit

import (
	"context"
	"encoding/json"
	"warehouse/pkg/database"
)

type AuditRepository struct {
	db *database.Connector
}

func NewAuditRepository(db *database.Connector) *AuditRepository {
	return &AuditRepository{
		db: db,
	}
}

func (r *AuditRepository) GetPagination(limit int, offset int, role string) ([]Audit, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var logs []Audit

	rows, err := pool.Query(context.Background(), `SELECT *FROM audit_log ORDER BY changed_at DESC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var log Audit
		var oldData, newData []byte

		err := rows.Scan(&log.ID, &log.TableName, &log.Action, &oldData, &newData, &log.ChangedBy, &log.ChangetAt)
		if err != nil {
			return nil, err
		}

		if len(oldData) > 0 {
			var o any
			if err := json.Unmarshal(oldData, &o); err == nil {
				log.OldData = o
			}
		}
		if len(newData) > 0 {
			var n any
			if err := json.Unmarshal(newData, &n); err == nil {
				log.NewData = n
			}
		}

		logs = append(logs, log)
	}

	return logs, nil
}
