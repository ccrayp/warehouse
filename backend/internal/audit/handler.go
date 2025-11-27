package audit

import (
	"net/http"
	"strconv"
	"warehouse/internal/auth"
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
	if ctx.Query("limit") == "" || ctx.Query("offset") == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "", "missing pagination params", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

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

	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	logs, err := h.AuditRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to parse role", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "logs selected successfully", logs)
}
