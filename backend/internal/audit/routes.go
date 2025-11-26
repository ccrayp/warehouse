package audit

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewAuditHandler(db)

	r.GET("/audit", auth.AuthMiddleware(), handler.GetAuditPagination)
}
