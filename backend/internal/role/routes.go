package role

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewRoleHandler(db)

	r.GET("/roles", auth.AuthMiddleware(), handler.GetRolesPagination)
	r.GET("/roles/:id", auth.AuthMiddleware(), handler.GetRoleById)
	r.POST("/roles", auth.AuthMiddleware(), handler.CreateRole)
	r.PUT("/roles/:id", auth.AuthMiddleware(), handler.UpdateRole)
	r.DELETE("/roles/:id", auth.AuthMiddleware(), handler.DeleteRole)
}
