// main.go
package main

import (
	"context"
	"fmt"
	"net/http"
	warehouse "warehouse/internal/utils"

	"github.com/gin-gonic/gin"
)

func main() {
	connStr := "postgres://admin:admin@warehouse_db:5432/warehouse"
	conn, err := warehouse.ConnectDB(connStr)
	if err != nil {
		fmt.Printf("ERROR %s", err.Error())
		return
	}
	defer conn.Close(context.Background())

	server := gin.Default()

	server.GET("/request", func(ctx *gin.Context) {
		query := ctx.Query("query")
		results, err := warehouse.GetResponseFromQuery(conn, query)
		if err != nil {
			ctx.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		ctx.JSON(http.StatusOK, results)
	})

	server.Run(":8080")
}
