package audit

import "time"

type Audit struct {
	ID        int       `json:"id"`
	TableName string    `json:"table_name"`
	Action    string    `json:"action"`
	OldData   any       `json:"old_data"`
	NewData   any       `json:"new_data"`
	ChangedBy string    `json:"changer_by"`
	ChangetAt time.Time `json:"changer_at"`
}

type AuditFilters struct {
	Role      string
	Action    string
	TableName string
}
