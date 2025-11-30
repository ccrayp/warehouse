package role

// table role
type Role struct {
	ID          int    `json:"id"`
	Name        string `json:"name"` // varchar(50)
	Description string `json:"description"`
	SysRole     string `json:"sys_role"` //varchar(50)
}

type RoleCreateRequest struct {
	Name        string `json:"name"` // varchar(50)
	Description string `json:"description"`
	SysRole     string `json:"sys_role"` //varchar(50)
}

type RoleUpdateRequest struct {
	Name        string `json:"name"` // varchar(50)
	Description string `json:"description"`
	SysRole     string `json:"sys_role"` //varchar(50)
}

type RoleDeleteRequest struct {
	ID int `json:"id"`
}
