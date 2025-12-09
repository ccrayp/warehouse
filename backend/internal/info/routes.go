package info

import (
	"context"
	"net/http"
	"warehouse/internal/auth"
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

	r.GET("info/me", auth.AuthMiddleware(), func(ctx *gin.Context) {
		var info EmployeeInfo

		claims := auth.GetClaims(ctx)
		if claims == nil {
			return
		}

		pool, _ := db.GetAdminPool()

		err := pool.QueryRow(context.Background(), `
			SELECT
				e.surname,
				e.firstname,
				e.patronymic,
				p.name AS position,
				a.subject || ', ' ||  a.region || ', ' || a.city || ', ' || a.street || ', ' || a.building AS address 
			FROM employee AS e
			JOIN position AS p
				ON e.id_position = p.id
			JOIN address AS a
				ON e.id_address = a.id
			JOIN sys_user AS su
				ON su.id_employee = e.id
			WHERE su.login = $1
		`, claims.Username).Scan(&info.Surname, &info.Firstname, &info.Patronymic, &info.Position, &info.Address)
		if err != nil {
			utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
			return
		}

		utils.RespondSuccess(ctx, http.StatusOK, "info data was successfully selected", gin.H{
			"employee": info,
		})
	})
}
