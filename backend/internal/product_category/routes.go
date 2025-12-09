package productcategory

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewProductCategoryHandler(db)

	r.GET("/product_categories", auth.AuthMiddleware(), handler.GetRouting)
	r.GET("/product_categories/:id", auth.AuthMiddleware(), handler.GetProductCategoryById)
	r.POST("/product_categories", auth.AuthMiddleware(), handler.CreateProductCategory)
	r.PUT("/product_categories/:id", auth.AuthMiddleware(), handler.UpdateProductCategory)
	r.DELETE("/product_categories/:id", auth.AuthMiddleware(), handler.DeleteProductCsategory)
}
