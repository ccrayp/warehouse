package main

import (
	"fmt"
	"net/http"
	"warehouse/internal/address"
	"warehouse/internal/audit"
	"warehouse/internal/auth"
	"warehouse/internal/batch"
	"warehouse/internal/document"
	documentcategory "warehouse/internal/document_category"
	"warehouse/internal/employee"
	"warehouse/internal/gender"
	"warehouse/internal/info"
	"warehouse/internal/position"
	"warehouse/internal/producer"
	"warehouse/internal/product"
	productcategory "warehouse/internal/product_category"
	"warehouse/internal/report"
	"warehouse/internal/role"
	"warehouse/internal/sys_user"
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

	s.Static("/static", "/app/uploads")

	s.GET("/", func(ctx *gin.Context) {
		utils.RespondSuccess(ctx, http.StatusOK, "server is working correctly", gin.H{
			"info": "api server for course project on 'Databases'",
		})
	})

	auth.InitRoutes(s, db)
	audit.InitRoutes(s, db)
	employee.InitRoutes(s, db)
	batch.InitRoutes(s, db)
	gender.InitRoutes(s, db)
	sys_user.InitRoutes(s, db)
	role.InitRoutes(s, db)
	product.InitRoutes(s, db)
	productcategory.InitRoutes(s, db)
	report.InitRoutes(s, db)
	producer.InitRoutes(s, db)
	position.InitRoutes(s, db)
	address.InitRoutes(s, db)
	documentcategory.InitRoutes(s, db)
	document.InitRoutes(s, db)

	info.InitRoutes(s, db)

	s.Run(":8080")
}
