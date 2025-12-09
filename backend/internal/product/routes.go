package product

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewProductHandler(db)

	r.GET("/products", handler.GetRouting)
	r.GET("/products/:id", auth.AuthMiddleware(), handler.GetProductById)
	r.POST("/products", auth.AuthMiddleware(), handler.CreateProduct)
	r.POST("/products/image/:id", auth.AuthMiddleware(), handler.AddProductImage)
	r.PUT("/products/:id", auth.AuthMiddleware(), handler.UpdateProduct)
	r.DELETE("/products/:id", auth.AuthMiddleware(), handler.DeleteProduct)
}
