package utils

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"
	"warehouse/pkg/database"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type Response struct {
	Success      bool   `json:"success"`
	Message      string `json:"message"`
	Status       int    `json:"status"`
	Data         any    `json:"data"`
	Error        string `json:"error"`
	Endpoint     string `json:"endpoint"`
	ResponseTime string `json:"response_time"`
}

func RespondSuccess(ctx *gin.Context, httpStatus int, message string, data any) {
	ctx.JSON(http.StatusOK, Response{
		Success:      true,
		Message:      message,
		Status:       httpStatus,
		Data:         data,
		Error:        "",
		Endpoint:     ctx.FullPath(),
		ResponseTime: time.Now().Local().Format("2006-01-02 15:04:05 MST"),
	})
}

func RespondError(ctx *gin.Context, httpStatus int, error string, message string, requestedStructure any) {
	ctx.JSON(httpStatus, Response{
		Success:      false,
		Message:      message,
		Status:       httpStatus,
		Data:         requestedStructure,
		Error:        error,
		Endpoint:     ctx.FullPath(),
		ResponseTime: time.Now().Local().Format("2006-01-02 15:04:05 MST"),
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

func CheckExists(id int, table string, role string, db *database.Connector) (bool, error) {
	pool, err := db.GetPool(role)
	if err != nil {
		return false, err
	}

	sql := fmt.Sprintf(`SELECT EXISTS (SELECT 1 FROM %s WHERE id=$1)`, table)

	var exists bool
	err = pool.QueryRow(context.Background(), sql, id).Scan(&exists)
	if err != nil {
		return false, err
	}

	return exists, nil
}

func CheckFK(ctx *gin.Context, id int, table string, role string, db *database.Connector) bool {
	exists, err := CheckExists(id, table, role, db)
	if err != nil {
		RespondError(ctx, http.StatusInternalServerError, err.Error(), fmt.Sprintf("error checking %s", table), nil)
		return false
	}
	if !exists {
		RespondError(ctx, http.StatusBadRequest, fmt.Sprintf("%s with such id doesn't exist", table), fmt.Sprintf("%s not found", table), nil)
		return false
	}
	return true
}

func CheckPermissionDenied(err error, defautStatus int, defaultMessage string) (int, string) {
	if strings.Contains(err.Error(), "42501") {
		return http.StatusForbidden, "permission denied for table"
	}

	return defautStatus, defaultMessage
}
