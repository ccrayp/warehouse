package document

import (
	"context"
	"warehouse/internal/document/models"
	"warehouse/pkg/database"
)

type DocumentRepository struct {
	db *database.Connector
}

func NewDocumentRepository(db *database.Connector) *DocumentRepository {
	return &DocumentRepository{
		db: db,
	}
}

func (r *DocumentRepository) GetDocumentAll(role string) ([]models.Document, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM document")
	if err != nil {
		return nil, err
	}

	var docuemnts []models.Document
	for rows.Next() {
		var docuemnt models.Document

		err := rows.Scan(&docuemnt.ID, &docuemnt.Date, &docuemnt.IdEmployee, &docuemnt.IdDocumentCategory)
		if err != nil {
			return nil, err
		}

		docuemnts = append(docuemnts, docuemnt)
	}

	return docuemnts, nil
}

func (r *DocumentRepository) GetDocumentPagination(limit, offset int, role string) ([]models.Document, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM document LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}

	var docuemnts []models.Document
	for rows.Next() {
		var docuemnt models.Document

		err := rows.Scan(&docuemnt.ID, &docuemnt.Date, &docuemnt.IdEmployee, &docuemnt.IdDocumentCategory)
		if err != nil {
			return nil, err
		}

		docuemnts = append(docuemnts, docuemnt)
	}

	return docuemnts, nil
}

func (r *DocumentRepository) GetDocumentById(id int, role string) (*models.Document, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var docuement models.Document
	err = pool.QueryRow(context.Background(), "SELECT * FROM document WHERE id=$1", id).Scan(&docuement.ID, &docuement.Date, &docuement.IdEmployee, &docuement.IdDocumentCategory)
	if err != nil {
		return nil, err
	}

	return &docuement, nil
}

func (r *DocumentRepository) CreateDocument(req models.DocumentRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO document (id, date, id_employee, id_document_category) VALUES (DEFAULT, $1, $2, $3) RETURNING id", req.Date, req.IdEmployee, req.IdDocumentCategory).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *DocumentRepository) UpdateDocuemnt(req models.DocumentRequest, id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "UPDATE document SET date=$1, id_employee=$2, id_document_category=$3 WHERE id = $4", req.Date, req.IdEmployee, req.IdDocumentCategory, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *DocumentRepository) DeleteDocument(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM document WHERE id=$1", id)
	if err != nil {
		return err
	}

	return nil
}

func (r *DocumentRepository) GetContentAll(role string) ([]models.Content, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM document_content")
	if err != nil {
		return nil, err
	}

	var contents []models.Content
	for rows.Next() {
		var content models.Content

		err := rows.Scan(&content.Id, &content.IdDocument, &content.IdBatch, &content.Quantity)
		if err != nil {
			return nil, err
		}

		contents = append(contents, content)
	}

	return contents, nil
}

func (r *DocumentRepository) GetContentPagination(limit, offset int, role string) ([]models.Content, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM document_content LIMIT $1 OFFSET $2", limit, offset)
	if err != nil {
		return nil, err
	}

	var contents []models.Content
	for rows.Next() {
		var content models.Content

		err := rows.Scan(&content.Id, &content.IdDocument, &content.IdBatch, &content.Quantity)
		if err != nil {
			return nil, err
		}

		contents = append(contents, content)
	}

	return contents, nil
}

func (r *DocumentRepository) GetContentById(id int, role string) (*models.Content, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var content models.Content
	err = pool.QueryRow(context.Background(), "SELECT * FROM document_content WHERE id=$1", id).Scan(&content.Id, &content.IdDocument, &content.IdBatch, &content.Quantity)
	if err != nil {
		return nil, err
	}

	return &content, nil
}

func (r *DocumentRepository) GetAllContentByDocuemntId(id int, role string) ([]models.Content, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	rows, err := pool.Query(context.Background(), "SELECT * FROM document_content WHERE id_document=$1", id)
	if err != nil {
		return nil, err
	}

	var contents []models.Content
	for rows.Next() {
		var content models.Content

		err := rows.Scan(&content.Id, &content.IdDocument, &content.IdBatch, &content.Quantity)
		if err != nil {
			return nil, err
		}

		contents = append(contents, content)
	}

	return contents, nil
}

func (r *DocumentRepository) CreateContent(req models.ContentRequest, role string) (*int, error) {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return nil, err
	}

	var id int
	err = pool.QueryRow(context.Background(), "INSERT INTO document_content (id, id_document, id_batch, quantity) VALUES (DEFAULT, $1, $2, $3) RETURNING id", req.IdDocument, req.IdBatch, req.Quantity).Scan(&id)
	if err != nil {
		return nil, err
	}

	return &id, nil
}

func (r *DocumentRepository) UpdateContent(req models.ContentRequest, id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "UPDATE document_content SET id_document=$1, id_batch=$2, quantity=$3 WHERE id=$4", req.IdDocument, req.IdBatch, req.Quantity, id)
	if err != nil {
		return err
	}

	return nil
}

func (r *DocumentRepository) DeleteContent(id int, role string) error {
	pool, err := r.db.GetPool(role)
	if err != nil {
		return err
	}

	_, err = pool.Exec(context.Background(), "DELETE FROM document_content WHERE id=$1", id)
	if err != nil {
		return err
	}

	return nil
}
