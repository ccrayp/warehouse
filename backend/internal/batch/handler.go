package batch

import (
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type BatchHandler struct {
	batchRepository *BatchRepository
}

func NewBatchHandler(db *database.Connector) *BatchHandler {
	return &BatchHandler{
		batchRepository: NewBatchRepository(db),
	}
}

func (h *BatchHandler) GetBatchesPagination(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		utils.RespondError(ctx, http.StatusUnauthorized, "missong token", "missing token", nil)
		return
	}

	limitQuery := ctx.Query("limit")
	limit, err := strconv.Atoi(limitQuery)
	if err != nil {
		return
	}

	offsetQuery := ctx.Query("offset")
	offset, err := strconv.Atoi(offsetQuery)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while parsing of offset", nil)
		return
	}

	batches, err := h.batchRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if batches == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "batches successfully selected", gin.H{
		"batches": batches,
	})
}

func (h *BatchHandler) GetBatchById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	idParam := ctx.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error while parsing id", "error while parsing id", nil)
		return
	}

	batch, err := h.batchRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if batch == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "batch successfully selected", gin.H{
		"batch": batch,
	})
}

func (h *BatchHandler) CreateBatch(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var reqBatch BatchCreateRequest
	err := ctx.BindJSON(&reqBatch)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if !utils.CheckFK(ctx, reqBatch.IdProduct, "product", claims.Role, h.batchRepository.db) {
		return
	}

	if !reqBatch.ProductionDate.Before(reqBatch.ExpirationDate) {
		utils.RespondError(ctx, http.StatusBadRequest, "wrong date", "wrong date", nil)
		return
	}

	if reqBatch.Cost <= 0.0 {
		utils.RespondError(ctx, http.StatusBadRequest, "wrong cost", "wrong cost", nil)
		return
	}

	newBatch, err := h.batchRepository.Create(reqBatch, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, "error while insert", "error while insert", nil)
		return
	}

	if newBatch == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "batch successfully created", gin.H{
		"batch": newBatch,
	})
}

func (h *BatchHandler) UpdateBatch(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	idParam := ctx.Param("id")
	id, err := strconv.Atoi(idParam)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while id parsing", nil)
		return
	}

	exists, err := utils.CheckExists(id, "batch", claims.Role, h.batchRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while existence checking", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "batch with such id doesn't exist", "batch with such id doesn't exist", nil)
		return
	}

	var reqBatch BacthUpdateRequest
	err = ctx.BindJSON(&reqBatch)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if !utils.CheckFK(ctx, reqBatch.IdProduct, "product", claims.Role, h.batchRepository.db) {
		return
	}

	if !reqBatch.ProductionDate.Before(reqBatch.ExpirationDate) {
		utils.RespondError(ctx, http.StatusBadRequest, "wrong date", "wrong date", nil)
		return
	}

	if reqBatch.Cost <= 0.0 {
		utils.RespondError(ctx, http.StatusBadRequest, "wrong cost", "wrong cost", nil)
		return
	}

	updatedBatch, err := h.batchRepository.Update(reqBatch, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, "error while update", "error while update", nil)
		return
	}

	if updatedBatch == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "batch successfully updated", gin.H{
		"batch": updatedBatch,
	})
}

func (h *BatchHandler) DeleteBatchById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var reqBatch BatchDeleteRequest
	err := ctx.BindJSON(&reqBatch)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	exists, err := utils.CheckExists(reqBatch.ID, "batch", claims.Role, h.batchRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while existence checking", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "batch with such id doesn't exist", "batch with such id doesn't exist", nil)
		return
	}

	err = h.batchRepository.Delete(reqBatch.ID, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while deleting", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "batch was successfully deleted", nil)
}
