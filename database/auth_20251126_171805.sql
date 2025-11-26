--
-- PostgreSQL database cluster dump
--

\restrict shx64RiHmscmft8k3aNKLSvzTzLPwwW8yofoc32lJpRXjbUziK4an0trlM4J8gp

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE admin;
ALTER ROLE admin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:ffZA+yYKYXLWTdreqSEuew==$+DqdGprmAvlBNYJSXcy+94EGtZDO8i3McEIhCpw+qGI=:cNdBYaTXFuzm9JwjTZjbSkZEuM8QSklm6BI6DgiduIw=';
CREATE ROLE manager;
ALTER ROLE manager WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:2emf/uenXqfXghon8li9EQ==$ARHHic/ZOx1j8Xl6jMtT55kSJrWishV7ODUUHF/Ne68=:cstoUZ6yZvQa0LW8bUGepdgFm+a9xvZp0U0Vnk75B1E=';
CREATE ROLE moderator;
ALTER ROLE moderator WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:nP45xb7at4j+dqXvFVSEUw==$Yp8T7lLoOb+LueVhJFFS3m/eoCIQ5QblbuCtz/Z+0NE=:Le9YDr8tRJWWOiVsQBvWrhUa15XPx1mfTVncJ9J2iSU=';
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:Lasxw30CxcO8KYWU0WRUPg==$9Wb4RVDiRah6gUm/sCODnWGxw/cR6raEjsxR3rHv2oI=:Aq8oSnGLQXTOISRQ/LqL0sTNONkzHWtD5pZp4Wry1Nw=';

--
-- User Configurations
--








\unrestrict shx64RiHmscmft8k3aNKLSvzTzLPwwW8yofoc32lJpRXjbUziK4an0trlM4J8gp

--
-- PostgreSQL database cluster dump complete
--

--
-- PostgreSQL database dump
--

\restrict Dot0BocMZWthK4X3HYsQx41YivVrgC02SLVYhYOhYLts02EQhTOLh4MkBMFxkOH

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: audit_trigger(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.audit_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log(table_name, action, old_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), current_user);
        RETURN OLD;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log(table_name, action, old_data, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, row_to_json(OLD), row_to_json(NEW), current_user);
        RETURN NEW;

    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log(table_name, action, new_data, changed_by)
        VALUES (TG_TABLE_NAME, TG_OP, row_to_json(NEW), current_user);
        RETURN NEW;

    END IF;
END;
$$;


ALTER FUNCTION public.audit_trigger() OWNER TO postgres;

--
-- Name: createdocument(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.createdocument(v_id_employee integer, v_id_document_category integer) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM employee WHERE id = v_id_employee) THEN
        RETURN generateResponse('error', 'EMP_NOT_FOUND', 'Сотрудник с таким идентификатором не найден');
    ELSIF NOT EXISTS (
        SELECT 1 
        FROM employee e
        JOIN position p ON e.id_position = p.id
        WHERE e.id = v_id_employee AND p.name IN ('Начальник склада', 'Кладовщик')
    ) THEN
        RETURN generateResponse('error', 'NO_PERMISSION', 'Сотрудник не может создавать документы');
	ELSIF NOT EXISTS (
		SELECT 1 FROM document_category WHERE id = v_id_document_category
	) THEN
		RETURN generateResponse('error', 'EMP_NOT_FOUND', 'Категория документа с таким идентификатором не найдена');
    END IF;

    INSERT INTO document VALUES (DEFAULT, current_date, v_id_employee, v_id_document_category);

    RETURN generateResponse('success', 'OK', 'Документ успешно создан');
	
EXCEPTION
	WHEN others THEN RETURN generateResponse('error', 'DB_ERROR', SQLERRM);
END;
$$;


ALTER FUNCTION public.createdocument(v_id_employee integer, v_id_document_category integer) OWNER TO postgres;

--
-- Name: generateresponse(text, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.generateresponse(v_status text, v_code text, v_message text) RETURNS json
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN json_build_object(
		'status', v_status,
        'code', v_code,
        'message', v_message
	);
END;
$$;


ALTER FUNCTION public.generateresponse(v_status text, v_code text, v_message text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: address; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.address (
    id integer NOT NULL,
    subject character varying(100) NOT NULL,
    region character varying(100) NOT NULL,
    city character varying(100) NOT NULL,
    street character varying(100) NOT NULL,
    building integer NOT NULL
);


ALTER TABLE public.address OWNER TO postgres;

--
-- Name: address_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.address_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.address_id_seq OWNER TO postgres;

--
-- Name: address_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.address_id_seq OWNED BY public.address.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    id integer NOT NULL,
    table_name text NOT NULL,
    action text NOT NULL,
    old_data jsonb,
    new_data jsonb,
    changed_by text,
    changed_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_log_id_seq OWNER TO postgres;

--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: batch; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.batch (
    id integer NOT NULL,
    cost real NOT NULL,
    production_date date NOT NULL,
    expiration_date date,
    id_product integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.batch OWNER TO postgres;

--
-- Name: batch_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.batch_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.batch_id_seq OWNER TO postgres;

--
-- Name: batch_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.batch_id_seq OWNED BY public.batch.id;


--
-- Name: product; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    id_product_category integer NOT NULL,
    id_producer integer NOT NULL,
    image_url text DEFAULT 'placeholder.png'::text NOT NULL
);


ALTER TABLE public.product OWNER TO postgres;

--
-- Name: batches; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.batches AS
 SELECT b.id,
    p.name AS "Название продукта",
    b.cost AS "Стоимость за 1 у.е.",
    b.production_date AS "Дата производства",
    b.expiration_date AS "Годен до"
   FROM (public.batch b
     JOIN public.product p ON ((b.id_product = p.id)));


ALTER TABLE public.batches OWNER TO postgres;

--
-- Name: batches_m; Type: MATERIALIZED VIEW; Schema: public; Owner: postgres
--

CREATE MATERIALIZED VIEW public.batches_m AS
 SELECT b.id,
    p.name AS "Название продукта",
    b.cost AS "Стоимость за 1 у.е.",
    b.production_date AS "Дата производства",
    b.expiration_date AS "Годен до"
   FROM (public.batch b
     JOIN public.product p ON ((b.id_product = p.id)))
  WITH NO DATA;


ALTER TABLE public.batches_m OWNER TO postgres;

--
-- Name: document; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document (
    id integer NOT NULL,
    date date NOT NULL,
    id_employee integer NOT NULL,
    id_document_category integer NOT NULL
);


ALTER TABLE public.document OWNER TO postgres;

--
-- Name: document_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_category (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text NOT NULL
);


ALTER TABLE public.document_category OWNER TO postgres;

--
-- Name: document_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.document_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.document_category_id_seq OWNER TO postgres;

--
-- Name: document_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.document_category_id_seq OWNED BY public.document_category.id;


--
-- Name: document_content; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.document_content (
    id integer NOT NULL,
    id_document integer NOT NULL,
    id_batch integer NOT NULL,
    id_product integer NOT NULL,
    quantity integer NOT NULL
);


ALTER TABLE public.document_content OWNER TO postgres;

--
-- Name: document_content_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.document_content_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.document_content_id_seq OWNER TO postgres;

--
-- Name: document_content_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.document_content_id_seq OWNED BY public.document_content.id;


--
-- Name: document_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.document_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.document_id_seq OWNER TO postgres;

--
-- Name: document_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.document_id_seq OWNED BY public.document.id;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee (
    id integer NOT NULL,
    surname character varying(50) NOT NULL,
    firstname character varying(50) NOT NULL,
    patronymic character varying(50) NOT NULL,
    id_gender integer NOT NULL,
    inn character varying(12) NOT NULL,
    phone_number character varying(16) NOT NULL,
    id_address integer NOT NULL,
    birth_date date NOT NULL,
    id_position integer NOT NULL
);


ALTER TABLE public.employee OWNER TO postgres;

--
-- Name: employee_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employee_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_id_seq OWNER TO postgres;

--
-- Name: employee_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employee_id_seq OWNED BY public.employee.id;


--
-- Name: employees; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.employees AS
 SELECT employee.surname AS "Фамилия",
    employee.firstname AS "Имя",
    employee.patronymic AS "Отчество",
    employee.phone_number AS "Номер телефона",
    employee.birth_date AS "Дата рождения"
   FROM public.employee;


ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: gender; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gender (
    id integer NOT NULL,
    sign character varying(1) NOT NULL
);


ALTER TABLE public.gender OWNER TO postgres;

--
-- Name: gender_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gender_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gender_id_seq OWNER TO postgres;

--
-- Name: gender_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gender_id_seq OWNED BY public.gender.id;


--
-- Name: producer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producer (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    id_address integer NOT NULL,
    inn character varying(10) NOT NULL,
    surname character varying(50) NOT NULL,
    firstname character varying(50) NOT NULL,
    patronymic character varying(50) NOT NULL
);


ALTER TABLE public.producer OWNER TO postgres;

--
-- Name: no_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.no_products AS
 SELECT pt.id,
    pt.name AS "Название товара",
    pr.name AS "Название производителя"
   FROM ((( SELECT product.id
           FROM public.product
        EXCEPT
         SELECT b.id_product AS id
           FROM (( SELECT document_content.id_batch,
                        CASE
                            WHEN (document_content.id_document IN ( SELECT document.id
                               FROM public.document
                              WHERE (document.id_document_category = 2))) THEN (document_content.quantity * '-1'::integer)
                            ELSE document_content.quantity
                        END AS quantity
                   FROM public.document_content
                  WHERE (NOT (document_content.id_document IN ( SELECT document.id
                           FROM public.document
                          WHERE (document.id_document_category = 3))))) t
             JOIN public.batch b ON ((b.id = t.id_batch)))
          GROUP BY b.id_product
         HAVING (sum(t.quantity) > 0)) l
     JOIN public.product pt ON ((pt.id = l.id)))
     JOIN public.producer pr ON ((pr.id = pt.id_producer)));


ALTER TABLE public.no_products OWNER TO postgres;

--
-- Name: position; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."position" (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text NOT NULL
);


ALTER TABLE public."position" OWNER TO postgres;

--
-- Name: position_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.position_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.position_id_seq OWNER TO postgres;

--
-- Name: position_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.position_id_seq OWNED BY public."position".id;


--
-- Name: producer_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.producer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.producer_id_seq OWNER TO postgres;

--
-- Name: producer_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.producer_id_seq OWNED BY public.producer.id;


--
-- Name: product_category; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.product_category (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.product_category OWNER TO postgres;

--
-- Name: product_category_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_category_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_category_id_seq OWNER TO postgres;

--
-- Name: product_category_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_category_id_seq OWNED BY public.product_category.id;


--
-- Name: product_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.product_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_id_seq OWNER TO postgres;

--
-- Name: product_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.product_id_seq OWNED BY public.product.id;


--
-- Name: products_left; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.products_left AS
 SELECT pt.id,
    pt.name AS "Название товара",
    pr.name AS "Название производителя",
    COALESCE(l.product_left, (0)::bigint) AS "Остатки на складе"
   FROM ((( SELECT b.id_product,
            sum(t.quantity) AS product_left
           FROM (( SELECT document_content.id_batch,
                        CASE
                            WHEN (document_content.id_document IN ( SELECT document.id
                               FROM public.document
                              WHERE (document.id_document_category = 2))) THEN (document_content.quantity * '-1'::integer)
                            ELSE document_content.quantity
                        END AS quantity
                   FROM public.document_content
                  WHERE (NOT (document_content.id_document IN ( SELECT document.id
                           FROM public.document
                          WHERE (document.id_document_category = 3))))) t
             JOIN public.batch b ON ((b.id = t.id_batch)))
          GROUP BY b.id_product) l
     RIGHT JOIN public.product pt ON ((pt.id = l.id_product)))
     JOIN public.producer pr ON ((pr.id = pt.id_producer)));


ALTER TABLE public.products_left OWNER TO postgres;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refresh_tokens (
    id integer NOT NULL,
    token text NOT NULL,
    username text NOT NULL,
    role text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.refresh_tokens OWNER TO postgres;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.refresh_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.refresh_tokens_id_seq OWNER TO postgres;

--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.refresh_tokens_id_seq OWNED BY public.refresh_tokens.id;


--
-- Name: role; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.role (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    description text NOT NULL,
    sys_role character varying(50) NOT NULL
);


ALTER TABLE public.role OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_id_seq OWNER TO postgres;

--
-- Name: role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.role_id_seq OWNED BY public.role.id;


--
-- Name: sys_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sys_user (
    id integer NOT NULL,
    login character varying(50) NOT NULL,
    password_hash character(60) NOT NULL,
    id_role integer NOT NULL,
    id_employee integer NOT NULL
);


ALTER TABLE public.sys_user OWNER TO postgres;

--
-- Name: sys_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sys_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sys_user_id_seq OWNER TO postgres;

--
-- Name: sys_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sys_user_id_seq OWNED BY public.sys_user.id;


--
-- Name: system_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.system_users AS
 SELECT e.surname AS "Фамилия",
    e.firstname AS "Имя",
    e.patronymic AS "Отчество",
    ps.name AS "Должность",
    r.sys_role AS "Роль в системе"
   FROM (((public.employee e
     JOIN public.sys_user su ON ((su.id_employee = e.id)))
     JOIN public."position" ps ON ((e.id_position = ps.id)))
     JOIN public.role r ON ((su.id_role = r.id)))
  ORDER BY r.sys_role;


ALTER TABLE public.system_users OWNER TO postgres;

--
-- Name: address id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address ALTER COLUMN id SET DEFAULT nextval('public.address_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: batch id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch ALTER COLUMN id SET DEFAULT nextval('public.batch_id_seq'::regclass);


--
-- Name: document id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document ALTER COLUMN id SET DEFAULT nextval('public.document_id_seq'::regclass);


--
-- Name: document_category id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_category ALTER COLUMN id SET DEFAULT nextval('public.document_category_id_seq'::regclass);


--
-- Name: document_content id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content ALTER COLUMN id SET DEFAULT nextval('public.document_content_id_seq'::regclass);


--
-- Name: employee id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee ALTER COLUMN id SET DEFAULT nextval('public.employee_id_seq'::regclass);


--
-- Name: gender id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gender ALTER COLUMN id SET DEFAULT nextval('public.gender_id_seq'::regclass);


--
-- Name: position id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."position" ALTER COLUMN id SET DEFAULT nextval('public.position_id_seq'::regclass);


--
-- Name: producer id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producer ALTER COLUMN id SET DEFAULT nextval('public.producer_id_seq'::regclass);


--
-- Name: product id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product ALTER COLUMN id SET DEFAULT nextval('public.product_id_seq'::regclass);


--
-- Name: product_category id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_category ALTER COLUMN id SET DEFAULT nextval('public.product_category_id_seq'::regclass);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('public.refresh_tokens_id_seq'::regclass);


--
-- Name: role id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role ALTER COLUMN id SET DEFAULT nextval('public.role_id_seq'::regclass);


--
-- Name: sys_user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user ALTER COLUMN id SET DEFAULT nextval('public.sys_user_id_seq'::regclass);


--
-- Data for Name: address; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.address (id, subject, region, city, street, building) FROM stdin;
1	Новгородская область	Новгородский	Великий Новгород	Большая Санкт-Петербургская	25
2	Новгородская область	Новгородский	Великий Новгород	Людогоща	14
3	Новгородская область	Новгородский	Великий Новгород	Федоровский ручей	2
4	Новгородская область	Новгородский	Великий Новгород	Богдана Хмельницкого	42
5	Новгородская область	Новгородский	Великий Новгород	Великая	8
6	Приморский край	Ленинский	Владивосток	Светлановская	115
7	Республика Татарстан	Вахитовский	Казань	Баумана	44
8	Красноярский край	Советский	Красноярск	Мира	123
9	Москва	Текстильщики	Москва	Остаповский проезд	6
13	Нижегородская область	Буревестник	Нижний Новгород	Народная	1
15	Не указано	Не указано	Не указано	Не указано	0
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, table_name, action, old_data, new_data, changed_by, changed_at) FROM stdin;
2	producer	UPDATE	{"id": 3, "inn": "8901234567", "name": "ООО \\"МикроТех\\"", "surname": "Белов", "firstname": "Дмитрий", "id_address": 8, "patronymic": "Игоревич"}	{"id": 3, "inn": "8901234567", "name": "ООО \\"МикроТех\\"", "surname": "Белочкин", "firstname": "Дмитрий", "id_address": 8, "patronymic": "Игоревич"}	postgres	2025-11-23 09:01:25.747191
3	refresh_tokens	INSERT	\N	{"id": 5, "role": "admin", "token": "cba4fd00c94d24c294c03e229c32c26a883f21d7b64090e1b4e8c84b7fea8d77", "username": "roman", "created_at": "2025-11-26T13:44:34.193637"}	admin	2025-11-26 13:44:34.193637
4	refresh_tokens	INSERT	\N	{"id": 6, "role": "admin", "token": "331f7d0e39b7208afda01cc0de9c9eee633ba0b8ab4e593ea5290ca95d978007", "username": "roman", "created_at": "2025-11-26T13:53:17.617212"}	admin	2025-11-26 13:53:17.617212
5	refresh_tokens	INSERT	\N	{"id": 7, "role": "admin", "token": "94b73e8c98bd3c09f277f15c0bc6b5d25bc139c87dc067cf3e1061a39b76c68a", "username": "roman", "created_at": "2025-11-26T13:53:20.513858"}	admin	2025-11-26 13:53:20.513858
6	refresh_tokens	INSERT	\N	{"id": 8, "role": "admin", "token": "49daff6915a3f11892764200b755529cf7a0e3835acce53083d255d6c0ec3229", "username": "roman", "created_at": "2025-11-26T13:53:21.423941"}	admin	2025-11-26 13:53:21.423941
7	sys_user	UPDATE	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2b$12$A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0U1V2W3X4Y5Z6 "}	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$rgYYBEQoDW9f3dxPAgweruahkWXVL/EaX85oJaTY.SxpLHVhrRWsC"}	postgres	2025-11-26 14:10:46.647639
8	sys_user	UPDATE	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2b$12$L8Q9zR6nS2tV1WxY3Z4A7uB8C9D0E1F2G3H4I5J6K7L8M9N0O1P2Q"}	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$FVCCd92Vbpubj1004.Df8eVP4LVbyttxm1wXserInQnEbHcE5oFLm"}	postgres	2025-11-26 14:10:46.647639
9	refresh_tokens	INSERT	\N	{"id": 9, "role": "admin", "token": "943f03ab3a4f25a87cc71e5816dc1cadb987c215fb5ac55def363a9ee92bacbc", "username": "artem_volkov", "created_at": "2025-11-26T14:13:11.123677"}	admin	2025-11-26 14:13:11.123677
10	refresh_tokens	INSERT	\N	{"id": 10, "role": "admin", "token": "97c6bfd5e9067a095070646cebe2751d3b3a7ada884fa670f0e55146a89a1d62", "username": "artem_volkov", "created_at": "2025-11-26T14:13:39.912611"}	admin	2025-11-26 14:13:39.912611
11	refresh_tokens	DELETE	{"id": 10, "role": "admin", "token": "97c6bfd5e9067a095070646cebe2751d3b3a7ada884fa670f0e55146a89a1d62", "username": "artem_volkov", "created_at": "2025-11-26T14:13:39.912611"}	\N	admin	2025-11-26 14:14:54.969474
\.


--
-- Data for Name: batch; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.batch (id, cost, production_date, expiration_date, id_product, created_at) FROM stdin;
1	125500	2024-01-15	2034-01-15	1	2025-10-15 08:39:40.31846
2	48800	2025-02-01	2027-02-01	2	2025-10-15 08:39:40.31846
3	18900	2025-02-20	2029-02-20	3	2025-10-15 08:39:40.31846
5	89990	2025-03-05	2028-03-05	2	2025-10-15 08:39:40.31846
4	24300	2024-01-20	2034-02-20	1	2025-10-15 08:39:40.31846
\.


--
-- Data for Name: document; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document (id, date, id_employee, id_document_category) FROM stdin;
1	2024-03-10	2	1
2	2024-03-18	2	2
3	2024-03-25	2	3
4	2025-11-22	1	1
5	2025-11-22	1	1
6	2025-11-22	1	3
\.


--
-- Data for Name: document_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_category (id, name, description) FROM stdin;
1	Поступление	Фиксация поступления разных партии товаров различных категорий
2	Списание	Фиксация выбытия определённого количества товаров различных категорий из разных партий
3	Переоценка	Фиксация изменение стоимости 1 у. е. продукции определённой категории в определённой партии
\.


--
-- Data for Name: document_content; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.document_content (id, id_document, id_batch, id_product, quantity) FROM stdin;
1	1	1	1	5
2	1	2	2	3
3	1	3	3	10
4	1	4	4	15
5	1	5	5	2
6	2	1	1	4
7	2	4	4	3
9	3	3	3	2
10	3	4	4	1
11	3	5	5	1
8	2	5	5	2
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee (id, surname, firstname, patronymic, id_gender, inn, phone_number, id_address, birth_date, id_position) FROM stdin;
2	Соколова	Анна	Сергеевна	2	525209876543	+7 911 987-65-43	2	1992-08-23	2
3	Павлов	Иван	Олегович	1	525205678901	+7 911 456-78-90	3	1988-11-08	3
4	Орлов	Денис	Романович	1	525203456789	+7 911 234-56-78	4	1995-02-17	3
5	Никитин	Петр	Алексеевич	1	525201987654	+7 911 765-43-21	5	1983-07-30	3
1	Волчков	Артем	Дмитриевич	1	525201234567	+7 911 123-45-67	1	1985-05-12	1
\.


--
-- Data for Name: gender; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.gender (id, sign) FROM stdin;
1	М
2	Ж
3	-
\.


--
-- Data for Name: position; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."position" (id, name, description) FROM stdin;
1	Начальник склада	Общее управление, планирование и отчётность
2	Кладовщик	Приёмка и отгрузка, учёт и сохранность
3	Грузчик	Комплектация заказов, помощь при приёмке
4	Не указано	Не указано
6	тест	тест
\.


--
-- Data for Name: producer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.producer (id, name, id_address, inn, surname, firstname, patronymic) FROM stdin;
1	ООО "СтильДрев"	6	2547890123	Громов	Алексей	Викторович
2	АО "БытМашПром"	7	6634517890	Захарова	Ольга	Николаевич
3	ООО "МикроТех"	8	8901234567	Белочкин	Дмитрий	Игоревич
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (id, name, id_product_category, id_producer, image_url) FROM stdin;
1	Кухонный гарнитур "Уют"	1	1	placeholder.png
2	Стиральная машина "SM-5000"	2	2	placeholder.png
3	Материнская плата "Gamer XTREME"	3	3	placeholder.png
4	Офисное кресло "Director"	1	1	placeholder.png
5	Холодильник "Frost+ 300"	2	2	placeholder.png
\.


--
-- Data for Name: product_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_category (id, name) FROM stdin;
1	Мебель
2	Электроника
3	Бытовая техника
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, token, username, role, created_at) FROM stdin;
1	813c16031039ae8b4284501b980c8aada2a1a1bdce4070b7ed71f56c719b62a9	roman	admin	2025-11-26 13:41:27.891585
5	cba4fd00c94d24c294c03e229c32c26a883f21d7b64090e1b4e8c84b7fea8d77	roman	admin	2025-11-26 13:44:34.193637
6	331f7d0e39b7208afda01cc0de9c9eee633ba0b8ab4e593ea5290ca95d978007	roman	admin	2025-11-26 13:53:17.617212
7	94b73e8c98bd3c09f277f15c0bc6b5d25bc139c87dc067cf3e1061a39b76c68a	roman	admin	2025-11-26 13:53:20.513858
8	49daff6915a3f11892764200b755529cf7a0e3835acce53083d255d6c0ec3229	roman	admin	2025-11-26 13:53:21.423941
9	943f03ab3a4f25a87cc71e5816dc1cadb987c215fb5ac55def363a9ee92bacbc	artem_volkov	admin	2025-11-26 14:13:11.123677
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.role (id, name, description, sys_role) FROM stdin;
1	Модератор	Модерирование базы данных, выполнение CRUD операций	moderator
2	Менеджер	Пользование БД, использование готовых запросов	manager
4	Администратор	Администрирование база данные, полный доступ ко всем объектам	admin
\.


--
-- Data for Name: sys_user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sys_user (id, login, password_hash, id_role, id_employee) FROM stdin;
2	anna_sokolova	$2a$10$rgYYBEQoDW9f3dxPAgweruahkWXVL/EaX85oJaTY.SxpLHVhrRWsC	2	2
1	artem_volkov	$2a$10$FVCCd92Vbpubj1004.Df8eVP4LVbyttxm1wXserInQnEbHcE5oFLm	4	1
\.


--
-- Name: address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.address_id_seq', 15, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 11, true);


--
-- Name: batch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.batch_id_seq', 7, true);


--
-- Name: document_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_category_id_seq', 3, true);


--
-- Name: document_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_content_id_seq', 11, true);


--
-- Name: document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_id_seq', 6, true);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_id_seq', 7, true);


--
-- Name: gender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gender_id_seq', 3, true);


--
-- Name: position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_id_seq', 6, true);


--
-- Name: producer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producer_id_seq', 3, true);


--
-- Name: product_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_category_id_seq', 3, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 5, true);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refresh_tokens_id_seq', 10, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 4, true);


--
-- Name: sys_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sys_user_id_seq', 2, true);


--
-- Name: address address_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.address
    ADD CONSTRAINT address_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: batch batch_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch
    ADD CONSTRAINT batch_pkey PRIMARY KEY (id);


--
-- Name: document_category document_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_category
    ADD CONSTRAINT document_category_pkey PRIMARY KEY (id);


--
-- Name: document_content document_content_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content
    ADD CONSTRAINT document_content_pkey PRIMARY KEY (id);


--
-- Name: document document_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);


--
-- Name: employee employee_inn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_inn_key UNIQUE (inn);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (id);


--
-- Name: gender gender_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gender
    ADD CONSTRAINT gender_pkey PRIMARY KEY (id);


--
-- Name: position position_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."position"
    ADD CONSTRAINT position_pkey PRIMARY KEY (id);


--
-- Name: producer producer_inn_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producer
    ADD CONSTRAINT producer_inn_key UNIQUE (inn);


--
-- Name: producer producer_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producer
    ADD CONSTRAINT producer_pkey PRIMARY KEY (id);


--
-- Name: product_category product_category_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_category
    ADD CONSTRAINT product_category_name_key UNIQUE (name);


--
-- Name: product_category product_category_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product_category
    ADD CONSTRAINT product_category_pkey PRIMARY KEY (id);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_key UNIQUE (token);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (id);


--
-- Name: sys_user sys_user_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_login_key UNIQUE (login);


--
-- Name: sys_user sys_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_pkey PRIMARY KEY (id);


--
-- Name: idx_batch_id_product; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_batch_id_product ON public.batch USING btree (id_product);


--
-- Name: batches batches_delete; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE batches_delete AS
    ON DELETE TO public.batches DO INSTEAD  DELETE FROM public.batch
  WHERE (batch.id = old.id);


--
-- Name: batches batches_insert; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE batches_insert AS
    ON INSERT TO public.batches DO INSTEAD  INSERT INTO public.batch (id_product, cost, production_date, expiration_date)
  VALUES (( SELECT product.id
           FROM public.product
          WHERE ((product.name)::text = (new."Название продукта")::text)), new."Стоимость за 1 у.е.", new."Дата производства", new."Годен до");


--
-- Name: batches batches_update; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE batches_update AS
    ON UPDATE TO public.batches DO INSTEAD  UPDATE public.batch SET cost = new."Стоимость за 1 у.е.", production_date = new."Дата производства", expiration_date = new."Годен до"
  WHERE (batch.id = old.id);


--
-- Name: employees employees_insert; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE employees_insert AS
    ON INSERT TO public.employees DO INSTEAD  INSERT INTO public.employee (surname, firstname, patronymic, phone_number, birth_date, id_gender, id_address, id_position, inn)
  VALUES (new."Фамилия", new."Имя", new."Отчество", new."Номер телефона", new."Дата рождения", 3, 15, 4, '000000000000'::character varying);


--
-- Name: employees employees_update; Type: RULE; Schema: public; Owner: postgres
--

CREATE RULE employees_update AS
    ON UPDATE TO public.employees DO INSTEAD  UPDATE public.employee SET surname = new."Фамилия", firstname = new."Имя", patronymic = new."Отчество", phone_number = new."Номер телефона", birth_date = new."Дата рождения"
  WHERE (((employee.surname)::text = (old."Фамилия")::text) AND ((employee.firstname)::text = (old."Имя")::text));


--
-- Name: address audit_address; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_address AFTER INSERT OR DELETE OR UPDATE ON public.address FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: batch audit_batch; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_batch AFTER INSERT OR DELETE OR UPDATE ON public.batch FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: document audit_document; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_document AFTER INSERT OR DELETE OR UPDATE ON public.document FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: document_category audit_document_category; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_document_category AFTER INSERT OR DELETE OR UPDATE ON public.document_category FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: document_content audit_document_content; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_document_content AFTER INSERT OR DELETE OR UPDATE ON public.document_content FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: employee audit_employee; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_employee AFTER INSERT OR DELETE OR UPDATE ON public.employee FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: gender audit_gender; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_gender AFTER INSERT OR DELETE OR UPDATE ON public.gender FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: position audit_position; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_position AFTER INSERT OR DELETE OR UPDATE ON public."position" FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: producer audit_producer; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_producer AFTER INSERT OR DELETE OR UPDATE ON public.producer FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: product audit_product; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_product AFTER INSERT OR DELETE OR UPDATE ON public.product FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: product_category audit_product_category; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_product_category AFTER INSERT OR DELETE OR UPDATE ON public.product_category FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: refresh_tokens audit_refresh_tokens; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_refresh_tokens AFTER INSERT OR DELETE OR UPDATE ON public.refresh_tokens FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: role audit_role; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_role AFTER INSERT OR DELETE OR UPDATE ON public.role FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: sys_user audit_sys_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER audit_sys_user AFTER INSERT OR DELETE OR UPDATE ON public.sys_user FOR EACH ROW EXECUTE FUNCTION public.audit_trigger();


--
-- Name: batch batch_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch
    ADD CONSTRAINT batch_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.product(id);


--
-- Name: document_content document_content_id_batch_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content
    ADD CONSTRAINT document_content_id_batch_fkey FOREIGN KEY (id_batch) REFERENCES public.batch(id);


--
-- Name: document_content document_content_id_document_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content
    ADD CONSTRAINT document_content_id_document_fkey FOREIGN KEY (id_document) REFERENCES public.document(id);


--
-- Name: document_content document_content_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content
    ADD CONSTRAINT document_content_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.product(id);


--
-- Name: document document_id_document_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_category_fkey FOREIGN KEY (id_document_category) REFERENCES public.document_category(id);


--
-- Name: document document_id_employee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id);


--
-- Name: employee employee_id_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_id_address_fkey FOREIGN KEY (id_address) REFERENCES public.address(id);


--
-- Name: employee employee_id_gender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_id_gender_fkey FOREIGN KEY (id_gender) REFERENCES public.gender(id);


--
-- Name: employee employee_id_position_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_id_position_fkey FOREIGN KEY (id_position) REFERENCES public."position"(id);


--
-- Name: producer producer_id_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producer
    ADD CONSTRAINT producer_id_address_fkey FOREIGN KEY (id_address) REFERENCES public.address(id);


--
-- Name: product product_id_producer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_id_producer_fkey FOREIGN KEY (id_producer) REFERENCES public.producer(id);


--
-- Name: product product_id_product_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_id_product_category_fkey FOREIGN KEY (id_product_category) REFERENCES public.product_category(id);


--
-- Name: sys_user sys_user_id_employee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id);


--
-- Name: sys_user sys_user_id_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.role(id);


--
-- Name: FUNCTION generateresponse(v_status text, v_code text, v_message text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.generateresponse(v_status text, v_code text, v_message text) TO admin;


--
-- Name: TABLE address; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.address TO admin;
GRANT SELECT,UPDATE ON TABLE public.address TO moderator;
GRANT SELECT ON TABLE public.address TO manager;


--
-- Name: SEQUENCE address_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.address_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.address_id_seq TO moderator;
GRANT SELECT,USAGE ON SEQUENCE public.address_id_seq TO manager;


--
-- Name: TABLE audit_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT ON TABLE public.audit_log TO admin;
GRANT INSERT ON TABLE public.audit_log TO moderator;
GRANT INSERT ON TABLE public.audit_log TO manager;


--
-- Name: SEQUENCE audit_log_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.audit_log_id_seq TO admin;
GRANT ALL ON SEQUENCE public.audit_log_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.audit_log_id_seq TO manager;


--
-- Name: TABLE batch; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.batch TO admin;
GRANT SELECT,UPDATE ON TABLE public.batch TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.batch TO manager;


--
-- Name: SEQUENCE batch_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.batch_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.batch_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.batch_id_seq TO manager;


--
-- Name: TABLE product; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.product TO admin;
GRANT SELECT,UPDATE ON TABLE public.product TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.product TO manager;


--
-- Name: TABLE batches; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.batches TO manager;
GRANT SELECT ON TABLE public.batches TO moderator;


--
-- Name: TABLE document; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.document TO admin;
GRANT SELECT,UPDATE ON TABLE public.document TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.document TO manager;


--
-- Name: TABLE document_category; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.document_category TO admin;
GRANT SELECT,UPDATE ON TABLE public.document_category TO moderator;


--
-- Name: SEQUENCE document_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.document_category_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.document_category_id_seq TO moderator;


--
-- Name: TABLE document_content; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.document_content TO admin;
GRANT SELECT,UPDATE ON TABLE public.document_content TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.document_content TO manager;


--
-- Name: SEQUENCE document_content_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.document_content_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.document_content_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.document_content_id_seq TO manager;


--
-- Name: SEQUENCE document_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.document_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.document_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.document_id_seq TO manager;


--
-- Name: TABLE employee; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.employee TO admin;
GRANT SELECT,UPDATE ON TABLE public.employee TO moderator;
GRANT SELECT ON TABLE public.employee TO manager;


--
-- Name: SEQUENCE employee_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.employee_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.employee_id_seq TO moderator;
GRANT SELECT,USAGE ON SEQUENCE public.employee_id_seq TO manager;


--
-- Name: TABLE employees; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.employees TO admin;
GRANT SELECT ON TABLE public.employees TO moderator;
GRANT SELECT ON TABLE public.employees TO manager;


--
-- Name: TABLE gender; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.gender TO admin;
GRANT SELECT ON TABLE public.gender TO moderator;
GRANT SELECT ON TABLE public.gender TO manager;


--
-- Name: TABLE producer; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.producer TO admin;
GRANT SELECT ON TABLE public.producer TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.producer TO manager;


--
-- Name: TABLE no_products; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.no_products TO manager;
GRANT SELECT ON TABLE public.no_products TO admin;
GRANT SELECT ON TABLE public.no_products TO moderator;


--
-- Name: TABLE "position"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public."position" TO admin;
GRANT SELECT ON TABLE public."position" TO moderator;
GRANT SELECT ON TABLE public."position" TO manager;


--
-- Name: SEQUENCE position_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.position_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.position_id_seq TO moderator;
GRANT SELECT,USAGE ON SEQUENCE public.position_id_seq TO manager;


--
-- Name: SEQUENCE producer_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.producer_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.producer_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.producer_id_seq TO manager;


--
-- Name: TABLE product_category; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.product_category TO admin;
GRANT SELECT ON TABLE public.product_category TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.product_category TO manager;


--
-- Name: SEQUENCE product_category_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.product_category_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.product_category_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.product_category_id_seq TO manager;


--
-- Name: SEQUENCE product_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.product_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.product_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.product_id_seq TO manager;


--
-- Name: TABLE products_left; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.products_left TO admin;
GRANT SELECT ON TABLE public.products_left TO moderator;
GRANT SELECT ON TABLE public.products_left TO manager;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE ON TABLE public.refresh_tokens TO admin;
GRANT SELECT,INSERT,DELETE ON TABLE public.refresh_tokens TO moderator;
GRANT SELECT,INSERT,DELETE ON TABLE public.refresh_tokens TO manager;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO admin;
GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO manager;


--
-- Name: TABLE role; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.role TO admin;


--
-- Name: TABLE sys_user; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sys_user TO admin;


--
-- Name: SEQUENCE sys_user_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sys_user_id_seq TO admin;


--
-- Name: TABLE system_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.system_users TO admin;


--
-- Name: batches_m; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.batches_m;


--
-- PostgreSQL database dump complete
--

\unrestrict Dot0BocMZWthK4X3HYsQx41YivVrgC02SLVYhYOhYLts02EQhTOLh4MkBMFxkOH

