package main

import (
	"fmt"
	"net/http"
	"warehouse/internal/audit"
	"warehouse/internal/auth"
	"warehouse/internal/batch"
	"warehouse/internal/employee"
	"warehouse/internal/gender"
	"warehouse/internal/product"
	"warehouse/internal/role"
	"warehouse/internal/sys_user"
	"warehouse/pkg/config"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.LoadConfig()

	db, err := database.NewConnector(cfg)
	if err != nil {
		fmt.Println("Connection aborted")
	}

	s := gin.Default()

	s.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"http://localhost:8082"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization"},
		AllowCredentials: true,
	}))

	s.Static("/static", "/app/uploads")

	s.GET("/", func(ctx *gin.Context) {
		utils.RespondSuccess(ctx, http.StatusOK, "server is working correctly", nil)
	})

	auth.InitRoutes(s, db)
	audit.InitRoutes(s, db)
	employee.InitRoutes(s, db)
	batch.InitRoutes(s, db)
	gender.InitRoutes(s, db)
	sys_user.InitRoutes(s, db)
	role.InitRoutes(s, db)
	product.InitRoutes(s, db)

	s.Run(":8080")
}
