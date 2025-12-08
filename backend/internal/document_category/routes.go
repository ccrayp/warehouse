package documentcategory

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewDocumentCategoryHandler(db)

	r.GET("/document_categories", auth.AuthMiddleware(), handler.GetDocumentCategoryPagination)
	r.GET("/document_categories/:id", auth.AuthMiddleware(), handler.GetDocumentCategoryByID)
	r.POST("/document_categories", auth.AuthMiddleware(), handler.CreateDocumentCategory)
	r.PUT("/document_categories/:id", auth.AuthMiddleware(), handler.UpdateDocumentCategory)
	r.DELETE("/document_categories/:id", auth.AuthMiddleware(), handler.DeleteDocumentCategory)
}
