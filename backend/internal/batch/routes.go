package batch

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {

	handler := NewBatchHandler(db)

	r.GET("/batches", auth.AuthMiddleware(), handler.GetBatchesPagination)
	r.GET("/batches/:id", auth.AuthMiddleware(), handler.GetBatchById)
	r.POST("/batches", auth.AuthMiddleware(), handler.CreateBatch)
	r.PUT("/batches/:id", auth.AuthMiddleware(), handler.UpdateBatch)
	r.DELETE("/batches/:id", auth.AuthMiddleware(), handler.DeleteBatchById)
}
