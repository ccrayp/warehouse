package productcategory

import (
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type ProductCategoryHandler struct {
	productCategoryRepository *ProductCategoryRepository
}

func NewProductCategoryHandler(db *database.Connector) *ProductCategoryHandler {
	return &ProductCategoryHandler{
		productCategoryRepository: NewProductCategoryRepository(db),
	}
}

func (h *ProductCategoryHandler) GetRouting(ctx *gin.Context) {
	if ctx.Query("limit") != "" || ctx.Query("offset") != "" {
		h.GetProductCategoryPagination(ctx)
	} else {
		h.GetProductCategoryAll(ctx)
	}
}

func (h *ProductCategoryHandler) GetProductCategoryAll(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	productCategories, err := h.productCategoryRepository.GetAll(claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if productCategories == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied fo table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product categories were successfully selected", gin.H{
		"product_categories": productCategories,
	})
}

func (h *ProductCategoryHandler) GetProductCategoryPagination(ctx *gin.Context) {
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

	productCategories, err := h.productCategoryRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if productCategories == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied fo table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product categories were successfully selected", gin.H{
		"product_categories": productCategories,
	})
}

func (h *ProductCategoryHandler) GetProductCategoryById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "product_category", claims.Role, h.productCategoryRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "product catrgory with such id doesn't exist", "product catrgory with such id doesn't exist", nil)
		return
	}

	productCategory, err := h.productCategoryRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if productCategory == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product category was succesfully selected", gin.H{
		"product_category": productCategory,
	})
}

func (h *ProductCategoryHandler) CreateProductCategory(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req ProductCategoryCreateRequest

	if err := ctx.BindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	id, err := h.productCategoryRepository.Create(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "product category was successfully created", gin.H{
		"id": id,
	})
}

func (h *ProductCategoryHandler) UpdateProductCategory(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "product_category", claims.Role, h.productCategoryRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "product categry with such id doesn't exist", "product categry with such id doesn't exist", nil)
		return
	}

	var req ProductCategoryUpdateRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
	}

	err = h.productCategoryRepository.Update(id, req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product category was successfully updated", nil)
}

func (h *ProductCategoryHandler) DeleteProductCsategory(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "product_category", claims.Role, h.productCategoryRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "product catrgory with such id doesn't exist", "product catrgory with such id doesn't exist", nil)
		return
	}

	err = h.productCategoryRepository.DeleteById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product category was succesfully deleted", nil)
}
