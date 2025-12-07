package position

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewPositionHandler(db)

	r.GET("/positions", auth.AuthMiddleware(), handler.GetPositionPagination)
	r.GET("/positions/:id", auth.AuthMiddleware(), handler.GetPositionById)
	r.POST("/positions", auth.AuthMiddleware(), handler.CreatePosition)
	r.PUT("/positions/:id", auth.AuthMiddleware(), handler.UpdatePosition)
	r.DELETE("/positions/:id", auth.AuthMiddleware(), handler.DeletePosition)
}
