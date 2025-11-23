// warehouse/db.go
package warehouse

import (
	"context"

	"github.com/jackc/pgx/v5"
)

// ConnectDB открывает соединение
func ConnectDB(connStr string) (*pgx.Conn, error) {
	return pgx.Connect(context.Background(), connStr)
}

// GetResponseFromQuery выполняет любой SQL-запрос и возвращает результат в виде []map[string]interface{}
func GetResponseFromQuery(conn *pgx.Conn, query string) ([]map[string]interface{}, error) {
	rows, err := conn.Query(context.Background(), query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	fieldDescriptions := rows.FieldDescriptions()
	var results []map[string]interface{}

	for rows.Next() {
		values, err := rows.Values()
		if err != nil {
			return nil, err
		}

		rowMap := make(map[string]interface{})
		for i, fd := range fieldDescriptions {
			rowMap[string(fd.Name)] = values[i]
		}
		results = append(results, rowMap)
	}

	if rows.Err() != nil {
		return nil, rows.Err()
	}

	return results, nil
}
