package producer

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewProducerHandler(db)

	r.GET("/producers", auth.AuthMiddleware(), handler.GetRouting)
	r.GET("/producers/:id", auth.AuthMiddleware(), handler.GetProducerById)
	r.POST("/producers", auth.AuthMiddleware(), handler.CreateProducer)
	r.PUT("/producers/:id", auth.AuthMiddleware(), handler.UpdateProducer)
	r.DELETE("/producers/:id", auth.AuthMiddleware(), handler.DeleteProducer)
}
