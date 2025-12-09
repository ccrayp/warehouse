package document

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewDocumentHandler(db)

	r.GET("/documents", auth.AuthMiddleware(), handler.GetDocumentRouting)
	r.GET("/documents/:id", auth.AuthMiddleware(), handler.GetDocumentById)
	r.POST("/documents", auth.AuthMiddleware(), handler.CreateDocument)
	r.PUT("/documents/:id", auth.AuthMiddleware(), handler.UpdateDocuemnt)
	r.DELETE("/documents/:id", auth.AuthMiddleware(), handler.DeleteDocument)

	r.GET("/documents/contents", auth.AuthMiddleware(), handler.GetContentRouting)
	r.GET("/documents/contents/:id", auth.AuthMiddleware(), handler.GetContentById)
	r.GET("/documents/:id/contents", auth.AuthMiddleware(), handler.GetAllContentByDocuemntId)
	r.POST("/documents/contents", auth.AuthMiddleware(), handler.CreateContent)
	r.PUT("/documents/contents/:id", auth.AuthMiddleware(), handler.UpdateConetent)
	r.DELETE("/documents/contents/:id", auth.AuthMiddleware(), handler.DeleteContent)
}
