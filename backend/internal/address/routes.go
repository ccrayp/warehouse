package address

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewAddressHandler(db)

	r.GET("/addresses", auth.AuthMiddleware(), handler.GetAddressPagination)
	r.GET("/addresses/:id", auth.AuthMiddleware(), handler.GetAddressById)
	r.POST("/addresses", auth.AuthMiddleware(), handler.CreateAddress)
	r.PUT("/addresses/:id", auth.AuthMiddleware(), handler.UpdateAddress)
	r.DELETE("/addresses/:id", auth.AuthMiddleware(), handler.DeleteAddress)
}
