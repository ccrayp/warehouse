package document

import (
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/internal/document/models"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type DocumentHandler struct {
	documentRepository *DocumentRepository
}

func NewDocumentHandler(db *database.Connector) *DocumentHandler {
	return &DocumentHandler{
		documentRepository: NewDocumentRepository(db),
	}
}

func (h *DocumentHandler) GetDocumentPagination(ctx *gin.Context) {
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

	documents, err := h.documentRepository.GetDocumentPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if documents == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document were successfully selected", gin.H{
		"document": documents,
	})
}

func (h *DocumentHandler) GetDocumentById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "docuemnt with such id doesn't exist", "docuement with such id doesn't exist", nil)
		return
	}

	document, err := h.documentRepository.GetDocumentById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if document == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document was successfully selected", gin.H{
		"document": document,
	})
}

func (h *DocumentHandler) CreateDocument(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req models.DocumentRequest
	err := ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if !utils.CheckFK(ctx, req.IdEmployee, "employee", claims.Role, h.documentRepository.db) {
		return
	}

	if !utils.CheckFK(ctx, req.IdDocumentCategory, "document_category", claims.Role, h.documentRepository.db) {
		return
	}

	id, err := h.documentRepository.CreateDocument(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "document was successfully created", gin.H{
		"id": id,
	})
}

func (h *DocumentHandler) UpdateDocuemnt(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "document with such id doesn't exist", "document with such id doesn't exist", nil)
		return
	}

	var req models.DocumentRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if !utils.CheckFK(ctx, req.IdEmployee, "employee", claims.Role, h.documentRepository.db) {
		return
	}

	if !utils.CheckFK(ctx, req.IdDocumentCategory, "document_category", claims.Role, h.documentRepository.db) {
		return
	}

	err = h.documentRepository.UpdateDocuemnt(req, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document was successfully updated", nil)
}

func (h *DocumentHandler) DeleteDocument(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "docuemnt with such id doesn't exist", "docuement with such id doesn't exist", nil)
		return
	}

	err = h.documentRepository.DeleteDocument(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while delete", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document was successfully deleted", nil)
}

func (h *DocumentHandler) GetContentPagination(ctx *gin.Context) {
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

	contents, err := h.documentRepository.GetContentPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if contents == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document_contents were successfully selected", gin.H{
		"document_contents": contents,
	})
}

func (h *DocumentHandler) GetContentById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_content", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "docuemnt_content with such id doesn't exist", "docuemnt_content with such id doesn't exist", nil)
		return
	}

	content, err := h.documentRepository.GetContentById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if content == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document_content was successfully selected", gin.H{
		"document_content": content,
	})
}

func (h *DocumentHandler) GetAllContentByDocuemntId(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_content", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "docuemnt_content with such id doesn't exist", "docuemnt_content with such id doesn't exist", nil)
		return
	}

	contents, err := h.documentRepository.GetAllContentByDocuemntId(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if contents == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document_contents were successfully selected", gin.H{
		"document_contens": contents,
	})
}

func (h *DocumentHandler) CreateContent(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req models.ContentRequest
	err := ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if req.Quantity <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid quantity", "invalid quantity", nil)
		return
	}

	if !utils.CheckFK(ctx, req.IdBatch, "batch", claims.Role, h.documentRepository.db) {
		return
	}

	if !utils.CheckFK(ctx, req.IdDocument, "document", claims.Role, h.documentRepository.db) {
		return
	}

	id, err := h.documentRepository.CreateContent(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "document_content was successfully created", gin.H{
		"id": id,
	})
}

func (h *DocumentHandler) UpdateConetent(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_content", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "document_content with such id doesn't exist", "document_content with such id doesn't exist", nil)
		return
	}

	var req models.ContentRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if req.Quantity <= 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid quantity", "invalid quantity", nil)
		return
	}

	if !utils.CheckFK(ctx, req.IdBatch, "batch", claims.Role, h.documentRepository.db) {
		return
	}

	if !utils.CheckFK(ctx, req.IdDocument, "document", claims.Role, h.documentRepository.db) {
		return
	}

	err = h.documentRepository.UpdateContent(req, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "document_content was successfully updated", nil)
}

func (h *DocumentHandler) DeleteContent(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "document_content", claims.Role, h.documentRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "docuemnt_content with such id doesn't exist", "docuemnt_content with such id doesn't exist", nil)
		return
	}

	err = h.documentRepository.DeleteContent(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusOK, err.Error(), "error while delete", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "document_content was successfully deleted", nil)
}
