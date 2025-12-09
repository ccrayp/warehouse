package product

import (
	"net/http"
	"os"
	"strconv"
	"time"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type ProductHandler struct {
	productRepository *ProductRepository
}

func NewProductHandler(db *database.Connector) *ProductHandler {
	return &ProductHandler{
		productRepository: NewProductRepository(db),
	}
}

func (h *ProductHandler) GetRouting(ctx *gin.Context) {
	if ctx.Query("limit") != "" || ctx.Query("offset") != "" {
		h.GetProductPagination(ctx)
	} else {
		h.GetProductAll(ctx)
	}
}

func (h *ProductHandler) GetProductAll(ctx *gin.Context) {
	products, err := h.productRepository.GetAll("manager")
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if products == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "products selected successfully", gin.H{
		"products": products,
	})
}

func (h *ProductHandler) GetProductPagination(ctx *gin.Context) {
	if ctx.Query("limit") == "" || ctx.Query("offset") == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "no limit of offset parameter", "no limit or offset parameter", nil)
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

	products, err := h.productRepository.GetPagination(limit, offset, "manager")
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if products == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "products selected successfully", gin.H{
		"products": products,
	})
}

func (h *ProductHandler) GetProductById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "product", claims.Role, h.productRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "product with such id doesn't exist", "product with such id doesn't exist", nil)
		return
	}

	product, err := h.productRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if product == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product successfully selected", gin.H{
		"product": product,
	})
}

func (h *ProductHandler) CreateProduct(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req ProductCreateRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid json", err.Error(), nil)
		return
	}

	if !utils.CheckFK(ctx, req.IdProducer, "producer", claims.Role, h.productRepository.db) {
		return
	}

	if !utils.CheckFK(ctx, req.IdProductCategory, "product_category", claims.Role, h.productRepository.db) {
		return
	}

	req.ImageURL = ""

	id, err := h.productRepository.Create(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, "create error", err.Error(), nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product created", gin.H{
		"id": id,
	})
}

func (h *ProductHandler) UpdateProduct(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	var req ProductUpdateRequest

	if err := ctx.ShouldBindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid json", err.Error(), nil)
		return
	}

	if !utils.CheckFK(ctx, req.IdProducer, "producer", claims.Role, h.productRepository.db) {
		return
	}

	if !utils.CheckFK(ctx, req.IdProductCategory, "product_category", claims.Role, h.productRepository.db) {
		return
	}

	err = h.productRepository.Update(id, req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, "update error", err.Error(), nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product updated", nil)
}

func (h *ProductHandler) DeleteProduct(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "product", claims.Role, h.productRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "product with sush id doesn't eixst", "product with sush id doesn't eixst", nil)
		return
	}

	err = h.productRepository.DeleteById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while delete procudt", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "product was successfully deleted", nil)
}

func (h *ProductHandler) AddProductImage(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "product", claims.Role, h.productRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "exists check error", nil)
		return
	}
	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "product does not exist", "product does not exist", nil)
		return
	}

	file, err := ctx.FormFile("image")
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "image required", err.Error(), nil)
		return
	}

	uploadDir := "/app/uploads/products/"
	filename := strconv.FormatInt(time.Now().UnixNano(), 10) + "_" + file.Filename
	filePath := uploadDir + filename

	_ = os.MkdirAll(uploadDir, os.ModePerm)

	if err := ctx.SaveUploadedFile(file, filePath); err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, "save error", err.Error(), nil)
		return
	}

	imageURL := "/static/products/" + filename

	err = h.productRepository.UpdateImage(id, imageURL, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, "update image error", err.Error(), nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "image updated", gin.H{
		"image_url": imageURL,
	})
}

func (h *ProductHandler) DeleteProductImage(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

}
