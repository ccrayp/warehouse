package auth

import (
	"net/http"

	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	AuthRepository *AuthRepository
}

func NewAuthHandler(db *database.Connector) *AuthHandler {
	return &AuthHandler{
		AuthRepository: NewAuthRepository(db),
	}
}

func (h *AuthHandler) Login(ctx *gin.Context) {
	var data LoginRequest

	ctx.BindJSON(&data)

	role, err := h.AuthRepository.GetRoleByUsername(data.Username)
	if err != nil {
		utils.RespondError(ctx, http.StatusUnauthorized, err.Error(), "user with such username not found", gin.H{
			"required_data": LoginRequest{
				Username: "string",
				Password: "string",
			}})
		return
	}

	hash, err := h.AuthRepository.GetPassword(data.Username)
	if err != nil {
		utils.RespondError(ctx, http.StatusUnauthorized, err.Error(), "wrong login or password", gin.H{
			"required_data": LoginRequest{
				Username: "string",
				Password: "string",
			}})
		return
	}

	if !utils.CheckPasswordHash(data.Password, string(hash)) {
		utils.RespondError(ctx, http.StatusUnauthorized, "wrong password", "", gin.H{
			"required_data": LoginRequest{
				Username: "string",
				Password: "string",
			}})
		return
	}

	accessToken, err := GenerateToken(data.Username, role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to generate access token", gin.H{
			"required_data": LoginRequest{
				Username: "string",
				Password: "string",
			}})
	}

	claims, _ := ValidateToken(accessToken)
	refreshToken, err := GenerateRefreshToken(h.AuthRepository, data.Username, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "failed to generate refresh token", gin.H{
			"required_data": LoginRequest{
				Username: "string",
				Password: "string",
			}})
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "successed to generate access and refresh tokens", gin.H{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

func (h *AuthHandler) Refresh(ctx *gin.Context) {
	var data RefreshRequest

	if err := ctx.BindJSON(&data); err != nil || data.RefreshToken == "" {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "refresh token required", gin.H{
			"required_data": RefreshRequest{
				RefreshToken: "string",
			}})
		return
	}

	newAccessToken, newRefreshToken, err := RefreshAccessToken(h.AuthRepository, data.RefreshToken)
	if err != nil {
		utils.RespondError(ctx, http.StatusUnauthorized, err.Error(), "invalid refresh token", gin.H{
			"required_data": RefreshRequest{
				RefreshToken: "string",
			}})
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "successfully refreshed", gin.H{
		"access_token":  newAccessToken,
		"refresh_token": newRefreshToken,
	})
}

func (h *AuthHandler) Validate(ctx *gin.Context) {
	var data ValidateRequest
	ctx.BindJSON(&data)

	if data.AccessToken == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "token not provided", "token not provided", gin.H{
			"required_data": ValidateRequest{
				AccessToken: "string",
			}})
		return
	}

	claims, err := ValidateToken(data.AccessToken)
	if err != nil {
		utils.RespondError(ctx, http.StatusUnauthorized, "invalid token", "invalid token", gin.H{
			"required_data": ValidateRequest{
				AccessToken: "string",
			}})
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "tokena was validated", gin.H{"claims": claims})
}
