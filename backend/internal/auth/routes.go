package auth

import (
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewAuthHandler(db)

	r.POST("/auth/login", handler.Login)
	r.POST("/auth/refresh", AuthMiddleware(), handler.Refresh)
	r.POST("/auth/validate", AuthMiddleware(), handler.Validate)
}
