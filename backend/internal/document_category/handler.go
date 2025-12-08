package documentcategory

import (
	"net/http"
	"strconv"
	"unicode/utf8"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type DocumentCategoryHandler struct {
	documentCategoryRepository *DocumentCategoryRepository
}

func NewDocumentCategoryHandler(db *database.Connector) *DocumentCategoryHandler {
	return &DocumentCategoryHandler{
		documentCategoryRepository: NewDocumentCategoryRepository(db),
	}
}

func (h *DocumentCategoryHandler) GetDocumentCategoryPagination(ctx *gin.Context) {
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

	documentCategories, err := h.documentCategoryRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if documentCategories == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document_category successfully selected", gin.H{
		"document_categories": documentCategories,
	})
}

func (h *DocumentCategoryHandler) GetDocumentCategoryByID(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_category", claims.Role, h.documentCategoryRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "document_category with such id doesn't exist", "docuemnt_category with such id doesn't exist", nil)
		return
	}

	documentCategory, err := h.documentCategoryRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if documentCategory == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "docuemnt_category successfully selected", gin.H{
		"document_category": documentCategory,
	})
}

func (h *DocumentCategoryHandler) CreateDocumentCategory(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req DocumentCategoryRequest
	err := ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while parsing data", nil)
		return
	}

	if utf8.RuneCountInString(req.Name) > 50 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid name", "invalid name", nil)
		return
	}

	id, err := h.documentCategoryRepository.Create(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "document_category successfully created", gin.H{
		"id": id,
	})
}

func (h *DocumentCategoryHandler) UpdateDocumentCategory(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_category", claims.Role, h.documentCategoryRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "document_category with such id doesn't exist", "document_category with such id doesn't exist", nil)
		return
	}

	var req DocumentCategoryRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while parsing data", nil)
		return
	}

	if utf8.RuneCountInString(req.Name) > 50 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid name", "invalid name", nil)
		return
	}

	err = h.documentCategoryRepository.Update(req, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "document_catrgory successfully update", nil)
}

func (h *DocumentCategoryHandler) DeleteDocumentCategory(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_category", claims.Role, h.documentCategoryRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "document_category with such id doesn't exist", "document_category with such id doesn't exist", nil)
		return
	}

	err = h.documentCategoryRepository.Delete(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while delete", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document_category was successfully deleted", nil)
}
