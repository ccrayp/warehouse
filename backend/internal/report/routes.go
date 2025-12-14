package report

import (
	"fmt"
	"net/http"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewReportHandler(db)

	var ReportHandlers = map[string]func(c *gin.Context){
		"batches":                     handler.Batches,
		"documents_by_employee":       handler.DocumentsByEmployee,
		"employees":                   handler.Employees,
		"expired_batches":             handler.ExpiredBatches,
		"grants":                      handler.Grants,
		"interface_grants":            handler.InterfaceGrants,
		"no_products":                 handler.NoProducts,
		"producer_subject_statistics": handler.ProducerSubjectStatistics,
		"products_left":               handler.ProductLeft,
		"products_left_by_batch":      handler.ProductLeftByBatch,
		"non_fixed_batches":           handler.NonFixedBatches,
		"system_users":                handler.SystemUsers,
		"tables_activity_per_hour":    handler.TablesActivityPerHour,
		"tables_activity":             handler.TablesActivity,
	}

	r.GET("/report/:name", auth.AuthMiddleware(), func(ctx *gin.Context) {
		name := ctx.Param("name")

		if handlerReport, ok := ReportHandlers[name]; ok {
			handlerReport(ctx)
			return
		}

		utils.RespondError(ctx, http.StatusNotFound, fmt.Sprintf("report with such name (%s) not fount", name), fmt.Sprintf("report with such name (%s) not fount", name), nil)
	})
}
