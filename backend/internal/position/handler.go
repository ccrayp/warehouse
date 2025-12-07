package position

import (
	"net/http"
	"strconv"
	"unicode/utf8"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type PositionHandler struct {
	positionRepository *PositionRepository
}

func NewPositionHandler(db *database.Connector) *PositionHandler {
	return &PositionHandler{
		positionRepository: NewPositionRepository(db),
	}
}

func (h *PositionHandler) GetPositionPagination(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	limit, err := strconv.Atoi(ctx.Query("limit"))
	if err != nil || limit < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid limit", "invalid limit", nil)
		return
	}

	offset, err := strconv.Atoi(ctx.Query("offset"))
	if err != nil || offset < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid offset", "invalid offset", nil)
		return
	}

	positions, err := h.positionRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if positions == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "position successfully selected", gin.H{
		"positions": positions,
	})
}

func (h *PositionHandler) GetPositionById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "position", claims.Role, h.positionRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "position with such id doesn't exist", "position with such id doesn't exist", nil)
		return
	}

	potition, err := h.positionRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if potition == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "position successfully selected", gin.H{
		"position": potition,
	})
}

func (h *PositionHandler) CreatePosition(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req PositionRequest
	err := ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while parsing data", nil)
		return
	}

	if utf8.RuneCountInString(req.Name) > 50 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid name", "invalid name", nil)
		return
	}

	id, err := h.positionRepository.Create(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "position successfully created", gin.H{
		"id": id,
	})
}

func (h *PositionHandler) UpdatePosition(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "position", claims.Role, h.positionRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "position with such id doesn't exist", "position with such id doesn't exist", nil)
		return
	}

	var req PositionRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while parsing data", nil)
		return
	}

	if utf8.RuneCountInString(req.Name) > 50 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid name", "invalid name", nil)
		return
	}

	err = h.positionRepository.Update(req, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "position successfully update", nil)
}

func (h *PositionHandler) DeletePosition(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "position", claims.Role, h.positionRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "position with such id doesn't exist", "position with such id doesn't exist", nil)
		return
	}

	err = h.positionRepository.Delete(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while delete", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "position was successfully deleted", nil)
}
