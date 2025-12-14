package report

import (
	"context"
	"warehouse/pkg/database"
)

type ReportRepository struct {
	db *database.Connector
}

func NewReportRepository(db *database.Connector) *ReportRepository {
	return &ReportRepository{
		db: db,
	}
}

func (r *ReportRepository) GetBatches(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_batches")
	if err != nil {
		return nil, err
	}

	var response []ReportBatches
	for rows.Next() {
		var item ReportBatches

		err = rows.Scan(&item.Id, &item.Name, &item.Cost, &item.ProductionDate, &item.ExpirationDate)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetDocumentsByEmployee(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_documents_by_employee")
	if err != nil {
		return nil, err
	}

	var response []ReportDocumentsByEmployee
	for rows.Next() {
		var item ReportDocumentsByEmployee

		err = rows.Scan(&item.EmpoloyeeNumber, &item.Employee, &item.Position, &item.DocumentCategory, &item.Documents)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetEmployees(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_employees")
	if err != nil {
		return nil, err
	}

	var response []ReportEmployees
	for rows.Next() {
		var item ReportEmployees

		err = rows.Scan(&item.Number, &item.Surname, &item.Firstname, &item.Patronymic, &item.Position, &item.PhoneNumber, &item.BirthDate)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetExpiredBatches(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_expired_batches")
	if err != nil {
		return nil, err
	}

	var response []ReportExpiredBatches
	for rows.Next() {
		var item ReportExpiredBatches

		err = rows.Scan(&item.Number, &item.BatchId, &item.ProductName, &item.ExpirationDate, &item.RemainingQuantity)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetGrants(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_grants")
	if err != nil {
		return nil, err
	}

	var response []ReportGrants
	for rows.Next() {
		var item ReportGrants

		err = rows.Scan(&item.Number, &item.Grantee, &item.TableName, &item.Privileges)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetInterfaceGrants(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_interface_grants")
	if err != nil {
		return nil, err
	}

	var response []ReportInterfaceGrants
	for rows.Next() {
		var item ReportInterfaceGrants

		err = rows.Scan(&item.Role, &item.Section, &item.Permissions)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetNoProducts(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_no_products")
	if err != nil {
		return nil, err
	}

	var response []ReportNoProducts
	for rows.Next() {
		var item ReportNoProducts

		err = rows.Scan(&item.Number, &item.Id, &item.ProductName, &item.ProducerName)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetProductsTotalCost(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_products_total_cost")
	if err != nil {
		return nil, err
	}

	var response []ReportProductsTotalSum
	for rows.Next() {
		var item ReportProductsTotalSum

		err = rows.Scan(&item.Number, &item.IdBatch, &item.ProductName, &item.Cost, &item.LeftQuantity, &item.Total)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetProducerSubjectStatistics(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_producer_subject_statistics")
	if err != nil {
		return nil, err
	}

	var response []ReportProducerSubjectStatistics
	for rows.Next() {
		var item ReportProducerSubjectStatistics

		err = rows.Scan(&item.Number, &item.Subject, &item.ProducerQuantity, &item.ProducerName)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetProductLeft(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_products_left")
	if err != nil {
		return nil, err
	}

	var response []ReportProductsLeft
	for rows.Next() {
		var item ReportProductsLeft

		err = rows.Scan(&item.Number, &item.IdProduct, &item.ProductName, &item.ProducerName, &item.LeftQuantity)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetProductLeftByBatch(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_products_left_by_batch")
	if err != nil {
		return nil, err
	}

	var response []ReportProductsLeftByBatch
	for rows.Next() {
		var item ReportProductsLeftByBatch

		err = rows.Scan(&item.Number, &item.IdBacth, &item.IdProduct, &item.ProductName, &item.LeftQuantity)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetNonFixedBatches(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), `SELECT * FROM report_non_fixed_batches`)
	if err != nil {
		return nil, err
	}

	var response []ReportNonFixedBatches
	for rows.Next() {
		var item ReportNonFixedBatches

		err = rows.Scan(&item.Number, &item.IdBatch, &item.IdProduct, &item.ProductName)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetSystemUsers(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_system_users")
	if err != nil {
		return nil, err
	}

	var response []ReportSystemUsers
	for rows.Next() {
		var item ReportSystemUsers

		err = rows.Scan(&item.Number, &item.Role, &item.Surname, &item.Firstname, &item.Patronymic, &item.Position)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetTablesActivityPerHour(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_tables_activity_per_hour")
	if err != nil {
		return nil, err
	}

	var response []ReportTablesActivityPerHour
	for rows.Next() {
		var item ReportTablesActivityPerHour

		err = rows.Scan(&item.Hour, &item.ActionCount, &item.Actors)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}

func (r *ReportRepository) GetTablesActivity(role string) (any, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM report_tables_activity")
	if err != nil {
		return nil, err
	}

	var response []ReportTablesActivity
	for rows.Next() {
		var item ReportTablesActivity

		err = rows.Scan(&item.Number, &item.TableName, &item.Action, &item.Actors, &item.ActionQuantity)
		if err != nil {
			return nil, err
		}

		response = append(response, item)
	}

	return response, nil
}
