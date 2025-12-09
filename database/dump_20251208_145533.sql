--
-- PostgreSQL database cluster dump
--

\restrict PZtHHYybKdDNG9mM0T95ZB4gdgHDifBMW6t1IqxsMZp6DvjP54aE6qw2dLNTO7Q

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE admin;
ALTER ROLE admin WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:ffZA+yYKYXLWTdreqSEuew==$+DqdGprmAvlBNYJSXcy+94EGtZDO8i3McEIhCpw+qGI=:cNdBYaTXFuzm9JwjTZjbSkZEuM8QSklm6BI6DgiduIw=';
CREATE ROLE manager;
ALTER ROLE manager WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:2emf/uenXqfXghon8li9EQ==$ARHHic/ZOx1j8Xl6jMtT55kSJrWishV7ODUUHF/Ne68=:cstoUZ6yZvQa0LW8bUGepdgFm+a9xvZp0U0Vnk75B1E=';
CREATE ROLE moderator;
ALTER ROLE moderator WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:nP45xb7at4j+dqXvFVSEUw==$Yp8T7lLoOb+LueVhJFFS3m/eoCIQ5QblbuCtz/Z+0NE=:Le9YDr8tRJWWOiVsQBvWrhUa15XPx1mfTVncJ9J2iSU=';
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:Lasxw30CxcO8KYWU0WRUPg==$9Wb4RVDiRah6gUm/sCODnWGxw/cR6raEjsxR3rHv2oI=:Aq8oSnGLQXTOISRQ/LqL0sTNONkzHWtD5pZp4Wry1Nw=';

--
-- User Configurations
--








\unrestrict PZtHHYybKdDNG9mM0T95ZB4gdgHDifBMW6t1IqxsMZp6DvjP54aE6qw2dLNTO7Q

--
-- PostgreSQL database cluster dump complete
--

--
-- PostgreSQL database dump
--

\restrict ZKXIJGzZNn39MWRkeXwLAT2cpSqnqqn8INyhkPDW3CdChYcF3Ud5EJKi7EFd0zR

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
-- Name: gender; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gender (
    id integer NOT NULL,
    sign character(1) NOT NULL
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
-- Name: producer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.producer (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    id_address integer NOT NULL,
    inn character(10) NOT NULL,
    surname character varying(50) NOT NULL,
    firstname character varying(50) NOT NULL,
    patronymic character varying(50) NOT NULL
);


ALTER TABLE public.producer OWNER TO postgres;

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
-- Name: report_batches; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_batches AS
 SELECT b.id,
    p.name,
    b.cost,
    b.production_date,
    b.expiration_date
   FROM (public.batch b
     JOIN public.product p ON ((b.id_product = p.id)));


ALTER TABLE public.report_batches OWNER TO postgres;

--
-- Name: report_documents_by_employee; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_documents_by_employee AS
 SELECT dense_rank() OVER (ORDER BY e.surname, e.firstname, e.patronymic) AS employee_number,
    (((((e.surname)::text || ' '::text) || (e.firstname)::text) || ' '::text) || (e.patronymic)::text) AS employee,
    p.name AS "position",
    dc.name AS document_category,
    t.count AS documents
   FROM (((public.employee e
     JOIN ( SELECT e_1.id AS employee_id,
            d.id_document_category,
            count(*) AS count
           FROM (public.document d
             JOIN public.employee e_1 ON ((d.id_employee = e_1.id)))
          GROUP BY e_1.id, d.id_document_category) t ON ((e.id = t.employee_id)))
     JOIN public."position" p ON ((p.id = e.id_position)))
     JOIN public.document_category dc ON ((t.id_document_category = dc.id)))
  ORDER BY (((((e.surname)::text || ' '::text) || (e.firstname)::text) || ' '::text) || (e.patronymic)::text);


ALTER TABLE public.report_documents_by_employee OWNER TO postgres;

--
-- Name: report_employees; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_employees AS
 SELECT row_number() OVER () AS number,
    t.surname,
    t.firstname,
    t.patronymic,
    t.name AS "position",
    t.phone_number,
    t.birth_date
   FROM ( SELECT e.surname,
            e.firstname,
            e.patronymic,
            e.phone_number,
            e.birth_date,
            p.name
           FROM (public.employee e
             JOIN public."position" p ON ((e.id_position = p.id)))
          ORDER BY e.surname, e.firstname, e.patronymic) t;


ALTER TABLE public.report_employees OWNER TO postgres;

--
-- Name: report_expired_batches; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_expired_batches AS
 SELECT row_number() OVER () AS number,
    b.id AS batch_id,
    p.name AS product_name,
    b.expiration_date,
    COALESCE(sum(
        CASE
            WHEN (d.id_document_category = 1) THEN dc.quantity
            WHEN (d.id_document_category = 2) THEN (- dc.quantity)
            ELSE NULL::integer
        END), (0)::bigint) AS remaining_quantity
   FROM (((public.batch b
     JOIN public.product p ON ((b.id_product = p.id)))
     LEFT JOIN public.document_content dc ON ((dc.id_batch = b.id)))
     LEFT JOIN public.document d ON ((d.id = dc.id_document)))
  WHERE (b.expiration_date <= CURRENT_DATE)
  GROUP BY b.id, b.expiration_date, p.name
 HAVING (COALESCE(sum(
        CASE
            WHEN (d.id_document_category = 1) THEN dc.quantity
            WHEN (d.id_document_category = 2) THEN (- dc.quantity)
            ELSE NULL::integer
        END), (0)::bigint) > 0)
  ORDER BY b.expiration_date;


ALTER TABLE public.report_expired_batches OWNER TO postgres;

--
-- Name: report_grants; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_grants AS
 SELECT row_number() OVER () AS number,
    t.grantee,
    t.table_name,
    t.privileges
   FROM ( SELECT role_table_grants.grantee,
            role_table_grants.table_name,
            string_agg((role_table_grants.privilege_type)::text, ', '::text) AS privileges
           FROM information_schema.role_table_grants
          WHERE ((role_table_grants.grantee)::name = ANY (ARRAY['admin'::name, 'moderator'::name, 'manager'::name]))
          GROUP BY role_table_grants.grantee, role_table_grants.table_name
          ORDER BY role_table_grants.grantee, role_table_grants.table_name) t;


ALTER TABLE public.report_grants OWNER TO postgres;

--
-- Name: report_no_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_no_products AS
 SELECT row_number() OVER () AS number,
    pt.id,
    pt.name AS product_name,
    pr.name AS producer_name
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


ALTER TABLE public.report_no_products OWNER TO postgres;

--
-- Name: report_producer_subject_statistics; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_producer_subject_statistics AS
 SELECT row_number() OVER () AS number,
    a.subject,
    count(*) AS producer_quantity,
    string_agg((pr.name)::text, ', '::text) AS producer_name
   FROM (public.producer pr
     JOIN public.address a ON ((a.id = pr.id_address)))
  GROUP BY a.subject;


ALTER TABLE public.report_producer_subject_statistics OWNER TO postgres;

--
-- Name: report_products_left; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_products_left AS
 SELECT row_number() OVER () AS number,
    pt.id AS id_product,
    pt.name AS product_name,
    pr.name AS producer_name,
    COALESCE(l.product_left, (0)::bigint) AS left_quantity
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
          GROUP BY b.id_product
          ORDER BY (sum(t.quantity)) DESC) l
     RIGHT JOIN public.product pt ON ((pt.id = l.id_product)))
     JOIN public.producer pr ON ((pr.id = pt.id_producer)));


ALTER TABLE public.report_products_left OWNER TO postgres;

--
-- Name: report_products_left_by_batch; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_products_left_by_batch AS
 SELECT row_number() OVER () AS number,
    t.id_batch,
    t.id_product,
    t.product_name,
    t.left_quantity
   FROM ( SELECT b.id AS id_batch,
            p.id AS id_product,
            p.name AS product_name,
            COALESCE(t_1.left_quantity, (0)::bigint) AS left_quantity
           FROM ((public.batch b
             JOIN public.product p ON ((b.id_product = p.id)))
             LEFT JOIN ( SELECT dc.id_batch,
                    sum(
                        CASE
                            WHEN (d.id_document_category = 2) THEN (- dc.quantity)
                            ELSE dc.quantity
                        END) AS left_quantity
                   FROM (public.document_content dc
                     JOIN public.document d ON ((d.id = dc.id_document)))
                  GROUP BY dc.id_batch) t_1 ON ((t_1.id_batch = b.id)))
          ORDER BY COALESCE(t_1.left_quantity, (0)::bigint) DESC) t;


ALTER TABLE public.report_products_left_by_batch OWNER TO postgres;

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
-- Name: report_system_users; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_system_users AS
 SELECT row_number() OVER () AS number,
    t.role,
    t.surname,
    t.firstname,
    t.patronymic,
    t."position"
   FROM ( SELECT r.sys_role AS role,
            e.surname,
            e.firstname,
            e.patronymic,
            ps.name AS "position"
           FROM (((public.employee e
             JOIN public.sys_user su ON ((su.id_employee = e.id)))
             JOIN public."position" ps ON ((e.id_position = ps.id)))
             JOIN public.role r ON ((su.id_role = r.id)))
          ORDER BY r.sys_role) t;


ALTER TABLE public.report_system_users OWNER TO postgres;

--
-- Name: report_tables_activity; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_tables_activity AS
 SELECT row_number() OVER () AS number,
    t.table_name,
    t.action,
    t.actors,
    t.action_quantity
   FROM ( SELECT audit_log.table_name,
            audit_log.action,
            string_agg(DISTINCT audit_log.changed_by, ', '::text ORDER BY audit_log.changed_by) AS actors,
            count(*) AS action_quantity
           FROM public.audit_log
          WHERE ((audit_log.table_name <> 'refresh_tokens'::text) AND (audit_log.changed_at >= (CURRENT_DATE - '7 days'::interval)))
          GROUP BY audit_log.table_name, audit_log.action
          ORDER BY audit_log.table_name) t;


ALTER TABLE public.report_tables_activity OWNER TO postgres;

--
-- Name: report_tables_activity_per_hour; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_tables_activity_per_hour AS
 SELECT EXTRACT(hour FROM audit_log.changed_at) AS hour,
    count(*) AS action_count,
    string_agg(DISTINCT audit_log.changed_by, ', '::text ORDER BY audit_log.changed_by) AS actors
   FROM public.audit_log
  WHERE ((audit_log.table_name <> 'refresh_tokens'::text) AND (audit_log.changed_at >= (now() - '1 mon'::interval)))
  GROUP BY (EXTRACT(hour FROM audit_log.changed_at))
  ORDER BY (EXTRACT(hour FROM audit_log.changed_at));


ALTER TABLE public.report_tables_activity_per_hour OWNER TO postgres;

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
12	refresh_tokens	INSERT	\N	{"id": 11, "role": "admin", "token": "1cbe2f88d2f2ae7f9f9830c50708a987b72746beb26f69714c481d4b68b2a63c", "username": "artem_volkov", "created_at": "2025-11-26T14:19:15.076778"}	admin	2025-11-26 14:19:15.076778
13	refresh_tokens	INSERT	\N	{"id": 12, "role": "admin", "token": "4128f11f7639650ab58e66dc2de8c697259df3a0fff99ffefb1be1a135f82492", "username": "artem_volkov", "created_at": "2025-11-26T14:55:31.582029"}	admin	2025-11-26 14:55:31.582029
14	refresh_tokens	INSERT	\N	{"id": 13, "role": "admin", "token": "ca2cf4331fb90f0dba3b72d21b2619f4c94e05806e17cc725f32d31db19b9639", "username": "artem_volkov", "created_at": "2025-11-26T15:00:45.651163"}	admin	2025-11-26 15:00:45.651163
15	refresh_tokens	INSERT	\N	{"id": 14, "role": "admin", "token": "e69760612a8e12fc6b4c594aa6c91d43f360c7f741c3dc8d47a2b1f0d15d8012", "username": "artem_volkov", "created_at": "2025-11-27T06:29:01.211081"}	admin	2025-11-27 06:29:01.211081
16	sys_user	INSERT	\N	{"id": 4, "login": "manager", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	postgres	2025-11-27 06:41:25.719506
17	sys_user	INSERT	\N	{"id": 5, "login": "moderator", "id_role": 2, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	postgres	2025-11-27 06:41:25.719506
18	sys_user	UPDATE	{"id": 5, "login": "moderator", "id_role": 2, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	{"id": 5, "login": "moderator", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	postgres	2025-11-27 06:41:43.393199
19	refresh_tokens	INSERT	\N	{"id": 15, "role": "manager", "token": "a64ab6b5588249005d97f3620ffa83f3b6e2bf03e19463a0e5bffb667533caee", "username": "manager", "created_at": "2025-11-27T06:55:11.668623"}	manager	2025-11-27 06:55:11.668623
20	refresh_tokens	INSERT	\N	{"id": 16, "role": "admin", "token": "938f447ec5bcc121a17ef5df648da8e40e4806bdae73462c2579e066e8d442a2", "username": "artem_volkov", "created_at": "2025-11-27T06:56:30.238745"}	admin	2025-11-27 06:56:30.238745
21	refresh_tokens	INSERT	\N	{"id": 17, "role": "admin", "token": "10c6f457d5a4eea17421afbb0ba546956096905abded10a241a1330e31f1bf7a", "username": "artem_volkov", "created_at": "2025-11-27T07:09:46.021445"}	admin	2025-11-27 07:09:46.021445
22	refresh_tokens	INSERT	\N	{"id": 18, "role": "manager", "token": "25d631c35949d6aea6bda090c8ba45265658fe0c16e37f0247e95e23c3f66776", "username": "manager", "created_at": "2025-11-27T07:12:43.617149"}	manager	2025-11-27 07:12:43.617149
23	refresh_tokens	INSERT	\N	{"id": 19, "role": "manager", "token": "d369e960e74a00713ba90203a693fb21b2dda030689c52e1f698337c44a0980c", "username": "manager", "created_at": "2025-11-27T07:12:46.164956"}	manager	2025-11-27 07:12:46.164956
24	refresh_tokens	INSERT	\N	{"id": 20, "role": "manager", "token": "5e6ba8e70891f90d174244ec3b80300f862a88a1116ccc2bfcdf19d4f73284e8", "username": "manager", "created_at": "2025-11-27T12:46:28.835829"}	manager	2025-11-27 12:46:28.835829
25	refresh_tokens	DELETE	{"id": 20, "role": "manager", "token": "5e6ba8e70891f90d174244ec3b80300f862a88a1116ccc2bfcdf19d4f73284e8", "username": "manager", "created_at": "2025-11-27T12:46:28.835829"}	\N	admin	2025-11-27 14:41:24.553096
26	refresh_tokens	INSERT	\N	{"id": 21, "role": "admin", "token": "c4047bf1b6a35318377d1d62e8c017eae155bef3a323ba8b3749df0c8f6e1d4e", "username": "manager", "created_at": "2025-11-27T14:42:41.252856"}	admin	2025-11-27 14:42:41.252856
27	employee	INSERT	\N	{"id": 8, "inn": "111111111111", "surname": "test", "firstname": "test", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test", "id_position": 1, "phone_number": "1111111111111111"}	postgres	2025-11-27 15:27:41.815369
28	sys_user	INSERT	\N	{"id": 6, "login": "admin", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	postgres	2025-11-27 15:37:02.562526
225	document_category	DELETE	{"id": 4, "name": "test2", "description": "test1"}	\N	admin	2025-12-08 10:30:59.11395
29	refresh_tokens	INSERT	\N	{"id": 22, "role": "admin", "token": "a439faab054f288efe9c5355a01d02d21d61615c60a760b5aa0a7817e3de8413", "username": "admin", "created_at": "2025-11-27T15:37:15.190072"}	admin	2025-11-27 15:37:15.190072
30	employee	DELETE	{"id": 8, "inn": "111111111111", "surname": "test", "firstname": "test", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test", "id_position": 1, "phone_number": "1111111111111111"}	\N	admin	2025-11-27 15:37:29.955842
31	employee	INSERT	\N	{"id": 9, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-27 16:11:16.739013
32	employee	DELETE	{"id": 9, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	\N	admin	2025-11-27 16:11:29.296145
33	refresh_tokens	INSERT	\N	{"id": 23, "role": "admin", "token": "a64188161c526a29d54cf5007846a90dd8dd9567e8fed04aaa2a2a46dfb26ba8", "username": "admin", "created_at": "2025-11-28T08:31:54.748409"}	admin	2025-11-28 08:31:54.748409
34	refresh_tokens	INSERT	\N	{"id": 24, "role": "admin", "token": "4641efb53de98e5bb5a3c97adb117e1336bd4b8ed70e5178d649132074425e5a", "username": "manager", "created_at": "2025-11-28T08:32:56.011581"}	admin	2025-11-28 08:32:56.011581
35	refresh_tokens	INSERT	\N	{"id": 25, "role": "admin", "token": "9185d5b6e4de2a57af618f62cf5f5cde1719477e46834a4794941620275fe6ee", "username": "admin", "created_at": "2025-11-28T09:23:53.178776"}	admin	2025-11-28 09:23:53.178776
36	employee	INSERT	\N	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 09:25:01.630915
37	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 09:28:41.22616
38	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 09:32:47.599062
39	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 09:33:46.830059
40	refresh_tokens	DELETE	{"id": 25, "role": "admin", "token": "9185d5b6e4de2a57af618f62cf5f5cde1719477e46834a4794941620275fe6ee", "username": "admin", "created_at": "2025-11-28T09:23:53.178776"}	\N	admin	2025-11-28 11:56:11.112342
41	refresh_tokens	INSERT	\N	{"id": 26, "role": "admin", "token": "c93bd7b4e8e4f62db2eb2435e4e3ad002f45038ac88d01afb8e110d3065a186a", "username": "admin", "created_at": "2025-11-30T07:12:15.150566"}	admin	2025-11-30 07:12:15.150566
42	refresh_tokens	DELETE	{"id": 26, "role": "admin", "token": "c93bd7b4e8e4f62db2eb2435e4e3ad002f45038ac88d01afb8e110d3065a186a", "username": "admin", "created_at": "2025-11-30T07:12:15.150566"}	\N	admin	2025-11-30 07:12:48.338728
43	refresh_tokens	INSERT	\N	{"id": 27, "role": "admin", "token": "00633a60c1c4944e9f0d4fa9c1d42bab3dc4285613dfe830d2ca69ef64b2b4b1", "username": "manager", "created_at": "2025-11-30T07:32:39.664678"}	admin	2025-11-30 07:32:39.664678
44	refresh_tokens	INSERT	\N	{"id": 28, "role": "admin", "token": "05910c7f2a0f650e7dc2d80ba4d7466d45678aa6e33ee453585057d99df4816b", "username": "manager", "created_at": "2025-11-30T07:44:25.200399"}	admin	2025-11-30 07:44:25.200399
45	refresh_tokens	INSERT	\N	{"id": 29, "role": "admin", "token": "4944a01c570ddec78e028f48feb8c643e7f92a8f0813589b327a15ef091cd3a7", "username": "manager", "created_at": "2025-11-30T08:28:43.838285"}	admin	2025-11-30 08:28:43.838285
46	refresh_tokens	DELETE	{"id": 29, "role": "admin", "token": "4944a01c570ddec78e028f48feb8c643e7f92a8f0813589b327a15ef091cd3a7", "username": "manager", "created_at": "2025-11-30T08:28:43.838285"}	\N	admin	2025-11-30 08:29:08.314482
47	refresh_tokens	INSERT	\N	{"id": 30, "role": "admin", "token": "bdbe5123c0c8105880407442d94f5fbc00fe05e5d312bf5686d3d08024f74177", "username": "manager", "created_at": "2025-11-30T08:29:08.316015"}	admin	2025-11-30 08:29:08.316015
48	refresh_tokens	INSERT	\N	{"id": 31, "role": "admin", "token": "c1ac4cc5bb8c027547a5283e87b77b0063fa9c98a530ab0dbb975155b412a826", "username": "admin", "created_at": "2025-11-30T08:29:21.472275"}	admin	2025-11-30 08:29:21.472275
49	refresh_tokens	DELETE	{"id": 31, "role": "admin", "token": "c1ac4cc5bb8c027547a5283e87b77b0063fa9c98a530ab0dbb975155b412a826", "username": "admin", "created_at": "2025-11-30T08:29:21.472275"}	\N	admin	2025-11-30 08:29:34.610208
50	refresh_tokens	INSERT	\N	{"id": 32, "role": "admin", "token": "e5269021174b218ab7dfc0c09d02446c7e085ef7fbddcf31bf7cc79a15ed6adb", "username": "admin", "created_at": "2025-11-30T08:29:34.611839"}	admin	2025-11-30 08:29:34.611839
51	refresh_tokens	INSERT	\N	{"id": 33, "role": "admin", "token": "81b2147712dcf76a6e615617874b617c0ab35ba65e7847b58843a041e5ff2b24", "username": "admin", "created_at": "2025-11-30T08:29:50.245921"}	admin	2025-11-30 08:29:50.245921
52	refresh_tokens	DELETE	{"id": 33, "role": "admin", "token": "81b2147712dcf76a6e615617874b617c0ab35ba65e7847b58843a041e5ff2b24", "username": "admin", "created_at": "2025-11-30T08:29:50.245921"}	\N	admin	2025-11-30 08:29:55.69218
53	refresh_tokens	INSERT	\N	{"id": 34, "role": "admin", "token": "76fb8be14f37a849518a794e50331f186c0223a77ecf23066d607b95761ccfe8", "username": "admin", "created_at": "2025-11-30T08:29:55.693487"}	admin	2025-11-30 08:29:55.693487
54	refresh_tokens	DELETE	{"id": 34, "role": "admin", "token": "76fb8be14f37a849518a794e50331f186c0223a77ecf23066d607b95761ccfe8", "username": "admin", "created_at": "2025-11-30T08:29:55.693487"}	\N	admin	2025-11-30 08:30:00.359268
55	refresh_tokens	INSERT	\N	{"id": 35, "role": "admin", "token": "5f080e2de4dfc45315af118571437281d9e155efb1a07923011e07c3fc02ff26", "username": "admin", "created_at": "2025-11-30T08:30:00.360945"}	admin	2025-11-30 08:30:00.360945
56	refresh_tokens	INSERT	\N	{"id": 36, "role": "admin", "token": "40f18e21f80e0537f54f0f6b7c21453d1df6f51bc597c4ec7140857c2ed5dae8", "username": "admin", "created_at": "2025-11-30T08:50:22.033023"}	admin	2025-11-30 08:50:22.033023
57	refresh_tokens	INSERT	\N	{"id": 37, "role": "admin", "token": "761e8ed6d58798c8f328573452961a1f237c1386ad6b9c810bc6d5dd9e3c45e1", "username": "manager", "created_at": "2025-11-30T08:50:52.604475"}	admin	2025-11-30 08:50:52.604475
58	refresh_tokens	DELETE	{"id": 36, "role": "admin", "token": "40f18e21f80e0537f54f0f6b7c21453d1df6f51bc597c4ec7140857c2ed5dae8", "username": "admin", "created_at": "2025-11-30T08:50:22.033023"}	\N	admin	2025-11-30 08:51:03.929454
59	refresh_tokens	INSERT	\N	{"id": 38, "role": "admin", "token": "52982be6dd3ff06f3b20aeb25ba5585f5364ee839a8d7a65dfe35f4a87083b49", "username": "admin", "created_at": "2025-11-30T08:51:03.931101"}	admin	2025-11-30 08:51:03.931101
60	refresh_tokens	DELETE	{"id": 37, "role": "admin", "token": "761e8ed6d58798c8f328573452961a1f237c1386ad6b9c810bc6d5dd9e3c45e1", "username": "manager", "created_at": "2025-11-30T08:50:52.604475"}	\N	admin	2025-11-30 08:51:10.605204
61	refresh_tokens	INSERT	\N	{"id": 39, "role": "admin", "token": "b0117da6b1b3be3dfd34e85852271cb9e48a79ccaa3b779bc020325c3437d1e8", "username": "manager", "created_at": "2025-11-30T08:51:10.606166"}	admin	2025-11-30 08:51:10.606166
62	refresh_tokens	INSERT	\N	{"id": 40, "role": "admin", "token": "17392d5f05da99a1c7f973738897a00c0cbdd79f877746176b9a65ac0abb702a", "username": "manager", "created_at": "2025-11-30T08:54:05.622474"}	admin	2025-11-30 08:54:05.622474
63	refresh_tokens	INSERT	\N	{"id": 41, "role": "admin", "token": "bd7032dfb7551d2712450e286d67f600cb561c58eccf00569a811e8664b0a23e", "username": "manager", "created_at": "2025-11-30T08:59:00.768525"}	admin	2025-11-30 08:59:00.768525
64	sys_user	UPDATE	{"id": 4, "login": "manager", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	{"id": 4, "login": "manager_login", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	postgres	2025-11-30 09:00:28.861994
65	sys_user	UPDATE	{"id": 5, "login": "moderator", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	{"id": 5, "login": "moderator_login", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	postgres	2025-11-30 09:00:28.861994
66	sys_user	UPDATE	{"id": 6, "login": "admin", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	{"id": 6, "login": "admin_login", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	postgres	2025-11-30 09:00:28.861994
67	refresh_tokens	INSERT	\N	{"id": 42, "role": "admin", "token": "7334f5e8a5206659e8bd9328af820fa885253a120e4a956724e0270921301d27", "username": "manager_login", "created_at": "2025-11-30T09:00:36.376971"}	admin	2025-11-30 09:00:36.376971
68	refresh_tokens	INSERT	\N	{"id": 43, "role": "manager", "token": "0e5d2ab8cd62d5bbdcc1c1c328592a282f3ed355e5ea0396c46183a971ba3d16", "username": "manager_login", "created_at": "2025-11-30T09:09:32.18135"}	admin	2025-11-30 09:09:32.18135
69	refresh_tokens	DELETE	{"id": 43, "role": "manager", "token": "0e5d2ab8cd62d5bbdcc1c1c328592a282f3ed355e5ea0396c46183a971ba3d16", "username": "manager_login", "created_at": "2025-11-30T09:09:32.18135"}	\N	admin	2025-11-30 09:09:53.258969
70	refresh_tokens	INSERT	\N	{"id": 44, "role": "manager", "token": "92227fe161a5dc011fe1525f513967eb7e4aca999423755e64ffdc57094c55cd", "username": "manager_login", "created_at": "2025-11-30T09:09:53.260424"}	admin	2025-11-30 09:09:53.260424
71	refresh_tokens	INSERT	\N	{"id": 45, "role": "manager", "token": "c1c1be46efb6a4a3fa21b8f3672a6c98c11e339c613240224c572620c817534b", "username": "manager_login", "created_at": "2025-11-30T09:11:04.226608"}	admin	2025-11-30 09:11:04.226608
72	refresh_tokens	DELETE	{"id": 45, "role": "manager", "token": "c1c1be46efb6a4a3fa21b8f3672a6c98c11e339c613240224c572620c817534b", "username": "manager_login", "created_at": "2025-11-30T09:11:04.226608"}	\N	admin	2025-11-30 09:11:19.489622
73	refresh_tokens	INSERT	\N	{"id": 46, "role": "manager", "token": "1386634e8bec9a32fb40ffd6fb22d4bd4786b2ea4da80c83d70dbe2ff5ed7cb9", "username": "manager_login", "created_at": "2025-11-30T09:11:19.491277"}	admin	2025-11-30 09:11:19.491277
74	refresh_tokens	INSERT	\N	{"id": 47, "role": "admin", "token": "05a78610e67b4982f84e54d1820eee7e7519820be5a952eac2eaf418ac446630", "username": "admin_login", "created_at": "2025-11-30T09:12:47.870291"}	admin	2025-11-30 09:12:47.870291
75	refresh_tokens	DELETE	{"id": 47, "role": "admin", "token": "05a78610e67b4982f84e54d1820eee7e7519820be5a952eac2eaf418ac446630", "username": "admin_login", "created_at": "2025-11-30T09:12:47.870291"}	\N	admin	2025-11-30 09:12:55.607542
76	refresh_tokens	INSERT	\N	{"id": 48, "role": "admin", "token": "2bf9eb0b8ed71a7ec7ef9c14eda3fb01bcb75a360850cd28b74edef015b19da4", "username": "admin_login", "created_at": "2025-11-30T09:12:55.60894"}	admin	2025-11-30 09:12:55.60894
77	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test2", "firstname": "test2", "id_gender": 1, "birth_date": "2025-01-01", "id_address": 1, "patronymic": "test2", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-30 09:52:13.449175
78	refresh_tokens	DELETE	{"id": 46, "role": "manager", "token": "1386634e8bec9a32fb40ffd6fb22d4bd4786b2ea4da80c83d70dbe2ff5ed7cb9", "username": "manager_login", "created_at": "2025-11-30T09:11:19.491277"}	\N	admin	2025-11-30 10:14:31.80156
79	refresh_tokens	INSERT	\N	{"id": 49, "role": "manager", "token": "0ca9e2bb281bf54d371f929c5fde835b16f19e004694ab6b5ba36c7eafaebc3a", "username": "manager_login", "created_at": "2025-11-30T10:14:31.808879"}	admin	2025-11-30 10:14:31.808879
80	refresh_tokens	DELETE	{"id": 48, "role": "admin", "token": "2bf9eb0b8ed71a7ec7ef9c14eda3fb01bcb75a360850cd28b74edef015b19da4", "username": "admin_login", "created_at": "2025-11-30T09:12:55.60894"}	\N	admin	2025-11-30 10:17:10.982628
81	refresh_tokens	INSERT	\N	{"id": 50, "role": "admin", "token": "e0db01645df5afb701c0510f905218f930c18c04b4e73902eddcfbf974695d95", "username": "admin_login", "created_at": "2025-11-30T10:17:10.988637"}	admin	2025-11-30 10:17:10.988637
82	employee	INSERT	\N	{"id": 11, "inn": "222222222222", "surname": "a", "firstname": "a", "id_gender": 1, "birth_date": "0001-01-01", "id_address": 1, "patronymic": "a", "id_position": 1, "phone_number": "2222222222222222"}	admin	2025-11-30 10:17:35.035909
83	refresh_tokens	DELETE	{"id": 49, "role": "manager", "token": "0ca9e2bb281bf54d371f929c5fde835b16f19e004694ab6b5ba36c7eafaebc3a", "username": "manager_login", "created_at": "2025-11-30T10:14:31.808879"}	\N	admin	2025-11-30 10:53:00.543844
84	refresh_tokens	INSERT	\N	{"id": 51, "role": "manager", "token": "999efdf14db436045f5ea7b3db3ed280bba96529d03cdc215851bf200bf19ae1", "username": "manager_login", "created_at": "2025-11-30T10:53:00.554936"}	admin	2025-11-30 10:53:00.554936
85	refresh_tokens	DELETE	{"id": 51, "role": "manager", "token": "999efdf14db436045f5ea7b3db3ed280bba96529d03cdc215851bf200bf19ae1", "username": "manager_login", "created_at": "2025-11-30T10:53:00.554936"}	\N	admin	2025-11-30 12:22:42.514068
86	refresh_tokens	INSERT	\N	{"id": 52, "role": "manager", "token": "a7023d162a807bd39e0a90f0a43325a4750b0aecb9c91b49bd4fc8aaf68728bd", "username": "manager_login", "created_at": "2025-11-30T12:22:42.518898"}	admin	2025-11-30 12:22:42.518898
87	refresh_tokens	DELETE	{"id": 50, "role": "admin", "token": "e0db01645df5afb701c0510f905218f930c18c04b4e73902eddcfbf974695d95", "username": "admin_login", "created_at": "2025-11-30T10:17:10.988637"}	\N	admin	2025-11-30 12:22:49.495698
88	refresh_tokens	INSERT	\N	{"id": 53, "role": "admin", "token": "99a9fa7fed06cbfe236377fe27d65480720596cdbc696a0f23526b2026de2a31", "username": "admin_login", "created_at": "2025-11-30T12:22:49.496807"}	admin	2025-11-30 12:22:49.496807
89	refresh_tokens	DELETE	{"id": 53, "role": "admin", "token": "99a9fa7fed06cbfe236377fe27d65480720596cdbc696a0f23526b2026de2a31", "username": "admin_login", "created_at": "2025-11-30T12:22:49.496807"}	\N	admin	2025-11-30 13:28:02.642445
90	refresh_tokens	INSERT	\N	{"id": 54, "role": "admin", "token": "0ba0631536e9d23048183e6997fc134ee1d0bb72d71e61839082719e908987e4", "username": "admin_login", "created_at": "2025-11-30T13:28:02.648157"}	admin	2025-11-30 13:28:02.648157
91	refresh_tokens	DELETE	{"id": 52, "role": "manager", "token": "a7023d162a807bd39e0a90f0a43325a4750b0aecb9c91b49bd4fc8aaf68728bd", "username": "manager_login", "created_at": "2025-11-30T12:22:42.518898"}	\N	admin	2025-11-30 13:30:38.49293
92	refresh_tokens	INSERT	\N	{"id": 55, "role": "manager", "token": "dc8a9108bc26c647475fef62c219badb9d99dee14dce0e19280f033eced13cbd", "username": "manager_login", "created_at": "2025-11-30T13:30:38.501962"}	admin	2025-11-30 13:30:38.501962
93	batch	INSERT	\N	{"id": 8, "cost": 1, "created_at": "2025-11-30T14:27:02.406452", "id_product": 1, "expiration_date": "2025-11-30", "production_date": "2025-11-30"}	postgres	2025-11-30 14:27:02.406452
94	batch	UPDATE	{"id": 8, "cost": 1, "created_at": "2025-11-30T14:27:02.406452", "id_product": 1, "expiration_date": "2025-11-30", "production_date": "2025-11-30"}	{"id": 8, "cost": 2, "created_at": "2025-11-30T14:27:02.406452", "id_product": 1, "expiration_date": "2026-01-30", "production_date": "2025-10-30"}	postgres	2025-11-30 14:28:03.059234
95	batch	INSERT	\N	{"id": 9, "cost": 2, "created_at": "2025-11-30T14:28:46.581513", "id_product": 3, "expiration_date": "2025-12-30", "production_date": "2025-01-30"}	postgres	2025-11-30 14:28:46.581513
96	refresh_tokens	DELETE	{"id": 54, "role": "admin", "token": "0ba0631536e9d23048183e6997fc134ee1d0bb72d71e61839082719e908987e4", "username": "admin_login", "created_at": "2025-11-30T13:28:02.648157"}	\N	admin	2025-11-30 15:21:30.045022
97	refresh_tokens	INSERT	\N	{"id": 56, "role": "admin", "token": "271ee7e19922baa281276e15b39752405e7dea3b50df417a5c73288e3bdaae7c", "username": "admin_login", "created_at": "2025-11-30T15:21:30.050496"}	admin	2025-11-30 15:21:30.050496
98	batch	INSERT	\N	{"id": 10, "cost": 0, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-11-30", "production_date": "2025-11-29"}	admin	2025-11-30 15:25:23.003956
99	batch	UPDATE	{"id": 10, "cost": 0, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-11-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 15:33:52.860007
100	batch	UPDATE	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 15:34:26.726005
101	batch	UPDATE	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 15:35:04.669851
102	batch	UPDATE	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 10, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 15:35:21.497039
103	refresh_tokens	DELETE	{"id": 55, "role": "manager", "token": "dc8a9108bc26c647475fef62c219badb9d99dee14dce0e19280f033eced13cbd", "username": "manager_login", "created_at": "2025-11-30T13:30:38.501962"}	\N	admin	2025-11-30 16:43:14.956824
104	refresh_tokens	INSERT	\N	{"id": 57, "role": "manager", "token": "755f8c6b5d0b56badc69d2935a7e4f36def3dd84cddd5d2cafda1d34347385b9", "username": "manager_login", "created_at": "2025-11-30T16:43:14.962878"}	admin	2025-11-30 16:43:14.962878
105	refresh_tokens	INSERT	\N	{"id": 58, "role": "admin", "token": "1432d41450719516046bdd01c92fa06cd1d169c8790f023bf140f254cea812e1", "username": "admin_login", "created_at": "2025-12-01T06:06:31.197576"}	admin	2025-12-01 06:06:31.197576
106	refresh_tokens	DELETE	{"id": 58, "role": "admin", "token": "1432d41450719516046bdd01c92fa06cd1d169c8790f023bf140f254cea812e1", "username": "admin_login", "created_at": "2025-12-01T06:06:31.197576"}	\N	admin	2025-12-01 06:06:39.550254
107	refresh_tokens	INSERT	\N	{"id": 59, "role": "admin", "token": "211f8f489af394bc0e59d5d3e468bd64e6f00c4a5856556542ec87d45cb43f09", "username": "admin_login", "created_at": "2025-12-01T06:06:39.552779"}	admin	2025-12-01 06:06:39.552779
108	refresh_tokens	INSERT	\N	{"id": 60, "role": "manager", "token": "868852c8be49faa90ce107fc870fc4814895d8df77a4671723eeb69c902f4113", "username": "manager_login", "created_at": "2025-12-01T06:06:49.834222"}	admin	2025-12-01 06:06:49.834222
109	refresh_tokens	DELETE	{"id": 60, "role": "manager", "token": "868852c8be49faa90ce107fc870fc4814895d8df77a4671723eeb69c902f4113", "username": "manager_login", "created_at": "2025-12-01T06:06:49.834222"}	\N	admin	2025-12-01 06:06:58.816987
110	refresh_tokens	INSERT	\N	{"id": 61, "role": "manager", "token": "113415de5b947858e7bdcf797306349a9de999f368c0241232e5ee7848ce4bef", "username": "manager_login", "created_at": "2025-12-01T06:06:58.81918"}	admin	2025-12-01 06:06:58.81918
111	employee	INSERT	\N	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 6, "phone_number": "1111111111111111"}	postgres	2025-12-05 09:25:30.011977
112	sys_user	INSERT	\N	{"id": 7, "login": "valentin_admin", "id_role": 4, "id_employee": 14, "password_hash": "$2a$10$20LdgaOXwKGG9jQAJXDkMeIjzJo4jn5pMcr/Forby.IdMLDA9vuCK"}	postgres	2025-12-05 09:28:09.382849
113	refresh_tokens	INSERT	\N	{"id": 62, "role": "admin", "token": "88a6d1d348d14aef39c595b470446caf2a3e1579ca0c366f08bd776c3037da5b", "username": "valentin_admin", "created_at": "2025-12-05T09:28:35.024116"}	admin	2025-12-05 09:28:35.024116
114	refresh_tokens	INSERT	\N	{"id": 63, "role": "admin", "token": "d165cd4d7c9f627fe7fd2f7d99e642229e438b9ca9f713a331351e58a04fdef3", "username": "valentin_admin", "created_at": "2025-12-06T07:09:31.652981"}	admin	2025-12-06 07:09:31.652981
115	refresh_tokens	DELETE	{"id": 63, "role": "admin", "token": "d165cd4d7c9f627fe7fd2f7d99e642229e438b9ca9f713a331351e58a04fdef3", "username": "valentin_admin", "created_at": "2025-12-06T07:09:31.652981"}	\N	admin	2025-12-06 07:21:53.016154
116	refresh_tokens	INSERT	\N	{"id": 64, "role": "admin", "token": "08b3e5282f76f7fa9a7e960c15fe7d6b92dd4ee4e3ba41fd4fd0233d68dd7e4f", "username": "valentin_admin", "created_at": "2025-12-06T07:21:53.020384"}	admin	2025-12-06 07:21:53.020384
117	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "placeholder.png", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765007844082536256_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 07:57:24.084569
118	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765007844082536256_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008034406405720_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 08:00:34.408334
119	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008034406405720_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008060255653468_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 08:01:00.259002
120	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008060255653468_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008556902235503_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 08:09:16.903558
121	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008556902235503_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008573472322094_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 08:09:33.475365
122	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008573472322094_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008652953227464_p6.jpg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 08:10:52.953432
123	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008652953227464_p6.jpg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008872100895552_7179111216.jpg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 08:14:32.10403
124	refresh_tokens	DELETE	{"id": 64, "role": "admin", "token": "08b3e5282f76f7fa9a7e960c15fe7d6b92dd4ee4e3ba41fd4fd0233d68dd7e4f", "username": "valentin_admin", "created_at": "2025-12-06T07:21:53.020384"}	\N	admin	2025-12-06 08:17:10.965933
125	refresh_tokens	INSERT	\N	{"id": 65, "role": "admin", "token": "0a09202fc2fad6bfd6311920a2b2acd6d856f95c8673e7fc078f003702c2c82a", "username": "valentin_admin", "created_at": "2025-12-06T08:17:10.972563"}	admin	2025-12-06 08:17:10.972563
126	refresh_tokens	DELETE	{"id": 65, "role": "admin", "token": "0a09202fc2fad6bfd6311920a2b2acd6d856f95c8673e7fc078f003702c2c82a", "username": "valentin_admin", "created_at": "2025-12-06T08:17:10.972563"}	\N	admin	2025-12-06 08:44:28.402223
127	refresh_tokens	INSERT	\N	{"id": 66, "role": "admin", "token": "3fd9b04bf172bfa89f3ffc55590387274cbe290739b02514dcae507528c257a6", "username": "valentin_admin", "created_at": "2025-12-06T08:44:28.410055"}	admin	2025-12-06 08:44:28.410055
128	refresh_tokens	DELETE	{"id": 66, "role": "admin", "token": "3fd9b04bf172bfa89f3ffc55590387274cbe290739b02514dcae507528c257a6", "username": "valentin_admin", "created_at": "2025-12-06T08:44:28.410055"}	\N	admin	2025-12-06 08:50:16.150939
129	refresh_tokens	INSERT	\N	{"id": 67, "role": "admin", "token": "00b14650f0f376d609bbb9f6bfa77b307d1938777cd07d8a450e5937b1433bdd", "username": "valentin_admin", "created_at": "2025-12-06T08:50:16.169089"}	admin	2025-12-06 08:50:16.169089
130	refresh_tokens	DELETE	{"id": 67, "role": "admin", "token": "00b14650f0f376d609bbb9f6bfa77b307d1938777cd07d8a450e5937b1433bdd", "username": "valentin_admin", "created_at": "2025-12-06T08:50:16.169089"}	\N	admin	2025-12-06 08:50:38.724637
131	refresh_tokens	INSERT	\N	{"id": 68, "role": "admin", "token": "625ccf489d78027be4e630c77554ed67a7b1bbdca458b55edd3f1d2730cac123", "username": "valentin_admin", "created_at": "2025-12-06T08:50:38.726435"}	admin	2025-12-06 08:50:38.726435
132	product	UPDATE	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "placeholder.png", "id_producer": 1, "id_product_category": 1}	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "/static/products/1765011046095675919_a4c7c78c78a454e231f7718718ae6195.jpg", "id_producer": 1, "id_product_category": 1}	admin	2025-12-06 08:50:46.097652
133	product	UPDATE	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "placeholder.png", "id_producer": 2, "id_product_category": 2}	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "/static/products/1765011070099983639_images (3).jpeg", "id_producer": 2, "id_product_category": 2}	admin	2025-12-06 08:51:10.100518
134	product	UPDATE	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "placeholder.png", "id_producer": 1, "id_product_category": 1}	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "/static/products/1765011089390225675_images (2).jpeg", "id_producer": 1, "id_product_category": 1}	admin	2025-12-06 08:51:29.391089
135	product	UPDATE	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "placeholder.png", "id_producer": 2, "id_product_category": 2}	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "/static/products/1765011109815931171_images.jpeg", "id_producer": 2, "id_product_category": 2}	admin	2025-12-06 08:51:49.816443
136	refresh_tokens	DELETE	{"id": 68, "role": "admin", "token": "625ccf489d78027be4e630c77554ed67a7b1bbdca458b55edd3f1d2730cac123", "username": "valentin_admin", "created_at": "2025-12-06T08:50:38.726435"}	\N	admin	2025-12-06 10:45:17.012505
137	refresh_tokens	INSERT	\N	{"id": 69, "role": "admin", "token": "e2752681b877f708f2747682bf6d221971b36044b54571bb810f80c071febdfc", "username": "valentin_admin", "created_at": "2025-12-06T10:45:17.019766"}	admin	2025-12-06 10:45:17.019766
138	refresh_tokens	DELETE	{"id": 62, "role": "admin", "token": "88a6d1d348d14aef39c595b470446caf2a3e1579ca0c366f08bd776c3037da5b", "username": "valentin_admin", "created_at": "2025-12-05T09:28:35.024116"}	\N	postgres	2025-12-06 10:45:56.560168
139	refresh_tokens	DELETE	{"id": 61, "role": "manager", "token": "113415de5b947858e7bdcf797306349a9de999f368c0241232e5ee7848ce4bef", "username": "manager_login", "created_at": "2025-12-01T06:06:58.81918"}	\N	postgres	2025-12-06 10:46:02.613549
140	refresh_tokens	DELETE	{"id": 59, "role": "admin", "token": "211f8f489af394bc0e59d5d3e468bd64e6f00c4a5856556542ec87d45cb43f09", "username": "admin_login", "created_at": "2025-12-01T06:06:39.552779"}	\N	postgres	2025-12-06 10:46:05.258675
141	refresh_tokens	DELETE	{"id": 57, "role": "manager", "token": "755f8c6b5d0b56badc69d2935a7e4f36def3dd84cddd5d2cafda1d34347385b9", "username": "manager_login", "created_at": "2025-11-30T16:43:14.962878"}	\N	postgres	2025-12-06 10:46:07.396837
142	refresh_tokens	DELETE	{"id": 56, "role": "admin", "token": "271ee7e19922baa281276e15b39752405e7dea3b50df417a5c73288e3bdaae7c", "username": "admin_login", "created_at": "2025-11-30T15:21:30.050496"}	\N	postgres	2025-12-06 10:46:10.713063
143	refresh_tokens	DELETE	{"id": 69, "role": "admin", "token": "e2752681b877f708f2747682bf6d221971b36044b54571bb810f80c071febdfc", "username": "valentin_admin", "created_at": "2025-12-06T10:45:17.019766"}	\N	admin	2025-12-06 10:57:31.554838
144	refresh_tokens	INSERT	\N	{"id": 70, "role": "admin", "token": "e5c4ea5d108bdc6cea4eab69ffbc853cec95969d0901318f7303d2a0b77d7a10", "username": "valentin_admin", "created_at": "2025-12-06T10:57:31.561397"}	admin	2025-12-06 10:57:31.561397
145	product	INSERT	\N	{"id": 6, "name": "Placeholder", "image_url": "", "id_producer": 2, "id_product_category": 3}	admin	2025-12-06 11:06:17.546029
146	product	UPDATE	{"id": 6, "name": "Placeholder", "image_url": "", "id_producer": 2, "id_product_category": 3}	{"id": 6, "name": "Placeholder", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 2, "id_product_category": 3}	admin	2025-12-06 11:07:53.080201
147	refresh_tokens	DELETE	{"id": 70, "role": "admin", "token": "e5c4ea5d108bdc6cea4eab69ffbc853cec95969d0901318f7303d2a0b77d7a10", "username": "valentin_admin", "created_at": "2025-12-06T10:57:31.561397"}	\N	admin	2025-12-06 11:13:40.134178
148	refresh_tokens	INSERT	\N	{"id": 71, "role": "admin", "token": "a9b1b3b18dfaf114916b28c16979fd19036e1fd667d8d4afa6e034854a99a98f", "username": "valentin_admin", "created_at": "2025-12-06T11:13:40.147373"}	admin	2025-12-06 11:13:40.147373
149	refresh_tokens	DELETE	{"id": 71, "role": "admin", "token": "a9b1b3b18dfaf114916b28c16979fd19036e1fd667d8d4afa6e034854a99a98f", "username": "valentin_admin", "created_at": "2025-12-06T11:13:40.147373"}	\N	admin	2025-12-06 11:19:39.251792
150	refresh_tokens	INSERT	\N	{"id": 72, "role": "admin", "token": "71b6adff68788397a0013731763f10d0d912fb78a33074e82115e78570b4312f", "username": "valentin_admin", "created_at": "2025-12-06T11:19:39.260462"}	admin	2025-12-06 11:19:39.260462
151	product	UPDATE	{"id": 6, "name": "Placeholder", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 2, "id_product_category": 3}	{"id": 6, "name": "Placehold", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 1, "id_product_category": 1}	admin	2025-12-06 11:19:46.529985
152	product	DELETE	{"id": 6, "name": "Placehold", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 1, "id_product_category": 1}	\N	admin	2025-12-06 11:22:46.408884
153	refresh_tokens	DELETE	{"id": 72, "role": "admin", "token": "71b6adff68788397a0013731763f10d0d912fb78a33074e82115e78570b4312f", "username": "valentin_admin", "created_at": "2025-12-06T11:19:39.260462"}	\N	admin	2025-12-06 12:13:13.129492
154	refresh_tokens	INSERT	\N	{"id": 73, "role": "admin", "token": "f664ffe1be2eccda7122c8c3c18572a69535fdf8aa0ce2b28d15e5255110c895", "username": "valentin_admin", "created_at": "2025-12-06T12:13:13.133744"}	admin	2025-12-06 12:13:13.133744
155	product_category	INSERT	\N	{"id": 4, "name": "тест"}	postgres	2025-12-06 12:28:08.279316
156	refresh_tokens	DELETE	{"id": 73, "role": "admin", "token": "f664ffe1be2eccda7122c8c3c18572a69535fdf8aa0ce2b28d15e5255110c895", "username": "valentin_admin", "created_at": "2025-12-06T12:13:13.133744"}	\N	admin	2025-12-06 12:28:20.146233
157	refresh_tokens	INSERT	\N	{"id": 74, "role": "admin", "token": "b947f9a86494edabc7c731e319d938aa1bd9a7d34cc5260c21cbefb09401ce5b", "username": "valentin_admin", "created_at": "2025-12-06T12:28:20.148218"}	admin	2025-12-06 12:28:20.148218
158	product_category	DELETE	{"id": 4, "name": "тест"}	\N	admin	2025-12-06 12:36:05.680591
159	refresh_tokens	DELETE	{"id": 74, "role": "admin", "token": "b947f9a86494edabc7c731e319d938aa1bd9a7d34cc5260c21cbefb09401ce5b", "username": "valentin_admin", "created_at": "2025-12-06T12:28:20.148218"}	\N	admin	2025-12-06 13:11:28.205135
160	refresh_tokens	INSERT	\N	{"id": 75, "role": "admin", "token": "f7737d326e65a407c96a7dcdfff78370597e8ee38c7f83e3ec738668ffd5be69", "username": "valentin_admin", "created_at": "2025-12-06T13:11:28.212287"}	admin	2025-12-06 13:11:28.212287
161	product_category	INSERT	\N	{"id": 5, "name": "Посуда"}	admin	2025-12-06 13:13:59.849689
162	product_category	DELETE	{"id": 5, "name": "Посуда"}	\N	admin	2025-12-06 13:14:57.003044
163	product_category	INSERT	\N	{"id": 7, "name": "Посуда"}	admin	2025-12-06 13:15:02.663377
164	product_category	UPDATE	{"id": 7, "name": "Посуда"}	{"id": 7, "name": "Placeholder"}	admin	2025-12-06 13:18:39.759869
165	product_category	DELETE	{"id": 7, "name": "Placeholder"}	\N	admin	2025-12-06 13:20:09.886505
166	batch	INSERT	\N	{"id": 11, "cost": 134, "created_at": "2025-12-06T13:45:45.295078", "id_product": 3, "expiration_date": "2024-12-05", "production_date": "2024-12-06"}	postgres	2025-12-06 13:45:45.295078
167	document	INSERT	\N	{"id": 7, "date": "2024-12-23", "id_employee": 1, "id_document_category": 1}	postgres	2025-12-06 13:46:25.303401
168	document_content	INSERT	\N	{"id": 12, "id_batch": 11, "quantity": 100, "id_product": 1, "id_document": 7}	postgres	2025-12-06 13:47:12.80487
169	document	INSERT	\N	{"id": 8, "date": "2025-01-20", "id_employee": 2, "id_document_category": 2}	postgres	2025-12-06 13:49:52.765176
170	document_content	INSERT	\N	{"id": 13, "id_batch": 11, "quantity": 37, "id_document": 8}	postgres	2025-12-06 13:50:08.846909
171	producer	INSERT	\N	{"id": 4, "inn": "1234323858", "name": "ИП \\"Михайлов\\"", "surname": "Михайлов", "firstname": "Роман", "id_address": 1, "patronymic": "Александрович"}	postgres	2025-12-06 14:19:30.631278
172	producer	INSERT	\N	{"id": 5, "inn": "5467823934", "name": "АО \\"АвтоВлад\\"", "surname": "Судный", "firstname": "Максим", "id_address": 6, "patronymic": "Рэмович"}	postgres	2025-12-06 14:20:51.176793
173	refresh_tokens	INSERT	\N	{"id": 76, "role": "manager", "token": "9c3dc39afb2dffead0a18529248d58cbcab217e3f9606c8ac3886e4a15d66992", "username": "manager_login", "created_at": "2025-12-07T06:52:48.444446"}	admin	2025-12-07 06:52:48.444446
174	product_category	INSERT	\N	{"id": 8, "name": "Посуда"}	manager	2025-12-07 06:52:57.435728
175	refresh_tokens	DELETE	{"id": 75, "role": "admin", "token": "f7737d326e65a407c96a7dcdfff78370597e8ee38c7f83e3ec738668ffd5be69", "username": "valentin_admin", "created_at": "2025-12-06T13:11:28.212287"}	\N	admin	2025-12-07 10:37:52.83045
176	refresh_tokens	INSERT	\N	{"id": 77, "role": "admin", "token": "c1fc0c5a81402767019b601eece71c0bee2060bc7b0819a3a40ec8760f4f1dd0", "username": "valentin_admin", "created_at": "2025-12-07T10:37:52.836468"}	admin	2025-12-07 10:37:52.836468
177	refresh_tokens	DELETE	{"id": 77, "role": "admin", "token": "c1fc0c5a81402767019b601eece71c0bee2060bc7b0819a3a40ec8760f4f1dd0", "username": "valentin_admin", "created_at": "2025-12-07T10:37:52.836468"}	\N	admin	2025-12-07 11:21:40.196783
178	refresh_tokens	INSERT	\N	{"id": 78, "role": "admin", "token": "e4dc483a873c06e0d2e4ed11c67e19940b2fd65e5a96de4a06c37f3e913fa32f", "username": "valentin_admin", "created_at": "2025-12-07T11:21:40.205741"}	admin	2025-12-07 11:21:40.205741
179	refresh_tokens	DELETE	{"id": 78, "role": "admin", "token": "e4dc483a873c06e0d2e4ed11c67e19940b2fd65e5a96de4a06c37f3e913fa32f", "username": "valentin_admin", "created_at": "2025-12-07T11:21:40.205741"}	\N	admin	2025-12-07 12:24:33.991088
180	refresh_tokens	INSERT	\N	{"id": 79, "role": "admin", "token": "5d6088bcee48fed7ef4f35785a47e9f5c80b281585474e624216d5567ce1f849", "username": "valentin_admin", "created_at": "2025-12-07T12:24:33.996466"}	admin	2025-12-07 12:24:33.996466
181	refresh_tokens	DELETE	{"id": 79, "role": "admin", "token": "5d6088bcee48fed7ef4f35785a47e9f5c80b281585474e624216d5567ce1f849", "username": "valentin_admin", "created_at": "2025-12-07T12:24:33.996466"}	\N	admin	2025-12-07 12:56:31.462401
182	refresh_tokens	INSERT	\N	{"id": 80, "role": "admin", "token": "7c1a2e545f5ededc4d9880eb8f58b979382301a7d3aa4d6a3dd45f8afe30324d", "username": "valentin_admin", "created_at": "2025-12-07T12:56:31.477525"}	admin	2025-12-07 12:56:31.477525
183	product_category	INSERT	\N	{"id": 9, "name": "test"}	admin	2025-12-07 12:57:36.228564
184	product_category	DELETE	{"id": 9, "name": "test"}	\N	admin	2025-12-07 12:57:48.399966
185	producer	INSERT	\N	{"id": 6, "inn": "0123456789", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	admin	2025-12-07 13:00:02.180802
186	producer	INSERT	\N	{"id": 8, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	admin	2025-12-07 13:00:32.393072
187	producer	DELETE	{"id": 6, "inn": "0123456789", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	\N	admin	2025-12-07 13:00:50.680936
188	producer	DELETE	{"id": 8, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	\N	admin	2025-12-07 13:00:52.822328
189	producer	INSERT	\N	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	admin	2025-12-07 13:02:58.491127
190	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:04:35.023077
191	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:04:54.609017
192	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:02.922873
193	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:07.393071
194	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:08.305619
195	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:08.967501
196	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:09.667729
197	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:10.296162
198	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:10.885358
199	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:11.468342
200	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:12.044059
201	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:12.581566
202	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:13.147355
203	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 13:05:25.994683
204	producer	DELETE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	\N	admin	2025-12-07 13:05:43.99447
205	refresh_tokens	DELETE	{"id": 80, "role": "admin", "token": "7c1a2e545f5ededc4d9880eb8f58b979382301a7d3aa4d6a3dd45f8afe30324d", "username": "valentin_admin", "created_at": "2025-12-07T12:56:31.477525"}	\N	admin	2025-12-07 15:58:22.542464
206	refresh_tokens	INSERT	\N	{"id": 81, "role": "admin", "token": "05a775164a2c23a61825345f0ef0148e7a2d0b2f88f800bc9410f4e097b2fd2e", "username": "valentin_admin", "created_at": "2025-12-07T15:58:22.553163"}	admin	2025-12-07 15:58:22.553163
207	position	INSERT	\N	{"id": 7, "name": "temp", "description": "temp"}	postgres	2025-12-07 16:39:01.00384
208	position	DELETE	{"id": 7, "name": "temp", "description": "temp"}	\N	admin	2025-12-07 16:40:24.739229
209	refresh_tokens	DELETE	{"id": 81, "role": "admin", "token": "05a775164a2c23a61825345f0ef0148e7a2d0b2f88f800bc9410f4e097b2fd2e", "username": "valentin_admin", "created_at": "2025-12-07T15:58:22.553163"}	\N	admin	2025-12-07 17:00:49.515657
210	refresh_tokens	INSERT	\N	{"id": 82, "role": "admin", "token": "a98b217c5f9c872538b892fd1f04f1de079a78efb8a889b1846e9a777c95406b", "username": "valentin_admin", "created_at": "2025-12-07T17:00:49.523404"}	admin	2025-12-07 17:00:49.523404
211	position	INSERT	\N	{"id": 8, "name": "test", "description": "test"}	admin	2025-12-07 17:04:10.541119
212	position	UPDATE	{"id": 8, "name": "test", "description": "test"}	{"id": 8, "name": "test21", "description": "test12"}	admin	2025-12-07 17:04:44.881632
213	position	DELETE	{"id": 8, "name": "test21", "description": "test12"}	\N	admin	2025-12-07 17:04:56.548691
214	refresh_tokens	DELETE	{"id": 82, "role": "admin", "token": "a98b217c5f9c872538b892fd1f04f1de079a78efb8a889b1846e9a777c95406b", "username": "valentin_admin", "created_at": "2025-12-07T17:00:49.523404"}	\N	admin	2025-12-08 08:48:33.604689
215	refresh_tokens	INSERT	\N	{"id": 83, "role": "admin", "token": "050bc96f21cc7f36a74602bdd3b1973cde806c1c477f0df19b78c7bc8c7cf160", "username": "valentin_admin", "created_at": "2025-12-08T08:48:33.615528"}	admin	2025-12-08 08:48:33.615528
216	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 6, "phone_number": "1111111111111111"}	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	admin	2025-12-08 08:55:13.264927
217	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	admin	2025-12-08 08:56:52.388334
218	refresh_tokens	DELETE	{"id": 83, "role": "admin", "token": "050bc96f21cc7f36a74602bdd3b1973cde806c1c477f0df19b78c7bc8c7cf160", "username": "valentin_admin", "created_at": "2025-12-08T08:48:33.615528"}	\N	admin	2025-12-08 10:12:36.200916
219	refresh_tokens	INSERT	\N	{"id": 84, "role": "admin", "token": "77bb2a9b4c761f6fd7554e05bd812b9109b6e221345f9ddddb95f965a006a025", "username": "valentin_admin", "created_at": "2025-12-08T10:12:36.205304"}	admin	2025-12-08 10:12:36.205304
220	address	INSERT	\N	{"id": 16, "city": "test", "region": "test", "street": "test", "subject": "test", "building": 12}	admin	2025-12-08 10:14:36.338868
221	address	UPDATE	{"id": 16, "city": "test", "region": "test", "street": "test", "subject": "test", "building": 12}	{"id": 16, "city": "test1", "region": "test2", "street": "test0", "subject": "test3", "building": 1}	admin	2025-12-08 10:15:12.944608
222	address	DELETE	{"id": 16, "city": "test1", "region": "test2", "street": "test0", "subject": "test3", "building": 1}	\N	admin	2025-12-08 10:15:33.070826
223	document_category	INSERT	\N	{"id": 4, "name": "test", "description": "test"}	admin	2025-12-08 10:30:18.348391
224	document_category	UPDATE	{"id": 4, "name": "test", "description": "test"}	{"id": 4, "name": "test2", "description": "test1"}	admin	2025-12-08 10:30:45.594678
226	refresh_tokens	DELETE	{"id": 84, "role": "admin", "token": "77bb2a9b4c761f6fd7554e05bd812b9109b6e221345f9ddddb95f965a006a025", "username": "valentin_admin", "created_at": "2025-12-08T10:12:36.205304"}	\N	admin	2025-12-08 11:14:54.610279
227	refresh_tokens	INSERT	\N	{"id": 85, "role": "admin", "token": "f12fb44c074cb932351aa7ac412c1ca16f873da98bf45e6c8eda93ec205291c2", "username": "valentin_admin", "created_at": "2025-12-08T11:14:54.619104"}	admin	2025-12-08 11:14:54.619104
228	refresh_tokens	DELETE	{"id": 85, "role": "admin", "token": "f12fb44c074cb932351aa7ac412c1ca16f873da98bf45e6c8eda93ec205291c2", "username": "valentin_admin", "created_at": "2025-12-08T11:14:54.619104"}	\N	admin	2025-12-08 11:58:43.335946
229	refresh_tokens	INSERT	\N	{"id": 86, "role": "admin", "token": "1dd141264597581e199603c9597d659326c48069db263c7ae12e01c87fc0add6", "username": "valentin_admin", "created_at": "2025-12-08T11:58:43.343928"}	admin	2025-12-08 11:58:43.343928
230	refresh_tokens	DELETE	{"id": 86, "role": "admin", "token": "1dd141264597581e199603c9597d659326c48069db263c7ae12e01c87fc0add6", "username": "valentin_admin", "created_at": "2025-12-08T11:58:43.343928"}	\N	admin	2025-12-08 12:50:16.757027
231	refresh_tokens	INSERT	\N	{"id": 87, "role": "admin", "token": "2cb9cd6505793f0c14a9735c3336c3bf7f807d448511f006e67ee025799fcefc", "username": "valentin_admin", "created_at": "2025-12-08T12:50:16.763149"}	admin	2025-12-08 12:50:16.763149
232	document	INSERT	\N	{"id": 9, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	admin	2025-12-08 12:57:23.351389
233	document	DELETE	{"id": 9, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	\N	postgres	2025-12-08 12:58:13.057678
234	document	INSERT	\N	{"id": 10, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	admin	2025-12-08 12:58:16.556003
235	document	UPDATE	{"id": 1, "date": "2024-03-10", "id_employee": 2, "id_document_category": 1}	{"id": 1, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
236	document	UPDATE	{"id": 2, "date": "2024-03-18", "id_employee": 2, "id_document_category": 2}	{"id": 2, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
237	document	UPDATE	{"id": 3, "date": "2024-03-25", "id_employee": 2, "id_document_category": 3}	{"id": 3, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
238	document	UPDATE	{"id": 4, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	{"id": 4, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
239	document	UPDATE	{"id": 5, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	{"id": 5, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
240	document	UPDATE	{"id": 6, "date": "2025-11-22", "id_employee": 1, "id_document_category": 3}	{"id": 6, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
241	document	UPDATE	{"id": 7, "date": "2024-12-23", "id_employee": 1, "id_document_category": 1}	{"id": 7, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
242	document	UPDATE	{"id": 8, "date": "2025-01-20", "id_employee": 2, "id_document_category": 2}	{"id": 8, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
243	document	UPDATE	{"id": 10, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	{"id": 10, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 12:59:25.342038
244	document	DELETE	{"id": 10, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	\N	admin	2025-12-08 12:59:56.505616
245	document_content	INSERT	\N	{"id": 14, "id_batch": 3, "quantity": 500, "id_document": 1}	admin	2025-12-08 13:04:12.443516
246	document_content	UPDATE	{"id": 1, "id_batch": 1, "quantity": 5, "id_document": 1}	{"id": 1, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
247	document_content	UPDATE	{"id": 2, "id_batch": 2, "quantity": 3, "id_document": 1}	{"id": 2, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
248	document_content	UPDATE	{"id": 3, "id_batch": 3, "quantity": 10, "id_document": 1}	{"id": 3, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
249	document_content	UPDATE	{"id": 4, "id_batch": 4, "quantity": 15, "id_document": 1}	{"id": 4, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
250	document_content	UPDATE	{"id": 5, "id_batch": 5, "quantity": 2, "id_document": 1}	{"id": 5, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
251	document_content	UPDATE	{"id": 6, "id_batch": 1, "quantity": 4, "id_document": 2}	{"id": 6, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
252	document_content	UPDATE	{"id": 7, "id_batch": 4, "quantity": 3, "id_document": 2}	{"id": 7, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
253	document_content	UPDATE	{"id": 9, "id_batch": 3, "quantity": 2, "id_document": 3}	{"id": 9, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
254	document_content	UPDATE	{"id": 10, "id_batch": 4, "quantity": 1, "id_document": 3}	{"id": 10, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
255	document_content	UPDATE	{"id": 11, "id_batch": 5, "quantity": 1, "id_document": 3}	{"id": 11, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
256	document_content	UPDATE	{"id": 8, "id_batch": 5, "quantity": 2, "id_document": 2}	{"id": 8, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
257	document_content	UPDATE	{"id": 12, "id_batch": 11, "quantity": 100, "id_document": 7}	{"id": 12, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
258	document_content	UPDATE	{"id": 13, "id_batch": 11, "quantity": 37, "id_document": 8}	{"id": 13, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
259	document_content	UPDATE	{"id": 14, "id_batch": 3, "quantity": 500, "id_document": 1}	{"id": 14, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 13:06:10.718255
260	document_content	DELETE	{"id": 14, "id_batch": 3, "quantity": 5000, "id_document": 1}	\N	admin	2025-12-08 13:06:26.943108
261	refresh_tokens	DELETE	{"id": 87, "role": "admin", "token": "2cb9cd6505793f0c14a9735c3336c3bf7f807d448511f006e67ee025799fcefc", "username": "valentin_admin", "created_at": "2025-12-08T12:50:16.763149"}	\N	admin	2025-12-08 14:24:58.373132
262	refresh_tokens	INSERT	\N	{"id": 88, "role": "admin", "token": "b1538156433473107447b1fd69239686c3de2b43fbd39bda93dc74612e3b6d54", "username": "valentin_admin", "created_at": "2025-12-08T14:24:58.383009"}	admin	2025-12-08 14:24:58.383009
263	document_content	UPDATE	{"id": 13, "id_batch": 3, "quantity": 5000, "id_document": 1}	{"id": 13, "id_batch": 3, "quantity": 500, "id_document": 1}	admin	2025-12-08 14:25:20.367266
264	document	INSERT	\N	{"id": 1, "date": "2024-03-10", "id_employee": 2, "id_document_category": 1}	postgres	2025-12-08 14:28:39.90088
265	document	INSERT	\N	{"id": 2, "date": "2024-03-18", "id_employee": 2, "id_document_category": 2}	postgres	2025-12-08 14:28:39.90088
266	document	INSERT	\N	{"id": 3, "date": "2024-03-25", "id_employee": 2, "id_document_category": 3}	postgres	2025-12-08 14:28:39.90088
267	document	INSERT	\N	{"id": 4, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	postgres	2025-12-08 14:28:39.90088
268	document	INSERT	\N	{"id": 5, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	postgres	2025-12-08 14:28:39.90088
269	document	INSERT	\N	{"id": 6, "date": "2025-11-22", "id_employee": 1, "id_document_category": 3}	postgres	2025-12-08 14:28:39.90088
270	document_content	INSERT	\N	{"id": 1, "id_batch": 1, "quantity": 5, "id_document": 1}	postgres	2025-12-08 14:29:26.098872
271	document_content	INSERT	\N	{"id": 2, "id_batch": 2, "quantity": 3, "id_document": 1}	postgres	2025-12-08 14:29:26.098872
272	document_content	INSERT	\N	{"id": 3, "id_batch": 3, "quantity": 10, "id_document": 1}	postgres	2025-12-08 14:29:26.098872
273	document_content	INSERT	\N	{"id": 4, "id_batch": 4, "quantity": 15, "id_document": 1}	postgres	2025-12-08 14:29:26.098872
274	document_content	INSERT	\N	{"id": 5, "id_batch": 5, "quantity": 2, "id_document": 1}	postgres	2025-12-08 14:29:26.098872
275	document_content	INSERT	\N	{"id": 6, "id_batch": 1, "quantity": 4, "id_document": 2}	postgres	2025-12-08 14:29:26.098872
276	document_content	INSERT	\N	{"id": 7, "id_batch": 4, "quantity": 3, "id_document": 2}	postgres	2025-12-08 14:29:26.098872
277	document_content	INSERT	\N	{"id": 8, "id_batch": 5, "quantity": 2, "id_document": 2}	postgres	2025-12-08 14:29:26.098872
278	document_content	INSERT	\N	{"id": 9, "id_batch": 3, "quantity": 2, "id_document": 3}	postgres	2025-12-08 14:29:26.098872
279	document_content	INSERT	\N	{"id": 10, "id_batch": 4, "quantity": 1, "id_document": 3}	postgres	2025-12-08 14:29:26.098872
280	document_content	INSERT	\N	{"id": 11, "id_batch": 5, "quantity": 1, "id_document": 3}	postgres	2025-12-08 14:29:26.098872
281	refresh_tokens	DELETE	{"id": 88, "role": "admin", "token": "b1538156433473107447b1fd69239686c3de2b43fbd39bda93dc74612e3b6d54", "username": "valentin_admin", "created_at": "2025-12-08T14:24:58.383009"}	\N	admin	2025-12-08 14:54:21.532986
282	refresh_tokens	INSERT	\N	{"id": 89, "role": "admin", "token": "b3bc6fa09deb6ef0221bd9d5fda49b7e7ec6534fbc45bf4e34b31d9b8f6cebfa", "username": "valentin_admin", "created_at": "2025-12-08T14:54:21.536731"}	admin	2025-12-08 14:54:21.536731
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
8	2	2025-10-30	2026-01-30	1	2025-11-30 14:27:02.406452
9	2	2025-01-30	2025-12-30	3	2025-11-30 14:28:46.581513
10	10	2025-11-29	2025-12-30	4	2025-11-30 15:25:23.003956
11	134	2024-12-06	2024-12-05	3	2025-12-06 13:45:45.295078
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

COPY public.document_content (id, id_document, id_batch, quantity) FROM stdin;
1	1	1	5
2	1	2	3
3	1	3	10
4	1	4	15
5	1	5	2
6	2	1	4
7	2	4	3
8	2	5	2
9	3	3	2
10	3	4	1
11	3	5	1
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
10	test2	test2	test2	1	111111111111	1111111111111111	1	2025-01-01	1
11	a	a	a	1	222222222222	2222222222222222	1	0001-01-01	1
14	Баранов	Валентин	Александрович	1	111111111112	1111111111111111	1	2025-12-05	4
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
4	ИП "Михайлов"	1	1234323858	Михайлов	Роман	Александрович
5	АО "АвтоВлад"	6	5467823934	Судный	Максим	Рэмович
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (id, name, id_product_category, id_producer, image_url) FROM stdin;
3	Материнская плата "Gamer XTREME"	3	3	/static/products/1765008872100895552_7179111216.jpg
1	Кухонный гарнитур "Уют"	1	1	/static/products/1765011046095675919_a4c7c78c78a454e231f7718718ae6195.jpg
2	Стиральная машина "SM-5000"	2	2	/static/products/1765011070099983639_images (3).jpeg
4	Офисное кресло "Director"	1	1	/static/products/1765011089390225675_images (2).jpeg
5	Холодильник "Frost+ 300"	2	2	/static/products/1765011109815931171_images.jpeg
\.


--
-- Data for Name: product_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_category (id, name) FROM stdin;
1	Мебель
2	Электроника
3	Бытовая техника
8	Посуда
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, token, username, role, created_at) FROM stdin;
76	9c3dc39afb2dffead0a18529248d58cbcab217e3f9606c8ac3886e4a15d66992	manager_login	manager	2025-12-07 06:52:48.444446
89	b3bc6fa09deb6ef0221bd9d5fda49b7e7ec6534fbc45bf4e34b31d9b8f6cebfa	valentin_admin	admin	2025-12-08 14:54:21.536731
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
4	manager_login	$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu	2	4
5	moderator_login	$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK	1	5
6	admin_login	$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK	4	2
7	valentin_admin	$2a$10$20LdgaOXwKGG9jQAJXDkMeIjzJo4jn5pMcr/Forby.IdMLDA9vuCK	4	14
\.


--
-- Name: address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.address_id_seq', 16, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 282, true);


--
-- Name: batch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.batch_id_seq', 11, true);


--
-- Name: document_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_category_id_seq', 4, true);


--
-- Name: document_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_content_id_seq', 14, true);


--
-- Name: document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_id_seq', 10, true);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_id_seq', 14, true);


--
-- Name: gender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gender_id_seq', 3, true);


--
-- Name: position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_id_seq', 8, true);


--
-- Name: producer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producer_id_seq', 9, true);


--
-- Name: product_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_category_id_seq', 9, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 6, true);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refresh_tokens_id_seq', 89, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 4, true);


--
-- Name: sys_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sys_user_id_seq', 7, true);


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
-- Name: TABLE gender; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.gender TO admin;
GRANT SELECT ON TABLE public.gender TO moderator;
GRANT SELECT ON TABLE public.gender TO manager;


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
-- Name: TABLE producer; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.producer TO admin;
GRANT SELECT ON TABLE public.producer TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.producer TO manager;


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
-- Name: TABLE refresh_tokens; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE ON TABLE public.refresh_tokens TO admin;
GRANT INSERT,DELETE ON TABLE public.refresh_tokens TO moderator;
GRANT INSERT,DELETE ON TABLE public.refresh_tokens TO manager;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO admin;
GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO moderator;
GRANT ALL ON SEQUENCE public.refresh_tokens_id_seq TO manager;


--
-- Name: TABLE report_batches; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_batches TO moderator;


--
-- Name: TABLE report_employees; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_employees TO admin;
GRANT SELECT ON TABLE public.report_employees TO moderator;


--
-- Name: TABLE report_no_products; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_no_products TO admin;
GRANT SELECT ON TABLE public.report_no_products TO moderator;


--
-- Name: TABLE report_products_left; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_products_left TO admin;
GRANT SELECT ON TABLE public.report_products_left TO moderator;


--
-- Name: TABLE role; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.role TO admin;
GRANT SELECT ON TABLE public.role TO manager;
GRANT SELECT ON TABLE public.role TO moderator;


--
-- Name: TABLE sys_user; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.sys_user TO admin;
GRANT SELECT ON TABLE public.sys_user TO moderator;


--
-- Name: TABLE report_system_users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_system_users TO admin;


--
-- Name: SEQUENCE sys_user_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sys_user_id_seq TO admin;


--
-- Name: batches_m; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: postgres
--

REFRESH MATERIALIZED VIEW public.batches_m;


--
-- PostgreSQL database dump complete
--

\unrestrict ZKXIJGzZNn39MWRkeXwLAT2cpSqnqqn8INyhkPDW3CdChYcF3Ud5EJKi7EFd0zR

