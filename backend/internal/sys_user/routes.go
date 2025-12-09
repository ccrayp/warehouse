package sys_user

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewSysUserHandler(db)

	r.GET("/sys_users", auth.AuthMiddleware(), handler.GetRouting)
	r.GET("/sys_users/:id", auth.AuthMiddleware(), handler.GetUserById)
	r.POST("/sys_users", auth.AuthMiddleware(), handler.CreateUser)
	r.PUT("/sys_users/:id", auth.AuthMiddleware(), handler.UpdateUser)
	r.DELETE("/sys_users/:id", auth.AuthMiddleware(), handler.DeleteUser)
}
