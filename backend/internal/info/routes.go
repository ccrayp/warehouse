package info

import (
	"context"
	"net/http"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	r.GET("/info/homepage", func(ctx *gin.Context) {
		var employees, producer, products, product_categories int

		pool, _ := db.GetAdminPool()
		err := pool.QueryRow(context.Background(), `
			SELECT
				(SELECT COUNT(*) FROM employee) AS employees,
				(SELECT COUNT(*) FROM producer) AS producers,
				(SELECT COUNT(*) FROM product) AS products,
				(SELECT COUNT(*) FROM product_category) AS product_categories
		`).Scan(&employees, &producer, &products, &product_categories)
		if err != nil {
			utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
			return
		}

		utils.RespondSuccess(ctx, http.StatusOK, "info data was selected successfully", gin.H{
			"producer":  producer,
			"prodcut":   products,
			"employee":  employees,
			"categoris": product_categories,
		})
	})
}
