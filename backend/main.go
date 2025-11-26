package main

import (
	"fmt"
	"net/http"
	"warehouse/internal/audit"
	"warehouse/internal/auth"
	"warehouse/pkg/config"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

func main() {
	cfg := config.LoadConfig()

	db, err := database.NewConnector(cfg)
	if err != nil {
		fmt.Println("Connection aborted")
	}

	s := gin.Default()

	s.GET("/auth/health-check", func(ctx *gin.Context) {
		utils.RespondSuccess(ctx, http.StatusOK, "server is working correctly", gin.H{})
	})

	auth.InitRoutes(s, db)
	audit.InitRoutes(s, db)

	s.Run(":8080")
}
