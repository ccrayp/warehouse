package report

import (
	"net/http"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type ReportHandler struct {
	reportRepository *ReportRepository
}

func NewReportHandler(db *database.Connector) *ReportHandler {
	return &ReportHandler{
		reportRepository: NewReportRepository(db),
	}
}

func (h *ReportHandler) handleReport(
	ctx *gin.Context,
	fetchFn func(role string) (any, error),
) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	report, err := fetchFn(claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if report == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for view", "permission denied for view", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "report was successfully selected", gin.H{
		"report": report,
	})
}

func (h *ReportHandler) Batches(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetBatches)
}

func (h *ReportHandler) DocumentsByEmployee(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetDocumentsByEmployee)
}

func (h *ReportHandler) Employees(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetEmployees)
}

func (h *ReportHandler) ExpiredBatches(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetExpiredBatches)
}

func (h *ReportHandler) Grants(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetGrants)
}

func (h *ReportHandler) NoProducts(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetNoProducts)
}

func (h *ReportHandler) ProducerSubjectStatistics(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetProducerSubjectStatistics)
}

func (h *ReportHandler) ProductLeft(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetProductLeft)
}

func (h *ReportHandler) SystemUsers(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetSystemUsers)
}

func (h *ReportHandler) TableActivityPerHour(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetTableActivityPerHour)
}

func (h *ReportHandler) TablesActivity(ctx *gin.Context) {
	h.handleReport(ctx, h.reportRepository.GetTablesActivity)
}
