package audit

import (
	"net/http"
	"strconv"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type AuditHandler struct {
	AuditRepository *AuditRepository
}

func NewAuditHandler(db *database.Connector) *AuditHandler {
	return &AuditHandler{
		AuditRepository: NewAuditRepository(db),
	}
}

func (h *AuditHandler) GetAuditPagination(ctx *gin.Context) {
	limit, err := strconv.Atoi(ctx.Query("limit"))
	if err != nil || limit < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid limit", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

	offset, err := strconv.Atoi(ctx.Query("offset"))
	if err != nil || offset < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid offset", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

	var role PaginationRequest
	err = ctx.BindJSON(&role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to parse role", gin.H{
			"required_data": PaginationRequest{},
		})
		return
	}

	logs, err := h.AuditRepository.GetPagination(limit, offset, role.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to parse role", gin.H{
			"required_data": PaginationRequest{},
		})
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "logs selected successfully", logs)
}
