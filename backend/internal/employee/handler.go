package employee

import (
	"errors"
	"net/http"
	"strconv"
	"warehouse/internal/auth"
	"warehouse/pkg/database"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
)

type EmployeeHandler struct {
	EmployeeRepository *EmployeeRepository
}

func NewEmployeeHandler(db *database.Connector) *EmployeeHandler {
	return &EmployeeHandler{
		EmployeeRepository: NewEmployeeRepository(db),
	}
}

func (h *EmployeeHandler) GetEmployeesPagination(ctx *gin.Context) {

	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	if ctx.Query("limit") == "" || ctx.Query("offset") == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "", "missing pagination params", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

	limit, err := strconv.Atoi(ctx.Query("limit"))
	if err != nil || limit < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid limit", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

	offset, err := strconv.Atoi(ctx.Query("offset"))
	if err != nil || offset < 0 {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid offset", gin.H{
			"required_data": "?limit=int&offset=int",
		})
		return
	}

	employees, err := h.EmployeeRepository.GetPagination(limit, offset, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "query error", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "employees selected successfully", gin.H{
		"employees": employees,
	})
}

func (h *EmployeeHandler) GetEmployeeById(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	employeeIdString := ctx.Param("id")
	if employeeIdString == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "id was not recieved", "id was not recieved", gin.H{
			"required_data": "id",
		})
		return
	}

	id, err := strconv.Atoi(employeeIdString)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error parse id", "error parse id", nil)
		return
	}

	exists, err := utils.CheckExists(id, h.EmployeeRepository.TableName, claims.Role, h.EmployeeRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exist checking", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "employee with such id doesn't eixst", "employee with such id doesn't eixst", nil)
		return
	}

	employee, err := h.EmployeeRepository.GetById(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while query", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "employee was successfully selected", gin.H{
		"employee": employee,
	})
}

func (h *EmployeeHandler) CreateEmployee(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	var employeeData Employee
	err := ctx.BindJSON(&employeeData)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "fail to bind employee", gin.H{
			"required_data": Employee{},
		})
	}

	if !utils.CheckFK(ctx, employeeData.IdGender, "gender", claims.Role, h.EmployeeRepository.db) {
		return
	}
	if !utils.CheckFK(ctx, employeeData.IdPosition, "position", claims.Role, h.EmployeeRepository.db) {
		return
	}
	if !utils.CheckFK(ctx, employeeData.IdAddress, "address", claims.Role, h.EmployeeRepository.db) {
		return
	}

	if err := validateEmployee(employeeData); err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "invalid employee data", gin.H{"required_data": Employee{}})
		return
	}

	employee, err := h.EmployeeRepository.Create(employeeData, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, err.Error(), "error while creating", gin.H{
			"required_data": Employee{},
		})
		return
	}

	utils.RespondSuccess(ctx, http.StatusCreated, "employee was successfully created", gin.H{
		"employee": employee,
	})
}

func (h *EmployeeHandler) UpdateEmployee(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	employeeIdString := ctx.Param("id")
	if employeeIdString == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "id was not recieved", "id was not recieved", gin.H{
			"required_data": "id",
		})
		return
	}

	id, err := strconv.Atoi(employeeIdString)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error parse id", "error parse id", nil)
		return
	}

	exists, err := utils.CheckExists(id, h.EmployeeRepository.TableName, claims.Role, h.EmployeeRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exist checking", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "employee with such id doesn't eixst", "employee with such id doesn't eixst", nil)
		return
	}

}

func (h *EmployeeHandler) DeleteEmployee(ctx *gin.Context) {
	claims := auth.GetClaims(ctx)
	if claims == nil {
		return
	}

	employeeIdString := ctx.Param("id")
	if employeeIdString == "" {
		utils.RespondError(ctx, http.StatusBadRequest, "id was not recieved", "id was not recieved", gin.H{
			"required_data": "id",
		})
		return
	}

	id, err := strconv.Atoi(employeeIdString)
	if err != nil {
		utils.RespondError(ctx, http.StatusBadRequest, "error parse id", "error parse id", nil)
		return
	}

	exists, err := utils.CheckExists(id, h.EmployeeRepository.TableName, claims.Role, h.EmployeeRepository.db)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while exist checking", nil)
		return
	}

	if !exists {
		utils.RespondError(ctx, http.StatusInternalServerError, "employee with such id doesn't eixst", "employee with such id doesn't eixst", nil)
		return
	}

	err = h.EmployeeRepository.Delete(id, claims.Role)
	if err != nil {
		utils.RespondError(ctx, http.StatusInternalServerError, err.Error(), "error while deleting", nil)
		return
	}

	utils.RespondSuccess(ctx, http.StatusOK, "employee successfully deleted", nil)
}

func validateEmployee(employee Employee) error {
	if len(employee.Surname) == 0 || len(employee.Firstname) == 0 || len(employee.Patronymic) == 0 {
		return errors.New("surname, firstname, and patronymic are required")
	}
	if len(employee.Surname) > 50 || len(employee.Firstname) > 50 || len(employee.Patronymic) > 50 {
		return errors.New("fields cannot exceed 50 characters")
	}
	if len(employee.INN) != 12 {
		return errors.New("INN must be 12 characters")
	}
	if len(employee.PhoneNumber) != 16 {
		return errors.New("phone number must be 16 characters")
	}
	return nil
}
