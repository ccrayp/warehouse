package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Response struct {
	Success  bool   `json:"success"`
	Message  string `json:"message"`
	Status   int    `json:"status"`
	Data     any    `json:"data"`
	Error    string `json:"error"`
	Endpoint string `json:"endpoint"`
}

func RespondSuccess(ctx *gin.Context, httpStatus int, message string, data any) {
	ctx.JSON(http.StatusOK, Response{
		Success:  true,
		Message:  message,
		Status:   httpStatus,
		Data:     data,
		Error:    "",
		Endpoint: ctx.FullPath(),
	})
}

func RespondError(ctx *gin.Context, httpStatus int, error string, message string, requestedStructure any) {
	ctx.JSON(httpStatus, Response{
		Success:  false,
		Message:  message,
		Status:   httpStatus,
		Data:     requestedStructure,
		Error:    error,
		Endpoint: ctx.FullPath(),
	})
}

func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
