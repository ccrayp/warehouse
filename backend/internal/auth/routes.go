package auth

import (
	"net/http"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

func InitRoutes(r *gin.Engine, db *database.Connector) {
	handler := NewAuthHandler(db)

	r.POST("/auth/login", handler.Login)
	r.POST("/auth/refresh", handler.Refresh)
	r.POST("/auth/validate", handler.Validate)
	r.POST("/auth/me", AuthMiddleware(), handler.Me)
	r.GET("/auth/hash", func(ctx *gin.Context) {
		hash, _ := utils.HashPassword(ctx.Query("password"))
		utils.RespondSuccess(ctx, http.StatusOK, "hash seccessfully gotten", gin.H{
			"password":      ctx.Query("password"),
			"password_hash": hash,
		})
	})
}
