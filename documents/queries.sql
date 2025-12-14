-- 1. Выборка названий продуктов и их производителей
SELECT
	pt.id,
	pt.name,
	pr.name
FROM product AS pt
JOIN producer AS pr
	ON pt.id_producer = pr.id
ORDER BY pt.name, pr.name

-- 2. Выборка названий производителей их категорияй товаров, которые они производят
SELECT
	pr.id,
	pr.name,
	ARRAY_AGG(DISTINCT pc.name) AS categories
FROM producer AS pr
JOIN product AS pt
	ON pt.id_producer = pr.id
JOIN product_category AS pc
	ON pt.id_product_category = pc.id
GROUP BY pr.id, pr.name

-- 3. Выборка названией категорий продукции и количество производителей, которые их производят
SELECT
	pc.id,
	pc.name,
	COUNT(pc.id) AS producers_quantity
FROM product_category AS pc
JOIN product AS pt
	ON pt.id_product_category = pc.id
JOIN producer AS pr
	ON pt.id_producer = pr.id
GROUP BY pc.id, pc.name
ORDER BY LENGTH(pc.name), pc.name ASC

-- 4. Выборка товаров, в названии которых есть составное словое (через дефис)
SELECT
	id,
	name
FROM product
WHERE name LIKE '%-%'

-- 5. Выборка документов о поступлении и списании за 2025 год
SELECT
	d.id,
	d.date,
	dc.name
FROM document AS d
JOIN document_category AS dc
	ON d.id_document_category = dc.id
WHERE (date BETWEEN '2025-01-01' AND '2025-12-31') AND dc.name IN ('Поступление', 'Списание')

-- 6. Выборка количества оформленных документов по сотрдуникам
SELECT
	ROW_NUMBER() OVER(PARTITION BY e.id),
	e.surname || ' ' || e.firstname || ' ' || e.patronymic AS name,
	dc.name AS document_category,
	COUNT(d.id) AS documents_quantity
FROM document AS d
JOIN employee AS e
	ON e.id = d.id_employee
JOIN document_category AS dc
	ON d.id_document_category = dc.id
GROUP BY e.id, dc.name

-- 7. Выборка товаров, которые были хотя бы раз приняты в партиях
SELECT
	pt.id,
	pt.name,
	pc.name AS product_category
FROM product AS pt
JOIN product_category AS pc
	ON pt.id_product_category = pc.id
WHERE pt.id = ANY(SELECT id_product FROM batch)

-- 8. Выборка товаров, которые никогда не фигурировали в партиях на складе
SELECT
	pt.id,
	pt.name
FROM product AS pt

EXCEPT

SELECT
	pt.id,
	pt.name
FROM batch AS b
JOIN product AS pt
	ON b.id_product = pt.id

-- 9. Вывод сотрудников и их роли в системе
WITH emoloyees_names AS (
	SELECT
		id,
		surname,
		firstname,
		patronymic
	FROM employee
)
SELECT
	en.surname || ' ' || en.firstname || ' ' || en.patronymic AS name,
	COALESCE(su.id::TEXT, '-') AS id_user,
	COALESCE(r.sys_role, '-') AS role
FROM sys_user AS su
RIGHT JOIN emoloyees_names AS en
	ON su.id_employee = en.id
LEFT JOIN role AS r
	ON su.id_role = r.id
ORDER BY r.sys_role

-- 10. Выборка производителей и количества их товаров, которые фигурировали хотя бы раз в партиях
SELECT
    pr.name AS producer_name,
    COUNT(sub.id_product) AS products_in_batches
FROM producer AS pr
JOIN (
    SELECT DISTINCT pt.id AS id_product, pt.id_producer
    FROM product AS pt
    JOIN batch AS b
        ON pt.id = b.id_product
) AS sub
    ON pr.id = sub.id_producer
GROUP BY pr.name
ORDER BY products_in_batches DESC, pr.name;