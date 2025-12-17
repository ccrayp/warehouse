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
	limitStr := ctx.Query("limit")
	offsetStr := ctx.Query("offset")

	if limitStr == "" || offsetStr == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "", "missing pagination params", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid limit", nil)
		return
	}

	offset, err := strconv.Atoi(offsetStr)
	if err != nil || offset < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid offset", nil)
		return
	}

	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	// 🔥 фильтры
	filters := AuditFilters{
		Role:      ctx.Query("role"),
		Action:    ctx.Query("action"),
		TableName: ctx.Query("table_name"),
	}

	logs, total, err := h.AuditRepository.GetPagination(
		limit,
		offset,
		claims.Role,
		filters,
	)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "query error", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "logs selected successfully", gin.H{
		"logs":  logs,
		"total": total,
	})
}
