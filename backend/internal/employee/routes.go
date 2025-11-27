package employee

import (
	"warehouse/internal/auth"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {

	handler := NewEmployeeHandler(db)

	r.GET("/employees", auth.AuthMiddleware(), handler.GetEmployeesPagination)
	r.GET("/employees/:id", auth.AuthMiddleware(), handler.GetEmployeeById)
	r.POST("/employees", auth.AuthMiddleware(), handler.CreateEmployee)
	r.PUT("/employees/:id", auth.AuthMiddleware(), handler.UpdateEmployee)
	r.DELETE("/employees/:id", auth.AuthMiddleware(), handler.DeleteEmployee)
}
