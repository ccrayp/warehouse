package role

import (
	"errors"
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type RoleHandler struct {
	Repo *RoleRepository
}

func NewRoleHandler(db *database.Connector) *RoleHandler {
	return &RoleHandler{
		Repo: NewRoleRepository(db),
	}
}

func (h *RoleHandler) GetRolesPagination(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	limitStr := ctx.Query("limit")
	offsetStr := ctx.Query("offset")
	if limitStr == "" || offsetStr == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "", "missing pagination params", gin.H{"required_data": "?limit=int&offset=int"})
		return
	}

	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid limit", gin.H{"required_data": "?limit=int&offset=int"})
		return
	}

	offset, err := strconv.Atoi(offsetStr)
	if err != nil || offset < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid offset", gin.H{"required_data": "?limit=int&offset=int"})
		return
	}

	roles, err := h.Repo.GetPagination(limit, offset, claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while query")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "roles selected successfully", gin.H{"roles": roles})
}

func (h *RoleHandler) GetRoleById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	idStr := ctx.Param("id")
	if idStr == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "id not received", "id not received", gin.H{"required_data": "id"})
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error parse id", "error parse id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "role", claims.Role, h.Repo.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error checking existence", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "role with such id doesn't exist", "role with such id doesn't exist", nil)
		return
	}

	roleObj, err := h.Repo.GetById(id, claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while query")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "role successfully selected", gin.H{"role": roleObj})
}

func (h *RoleHandler) CreateRole(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req RoleCreateRequest
	if err := ctx.BindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "fail to bind request", gin.H{"required_data": RoleCreateRequest{}})
		return
	}

	if err := validateRole(req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid role data", gin.H{"required_data": RoleCreateRequest{}})
		return
	}

	id, err := h.Repo.Create(req, claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusBadRequest, "error while creating role")
		utils.RespondError(ctx, status, err.Error(), message, gin.H{"required_data": RoleCreateRequest{}})
		return
	}

	roleObj, _ := h.Repo.GetById(*id, claims.Role)
	utils.RespondSuccess(ctx, http.StatusCreated, "role successfully created", gin.H{"role": roleObj})
}

func (h *RoleHandler) UpdateRole(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	idStr := ctx.Param("id")
	if idStr == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "id not received", "id not received", gin.H{"required_data": "id"})
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error parse id", "error parse id", nil)
		return
	}

	var req RoleUpdateRequest
	if err := ctx.BindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "fail to bind request", gin.H{"required_data": RoleUpdateRequest{}})
		return
	}

	if err := validateRole(req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid role data", gin.H{"required_data": RoleUpdateRequest{}})
		return
	}

	updated, err := h.Repo.Update(id, req, claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusBadRequest, "error while updating role")
		utils.RespondError(ctx, status, err.Error(), message, gin.H{"required_data": RoleUpdateRequest{}})
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "role successfully updated", gin.H{"role": updated})
}

func (h *RoleHandler) DeleteRole(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	idStr := ctx.Param("id")
	if idStr == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "id not received", "id not received", gin.H{"required_data": "id"})
		return
	}

	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error parse id", "error parse id", nil)
		return
	}

	exists, err := utils.CheckExists(id, "role", claims.Role, h.Repo.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error checking existence", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "role with such id doesn't exist", "role with such id doesn't exist", nil)
		return
	}

	if err := h.Repo.Delete(id, claims.Role); err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while deleting role")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "role successfully deleted", nil)
}

func validateRole(u interface{}) error {
	switch v := u.(type) {
	case RoleCreateRequest:
		if len(v.Name) == 0 {
			return errors.New("name is required")
		}
		if len(v.Name) > 50 {
			return errors.New("name cannot exceed 50 characters")
		}
		if len(v.SysRole) == 0 {
			return errors.New("sys_role is required")
		}
		if len(v.SysRole) > 50 {
			return errors.New("sys_role cannot exceed 50 characters")
		}
	case RoleUpdateRequest:
		if len(v.Name) == 0 {
			return errors.New("name is required")
		}
		if len(v.Name) > 50 {
			return errors.New("name cannot exceed 50 characters")
		}
		if len(v.SysRole) == 0 {
			return errors.New("sys_role is required")
		}
		if len(v.SysRole) > 50 {
			return errors.New("sys_role cannot exceed 50 characters")
		}
	default:
		return errors.New("invalid type")
	}
	return nil
}
