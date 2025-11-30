package sys_user

// table sys_user
type SysUser struct {
	ID           int    `json:"id"`
	Login        string `json:"login"`         //varchar(50)
	PasswordHash string `json:"password_hash"` //char(60)
	IdRole       int    `json:"id_role"`
	IdEmployee   int    `json:"id_employee"`
}

type SysUserCreateRequest struct {
	Login      string `json:"login"` //varchar(50)
	Password   string `json:"password"`
	IdRole     int    `json:"id_role"`
	IdEmployee int    `json:"id_employee"`
}

type SysUserCreateUpdateRequest struct {
	Login      string `json:"login"` //varchar(50)
	Password   string `json:"password"`
	IdRole     int    `json:"id_role"`
	IdEmployee int    `json:"id_employee"`
}

type SysUserDeleteRequest struct {
	ID int `json:"id"`
}
