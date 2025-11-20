# Course project on subject "Databases". 
## Theme of the work is "Developing of the data base for automatisation of storage accounting"
## Description:
```Приложение предназначено для ввода и обработки информации, о приходе и выбытии товара, а также о фактических остатках товара на складе. 
На основе полученных данных должен производиться расчет реализации товара за определенный период. 
Автоматизированная информационная система должна контролировать корректность вводимой информации и осуществлять формирование выходных документов (инвентаризационная ведомость остатков, отчет о реализации товара за период, отчет по приходу товара на склад). 
В связи с инфляцией и уменьшением срока годности товара иногда возникает необходимость произвести переоценку товара, которая оформляется документально (акт списания товара). 
Также, в системе осуществляется формирование карточки с изображением товара и его описанием. 
При входе в систему требуется авторизация пользователей.
```

## Posible queries
```sql
-- список партий, полученных от определенного поставщика;

SELECT b.* 
FROM batch AS b
JOIN product AS pt
	ON pt.id = b.id_product
JOIN producer AS pr
	ON pr.id = pt.id_producer
WHERE pr.name = 'ООО "СтильДрев"';


-- список продуктов, которых нет на складе;

SELECT
	pt.id,
	pt.name,
	pt.id_producer
FROM (
	SELECT id FROM product 
	EXCEPT
	SELECT 
		id_product AS id
	FROM (
		SELECT
			id_product,
			CASE
				WHEN id_document IN (SELECT id FROM document WHERE id_document_category = 2) THEN quantity * -1
				ELSE quantity
			END AS quantity
		FROM document_content
		WHERE id_document NOT IN (SELECT id FROM document WHERE id_document_category = 3)
	)
	GROUP BY id_product
	HAVING SUM(quantity) > 0
) AS l
JOIN product AS pt
	ON pt.id = l.id


-- Количество оставшихся на складе товаров каждого типа

SELECT 
	pt.id,
	pt.name,
	l.product_left
FROM (
	SELECT 
		id_product,
		SUM(quantity) AS product_left
	FROM (
		SELECT
			id_product,
			CASE
				WHEN id_document IN (SELECT id FROM document WHERE id_document_category = 2) THEN quantity * -1
				ELSE quantity
			END AS quantity
		FROM document_content
		WHERE id_document NOT IN (SELECT id FROM document WHERE id_document_category = 3)
	)
	GROUP BY id_product
) AS l
JOIN product AS pt
	ON pt.id = l.id_product


-- список сотрудников, которые могут пользоваться системой;

SELECT 
	e.surname,
	e.firstname,
	e.patronymic,
	ps.name
FROM employee AS e
JOIN sys_user AS su
	ON su.id_employee = e.id
JOIN position AS ps
	ON e.id_position = ps.id


-- список список партий, принятых за определенный период времени;

SELECT b.* FROM batch AS b
JOIN (
	SELECT
		id_batch
	FROM document_content AS dc
	JOIN document AS d
		ON d.id = dc.id_document
	WHERE d.id_document_category = 1 AND (d.date BETWEEN '2024-01-01' AND '2024-07-01')
) AS l
ON l.id_batch = b.id
```
