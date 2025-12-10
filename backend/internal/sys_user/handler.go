package sys_user

import (
	"errors"
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type SysUserHandler struct {
	Repo *SysUserRepository
}

func NewSysUserHandler(db *database.Connector) *SysUserHandler {
	return &SysUserHandler{
		Repo: NewSysUserRepository(db),
	}
}

func (h *SysUserHandler) GetRouting(ctx *gin.Context) {
	if ctx.Query("limit") != "" || ctx.Query("offset") != "" {
		h.GetUsersPagination(ctx)
	} else {
		h.GetUsersAll(ctx)
	}
}

func (h *SysUserHandler) GetUsersAll(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	users, err := h.Repo.GetAll(claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while query")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	if users == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "query error", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "users selected successfully", gin.H{"users": users})
}

func (h *SysUserHandler) GetUsersPagination(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	limitStr := ctx.Query("limit")
	offsetStr := ctx.Query("offset")
	if limitStr == "" || offsetStr == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "", "missing pagination params", gin.H{
			"required_data": "?limit=int&offset=int",
		})
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

	users, total, err := h.Repo.GetPagination(limit, offset, claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while query")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	if users == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "query error", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "users selected successfully", gin.H{"users": users, "total": total})
}

func (h *SysUserHandler) GetUserById(ctx *gin.Context) {
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

	exists, err := utils.CheckExists(id, "sys_user", claims.Role, h.Repo.db)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error checking existence")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "sys_user with such id doesn't exist", "sys_user with such id doesn't exist", nil)
		return
	}

	user, err := h.Repo.GetById(id, claims.Role)
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while query")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	if user == nil {
		utils.RespondError(ctx, http.StatusForbidden, "permission denied for table", "query error", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "user was successfully selected", gin.H{"user": user})
}

func (h *SysUserHandler) CreateUser(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var req SysUserCreateRequest
	if err := ctx.BindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "fail to bind request", gin.H{"required_data": SysUserCreateRequest{}})
		return
	}

	if !utils.CheckFK(ctx, req.IdRole, "role", claims.Role, h.Repo.db) {
		return
	}
	if !utils.CheckFK(ctx, req.IdEmployee, "employee", claims.Role, h.Repo.db) {
		return
	}

	if err := validateSysUser(req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid user data", gin.H{"required_data": SysUserCreateRequest{}})
		return
	}

	hash, err := utils.HashPassword(req.Password)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to hash password", nil)
		return
	}

	id, err := h.Repo.Create(req, claims.Role, string(hash))
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusBadRequest, "error while creating user")
		utils.RespondError(ctx, status, err.Error(), message, gin.H{"required_data": SysUserCreateRequest{}})
		return
	}

	user, _ := h.Repo.GetById(*id, claims.Role)
	utils.RespondSuccess(ctx, http.StatusCreated, "user successfully created", gin.H{"user": user})
}

func (h *SysUserHandler) UpdateUser(ctx *gin.Context) {
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

	var req SysUserCreateUpdateRequest
	if err := ctx.BindJSON(&req); err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "fail to bind request", gin.H{"required_data": SysUserCreateUpdateRequest{}})
		return
	}

	if !utils.CheckFK(ctx, req.IdRole, "role", claims.Role, h.Repo.db) {
		return
	}
	if !utils.CheckFK(ctx, req.IdEmployee, "employee", claims.Role, h.Repo.db) {
		return
	}

	if err := validateSysUser(req); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid user data", gin.H{"required_data": SysUserCreateUpdateRequest{}})
		return
	}

	hash, err := utils.HashPassword(req.Password)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to hash password", nil)
		return
	}

	updated, err := h.Repo.Update(id, req, claims.Role, string(hash))
	if err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusBadRequest, "error while updating user")
		utils.RespondError(ctx, status, err.Error(), message, gin.H{"required_data": SysUserCreateUpdateRequest{}})
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "user successfully updated", gin.H{"user": updated})
}

func (h *SysUserHandler) DeleteUser(ctx *gin.Context) {
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

	exists, err := utils.CheckExists(id, "sys_user", claims.Role, h.Repo.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error checking existence", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "sys_user with such id doesn't exist", "sys_user with such id doesn't exist", nil)
		return
	}

	if err := h.Repo.Delete(id, claims.Role); err != nil {
		status, message := utils.CheckPermissionDenied(err, http.StatusInternalServerError, "error while deleting user")
		utils.RespondError(ctx, status, err.Error(), message, nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "user successfully deleted", nil)
}

func validateSysUser(u interface{}) error {
	switch v := u.(type) {
	case SysUserCreateRequest:
		if len(v.Login) == 0 {
			return errors.New("login is required")
		}
		if len(v.Login) > 50 {
			return errors.New("login cannot exceed 50 characters")
		}
		if len(v.Password) < 6 {
			return errors.New("password must be at least 6 characters")
		}
	case SysUserCreateUpdateRequest:
		if len(v.Login) == 0 {
			return errors.New("login is required")
		}
		if len(v.Login) > 50 {
			return errors.New("login cannot exceed 50 characters")
		}
		if len(v.Password) < 6 {
			return errors.New("password must be at least 6 characters")
		}
	default:
		return errors.New("invalid type")
	}
	return nil
}
