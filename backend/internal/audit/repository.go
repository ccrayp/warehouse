package audit

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
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

func (r *AuditRepository) GetPagination(
	limit int,
	offset int,
	role string,
	filters AuditFilters,
) ([]Audit, *int, error) {

	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, nil, err
	}

	var (
		args       []any
		conditions []string
		argID      = 1
	)

	if filters.Role != "" {
		conditions = append(conditions, fmt.Sprintf("changed_by ILIKE $%d", argID))
		args = append(args, "%"+filters.Role+"%")
		argID++
	}

	if filters.Action != "" {
		conditions = append(conditions, fmt.Sprintf("action ILIKE $%d", argID))
		args = append(args, "%"+filters.Action+"%")
		argID++
	}

	if filters.TableName != "" {
		conditions = append(conditions, fmt.Sprintf("table_name ILIKE $%d", argID))
		args = append(args, "%"+filters.TableName+"%")
		argID++
	}

	whereSQL := ""
	if len(conditions) > 0 {
		whereSQL = "WHERE " + strings.Join(conditions, " AND ")
	}

	args = append(args, limit, offset)

	query := fmt.Sprintf(`
		SELECT id, table_name, action, old_data, new_data, changed_by, changed_at
		FROM audit_log
		%s
		ORDER BY changed_at DESC
		LIMIT $%d OFFSET $%d
	`, whereSQL, argID, argID+1)

	rows, err := pool.Query(context.Background(), query, args...)
	if err != nil {
		return nil, nil, err
	}
	defer rows.Close()

	var logs []Audit

	for rows.Next() {
		var log Audit
		var oldData, newData []byte

		if err := rows.Scan(
			&log.ID,
			&log.TableName,
			&log.Action,
			&oldData,
			&newData,
			&log.ChangedBy,
			&log.ChangetAt,
		); err != nil {
			return nil, nil, err
		}

		if len(oldData) > 0 {
			_ = json.Unmarshal(oldData, &log.OldData)
		}
		if len(newData) > 0 {
			_ = json.Unmarshal(newData, &log.NewData)
		}

		logs = append(logs, log)
	}

	countQuery := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM audit_log
		%s
	`, whereSQL)

	var total int
	err = pool.QueryRow(context.Background(), countQuery, args[:len(args)-2]...).Scan(&total)
	if err != nil {
		return nil, nil, err
	}

	return logs, &total, nil
}
