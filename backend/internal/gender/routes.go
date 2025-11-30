package gender

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {

	handler := NewGenderHandler(db)

	r.GET("/genders", auth.AuthMiddleware(), handler.GetAllGenders)
	r.GET("/genders/:id", auth.AuthMiddleware(), handler.GetGenderById)
}
