package producer

import (
	"net/http"
	"strconv"
	"unicode/utf8"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type ProducerHandler struct {
	producerRepository *ProducerRepository
}

func NewProducerHandler(db *database.Connector) *ProducerHandler {
	return &ProducerHandler{
		producerRepository: NewProducerRepository(db),
	}
}

func (h *ProducerHandler) GetRouting(ctx *gin.Context) {
	if ctx.Query("limit") != "" || ctx.Query("offset") != "" {
		h.GetProducerPagination(ctx)
	} else {
		h.GetProducerAll(ctx)
	}
}

func (h *ProducerHandler) GetProducerAll(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	producers, err := h.producerRepository.GetAll(claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if producers == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "producers selected successfully", gin.H{
		"producers": producers,
	})
}

func (h *ProducerHandler) GetProducerPagination(ctx *gin.Context) {
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
		utils.RespondError(ctx, http.StatusBadRequest, "invalid offset", "limit offset", nil)
		return
	}

	producers, err := h.producerRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if producers == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "producers selected successfully", gin.H{
		"producers": producers,
	})
}

func (h *ProducerHandler) GetProducerById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "producer", claims.Role, h.producerRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "producer with such id doesn't exist", "producer with such id doesn't exist", nil)
		return
	}

	producer, err := h.producerRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if producer == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied fo table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "producer was successfully selected", gin.H{
		"producer": producer,
	})
}

func (h *ProducerHandler) CreateProducer(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req ProducerRequest
	err := ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	valid, err := h.CheckProducer(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "erorr while validation", nil)
		return
	}

	if !valid {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid data", "invalid data", nil)
		return
	}

	id, err := h.producerRepository.Create(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "producer was successfully created", gin.H{
		"id": id,
	})
}

func (h *ProducerHandler) UpdateProducer(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "producer", claims.Role, h.producerRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "producer with such id doesn't exist", "producer with such id doesn't exist", nil)
		return
	}

	var req ProducerRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	valid, err := h.CheckProducer(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "erorr while validation", nil)
		return
	}

	if !valid {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid data", "invalid data", nil)
		return
	}

	err = h.producerRepository.Update(req, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "producer was successfully updated", nil)
}

func (h *ProducerHandler) DeleteProducer(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "producer", claims.Role, h.producerRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusBadRequest, "producer with such id doesn't exist", "producer with such id doesn't exist", nil)
		return
	}

	err = h.producerRepository.Delete(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while delete", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "producer was successfully deleted", nil)
}

func (h *ProducerHandler) CheckProducer(producer ProducerRequest, role string) (bool, error) {
	if utf8.RuneCountInString(producer.Surname) > 50 {
		return false, nil
	}
	if utf8.RuneCountInString(producer.Firstname) > 50 {
		return false, nil
	}
	if utf8.RuneCountInString(producer.Patronymic) > 50 {
		return false, nil
	}
	if utf8.RuneCountInString(producer.INN) > 10 {
		return false, nil
	}

	exists, err := utils.CheckExists(producer.IdAddress, "address", role, h.producerRepository.db)
	if err != nil || !exists {
		return false, nil
	}

	return true, nil
}
