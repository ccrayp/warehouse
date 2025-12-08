package address

import (
	"net/http"
	"strconv"
	"unicode/utf8"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type AddressHandler struct {
	addressRepository *AddressRepository
}

func NewAddressHandler(db *database.Connector) *AddressHandler {
	return &AddressHandler{
		addressRepository: NewAddressRepository(db),
	}
}

func (h *AddressHandler) GetAddressPagination(ctx *gin.Context) {
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

	addresses, err := h.addressRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if addresses == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "addresses were selected successfully", gin.H{
		"addresses": addresses,
	})
}

func (h *AddressHandler) GetAddressById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "address", claims.Role, h.addressRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "address with such id doesn't exist", "address with such id doesn't exist", nil)
		return
	}

	address, err := h.addressRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while select", nil)
		return
	}

	if address == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "permission denied for table", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "address was successfully selected", gin.H{
		"address": address,
	})
}

func (h *AddressHandler) CreateAddress(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req AddressRequest
	err := ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if !h.CheckAddress(req) {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid address", "invalid address", nil)
		return
	}

	id, err := h.addressRepository.Create(req, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while create", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "address was successfully created", gin.H{
		"id": id,
	})
}

func (h *AddressHandler) UpdateAddress(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "address", claims.Role, h.addressRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "address with such id doesn't exist", "address with such id doesn't exist", nil)
		return
	}

	var req AddressRequest
	err = ctx.BindJSON(&req)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while data parsing", nil)
		return
	}

	if !h.CheckAddress(req) {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid address", "invalid address", nil)
		return
	}

	err = h.addressRepository.Update(req, id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while update", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "address was successfully updated", nil)
}

func (h *AddressHandler) DeleteAddress(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	id, err := strconv.Atoi(ctx.Param("id"))
	if err != nil || id < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, "invalid id", "invalid id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "address", claims.Role, h.addressRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exists check", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusNotFound, "address with such id doesn't exist", "address with such id doesn't exist", nil)
		return
	}

	err = h.addressRepository.Delete(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while delete", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "address was successfully deleted", nil)
}

func (h *AddressHandler) CheckAddress(req AddressRequest) bool {
	if utf8.RuneCountInString(req.Subject) > 100 {
		return false
	}
	if utf8.RuneCountInString(req.Region) > 100 {
		return false
	}
	if utf8.RuneCountInString(req.City) > 100 {
		return false
	}
	if utf8.RuneCountInString(req.Street) > 100 {
		return false
	}
	if req.Building <= 0 {
		return false
	}

	return true
}
