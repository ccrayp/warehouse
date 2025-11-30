package gender

import (
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type GenderHandler struct {
	genderRepository *GenderRepository
}

func NewGenderHandler(db *database.Connector) *GenderHandler {
	return &GenderHandler{
		genderRepository: NewGenderRepository(db),
	}
}

func (h *GenderHandler) GetAllGenders(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	genders, err := h.genderRepository.GetAll(claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if genders == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "genders successfully selected", gin.H{
		"genders": genders,
	})
}

func (h *GenderHandler) GetGenderById(ctx *gin.Context) {
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

	exists, err := utils.CheckExists(id, "gender", claims.Role, h.genderRepository.db)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while existence checking")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "gender with such id doesn't exist", "gender with such id doesn't exist", nil)
		return
	}

	gender, err := h.genderRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if gender == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "gender selected successfully", gin.H{
		"gender": gender,
	})
}
