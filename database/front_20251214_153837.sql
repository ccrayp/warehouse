--
-- PostgreSQL database cluster dump
--

\restrict KbnVUxgbeiA1eduoFXVcKHez7rbbo0nD67SASCkyhIYiUaXKhjGzvZ8NAfdDs3v

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








\unrestrict KbnVUxgbeiA1eduoFXVcKHez7rbbo0nD67SASCkyhIYiUaXKhjGzvZ8NAfdDs3v

--
-- PostgreSQL database cluster dump complete
--

--
-- PostgreSQL database dump
--

\restrict FmJYTKcX9oQhycIA65rRx32fJ0f7HSiCbriuhnYAN7r91lGii0C6oPgcTRmSAZa

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
-- Name: delete_old(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.delete_old() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM audit_log WHERE changed_at < CURRENT_TIMESTAMP - INTERVAL '1 month';

	RETURN NEW;
END;
$$;


ALTER FUNCTION public.delete_old() OWNER TO postgres;

--
-- Name: get_interface_grants(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_interface_grants(p_role text) RETURNS TABLE(role text, section text, permissions text[])
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM report_interface_grants rig
        WHERE rig.role = p_role
    ) THEN
        RAISE EXCEPTION 'ERROR: no grants for this role (%)', p_role;
    END IF;

    RETURN QUERY
    SELECT 
        rig.role::text,
        rig.section::text,
        rig.permissions
    FROM report_interface_grants AS rig
    WHERE rig.role = p_role
    ORDER BY rig.section;
END;
$$;


ALTER FUNCTION public.get_interface_grants(p_role text) OWNER TO postgres;

--
-- Name: get_products_left_in_batch(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_products_left_in_batch(v_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	v_products_left INT DEFAULT 0;
BEGIN
	IF NOT EXISTS (SELECT 1 FROM report_products_left_by_batch WHERE id_batch = v_id) THEN
		RAISE EXCEPTION 'ERROR: no batch with such id (%)', v_id;
	END IF;
	
	SELECT 
		left_quantity INTO v_products_left 
	FROM report_products_left_by_batch WHWRE
	WHERE id_batch = v_id;

	RETURN v_products_left;
END;
$$;


ALTER FUNCTION public.get_products_left_in_batch(v_id integer) OWNER TO postgres;

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
    changed_by text NOT NULL,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
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
    image_url text DEFAULT '/static/products/placeholder.png'::text NOT NULL
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
    patronymic character varying(50),
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
    patronymic character varying(50)
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
          WHERE (((role_table_grants.grantee)::name = ANY (ARRAY['admin'::name, 'moderator'::name, 'manager'::name])) AND ((role_table_grants.table_name)::name <> 'refresh_tokens'::name))
          GROUP BY role_table_grants.grantee, role_table_grants.table_name
          ORDER BY role_table_grants.grantee, role_table_grants.table_name) t;


ALTER TABLE public.report_grants OWNER TO postgres;

--
-- Name: report_interface_grants; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_interface_grants AS
 SELECT table_privileges.grantee AS role,
    table_privileges.table_name AS section,
    array_agg(lower((table_privileges.privilege_type)::text) ORDER BY
        CASE lower((table_privileges.privilege_type)::text)
            WHEN 'select'::text THEN 1
            WHEN 'insert'::text THEN 2
            WHEN 'update'::text THEN 3
            WHEN 'delete'::text THEN 4
            ELSE 5
        END) AS permissions
   FROM information_schema.table_privileges
  WHERE (((table_privileges.privilege_type)::text = ANY (ARRAY[('SELECT'::character varying)::text, ('INSERT'::character varying)::text, ('UPDATE'::character varying)::text, ('DELETE'::character varying)::text])) AND ((table_privileges.grantee)::name = ANY (ARRAY['admin'::name, 'moderator'::name, 'manager'::name])))
  GROUP BY table_privileges.grantee, table_privileges.table_name
  ORDER BY table_privileges.grantee, table_privileges.table_name;


ALTER TABLE public.report_interface_grants OWNER TO postgres;

--
-- Name: report_no_products; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_no_products AS
 SELECT row_number() OVER () AS number,
    t.id,
    t.product_name,
    t.producer_name
   FROM ( SELECT pt.id,
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
                                  WHERE (document.id_document_category = 3))))) t_1
                     JOIN public.batch b ON ((b.id = t_1.id_batch)))
                  GROUP BY b.id_product
                 HAVING (sum(t_1.quantity) > 0)) l
             JOIN public.product pt ON ((pt.id = l.id)))
             JOIN public.producer pr ON ((pr.id = pt.id_producer)))
          ORDER BY pr.name, pt.name) t;


ALTER TABLE public.report_no_products OWNER TO postgres;

--
-- Name: report_non_fixed_batches; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_non_fixed_batches AS
 SELECT row_number() OVER () AS number,
    b.id AS id_batch,
    b.id_product,
    pt.name
   FROM ((public.batch b
     JOIN ( SELECT batch.id AS id_batch
           FROM public.batch
        EXCEPT
         SELECT DISTINCT document_content.id_batch
           FROM public.document_content) t ON ((b.id = t.id_batch)))
     JOIN public.product pt ON ((pt.id = b.id_product)));


ALTER TABLE public.report_non_fixed_batches OWNER TO postgres;

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
    t.id_product,
    t.product_name,
    t.producer_name,
    t.left_quantity
   FROM ( SELECT pt.id AS id_product,
            pt.name AS product_name,
            pr.name AS producer_name,
            COALESCE(l.product_left, (0)::bigint) AS left_quantity
           FROM ((( SELECT b.id_product,
                    sum(t_1.quantity) AS product_left
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
                                  WHERE (document.id_document_category = 3))))) t_1
                     JOIN public.batch b ON ((b.id = t_1.id_batch)))
                  GROUP BY b.id_product
                  ORDER BY (sum(t_1.quantity)) DESC) l
             RIGHT JOIN public.product pt ON ((pt.id = l.id_product)))
             JOIN public.producer pr ON ((pr.id = pt.id_producer)))
          ORDER BY COALESCE(l.product_left, (0)::bigint) DESC, pr.name) t;


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
                            WHEN (d.id_document_category = 1) THEN dc.quantity
                            ELSE NULL::integer
                        END) AS left_quantity
                   FROM (public.document_content dc
                     JOIN public.document d ON ((d.id = dc.id_document)))
                  GROUP BY dc.id_batch) t_1 ON ((t_1.id_batch = b.id)))
          ORDER BY COALESCE(t_1.left_quantity, (0)::bigint) DESC) t;


ALTER TABLE public.report_products_left_by_batch OWNER TO postgres;

--
-- Name: report_products_total_cost; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.report_products_total_cost AS
 SELECT row_number() OVER (ORDER BY GROUPING(b.id), pt.name) AS number,
    b.id AS batch_id,
    COALESCE(pt.name, 'ИТОГ'::character varying) AS product_name,
    b.cost,
    r.left_quantity,
    sum((b.cost * (r.left_quantity)::double precision)) AS total
   FROM ((public.report_products_left_by_batch r
     JOIN public.batch b ON ((r.id_batch = b.id)))
     JOIN public.product pt ON ((b.id_product = pt.id)))
  WHERE (r.left_quantity > 0)
  GROUP BY GROUPING SETS ((b.id, pt.name, b.cost, r.left_quantity), ())
  ORDER BY GROUPING(b.id), pt.name;


ALTER TABLE public.report_products_total_cost OWNER TO postgres;

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
17	Санкт-Петербург	Центральный	Санкт-Петербург	Невский проспект	12
18	Ленинградская область	Выборгский	Выборг	Ленинградская улица	7
19	Свердловская область	Екатеринбургский	Екатеринбург	Ленина	18
20	Краснодарский край	Центральный	Краснодар	Красная	33
21	Московская область	Химкинский	Химки	Ленинградская	5
22	Ростовская область	Ростовский	Ростов-на-Дону	Пушкинская	20
23	Самарская область	Самарский	Самара	Советская	44
24	Челябинская область	Челябинский	Челябинск	Космонавтов	3
25	Воронежская область	Центральный	Воронеж	Комсомольская	10
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, table_name, action, old_data, new_data, changed_by, changed_at) FROM stdin;
747	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008872100895552_7179111216.jpg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008872100895552_7179111216.jpg", "id_producer": 3, "id_product_category": 2}	admin	2025-12-10 13:42:35.186477
495	refresh_tokens	INSERT	\N	{"id": 113, "role": "manager", "token": "595cb504cdc827e0b54a79c43363c6a5e36fc89ff4a3380c5e4f4a7061f8eaf2", "username": "anna_sokolova", "created_at": "2025-12-09T12:36:19.952073"}	admin	2025-12-09 15:36:19.952073
525	refresh_tokens	DELETE	{"id": 128, "role": "admin", "token": "927ba55fb6bab277a3991a077ed5a43c46eb956c43e72934a6680242484fa3be", "username": "artem_volkov", "created_at": "2025-12-09T13:37:34.840008"}	\N	admin	2025-12-09 16:40:57.620994
526	refresh_tokens	INSERT	\N	{"id": 129, "role": "admin", "token": "ccaada3d84ce075c9ebb197bfeea9f74cb51ceb74dfec2794e9b2ec20daaedab", "username": "artem_volkov", "created_at": "2025-12-09T13:41:10.74989"}	admin	2025-12-09 16:41:10.74989
527	refresh_tokens	DELETE	{"id": 129, "role": "admin", "token": "ccaada3d84ce075c9ebb197bfeea9f74cb51ceb74dfec2794e9b2ec20daaedab", "username": "artem_volkov", "created_at": "2025-12-09T13:41:10.74989"}	\N	admin	2025-12-09 16:43:23.726001
528	refresh_tokens	INSERT	\N	{"id": 130, "role": "admin", "token": "8ad54b613d5d7694a1ad968fb776f139022f86f003968c41ba8d66f03a10efce", "username": "artem_volkov", "created_at": "2025-12-09T13:43:32.5289"}	admin	2025-12-09 16:43:32.5289
529	refresh_tokens	DELETE	{"id": 130, "role": "admin", "token": "8ad54b613d5d7694a1ad968fb776f139022f86f003968c41ba8d66f03a10efce", "username": "artem_volkov", "created_at": "2025-12-09T13:43:32.5289"}	\N	admin	2025-12-09 16:44:50.509753
530	refresh_tokens	INSERT	\N	{"id": 131, "role": "admin", "token": "d6b304c8674a25013dd8c1228ced960862ceabc710b0831d27ef476ca38c658a", "username": "artem_volkov", "created_at": "2025-12-09T13:45:01.131793"}	admin	2025-12-09 16:45:01.131793
531	refresh_tokens	DELETE	{"id": 131, "role": "admin", "token": "d6b304c8674a25013dd8c1228ced960862ceabc710b0831d27ef476ca38c658a", "username": "artem_volkov", "created_at": "2025-12-09T13:45:01.131793"}	\N	admin	2025-12-09 16:47:00.981174
532	refresh_tokens	INSERT	\N	{"id": 132, "role": "admin", "token": "724c36188f483e66d97b1d7ddf02c6582734ab9d69859af9f7558ee4d4c34bfc", "username": "artem_volkov", "created_at": "2025-12-09T13:50:33.351781"}	admin	2025-12-09 16:50:33.351781
533	refresh_tokens	DELETE	{"id": 132, "role": "admin", "token": "724c36188f483e66d97b1d7ddf02c6582734ab9d69859af9f7558ee4d4c34bfc", "username": "artem_volkov", "created_at": "2025-12-09T13:50:33.351781"}	\N	admin	2025-12-09 16:53:24.582317
534	refresh_tokens	INSERT	\N	{"id": 133, "role": "admin", "token": "cb3042ab51771d1d969d51b44ed9345ef211bd0694104ccbcc60e1cdf1c5b2c2", "username": "artem_volkov", "created_at": "2025-12-09T13:53:31.673132"}	admin	2025-12-09 16:53:31.673132
535	refresh_tokens	DELETE	{"id": 133, "role": "admin", "token": "cb3042ab51771d1d969d51b44ed9345ef211bd0694104ccbcc60e1cdf1c5b2c2", "username": "artem_volkov", "created_at": "2025-12-09T13:53:31.673132"}	\N	admin	2025-12-09 16:56:17.089649
536	refresh_tokens	INSERT	\N	{"id": 134, "role": "admin", "token": "e6e8b1ed73b6d646ade68a6f32269a08518b654890df4e6f20d348a063702630", "username": "artem_volkov", "created_at": "2025-12-09T13:56:25.525757"}	admin	2025-12-09 16:56:25.525757
537	refresh_tokens	DELETE	{"id": 134, "role": "admin", "token": "e6e8b1ed73b6d646ade68a6f32269a08518b654890df4e6f20d348a063702630", "username": "artem_volkov", "created_at": "2025-12-09T13:56:25.525757"}	\N	admin	2025-12-09 16:58:56.242879
538	refresh_tokens	INSERT	\N	{"id": 135, "role": "admin", "token": "2157dd8188715d6d02ef1ff582598d46f820bcb8fa3dd2f04fd1145490e418dd", "username": "artem_volkov", "created_at": "2025-12-09T14:00:20.767336"}	admin	2025-12-09 17:00:20.767336
654	refresh_tokens	DELETE	{"id": 181, "role": "admin", "token": "fc34f3e30d4f944ee1ebfc7a65204af20cf426f6590f5940665d7aaa3136d38d", "username": "artem_volkov", "created_at": "2025-12-10T08:27:25.754516"}	\N	admin	2025-12-10 12:27:59.018068
655	refresh_tokens	INSERT	\N	{"id": 184, "role": "admin", "token": "260f321ad83c08bae3f50f72a22aa90a04f4001d8e70a30b7ab0c1da368afcfd", "username": "artem_volkov", "created_at": "2025-12-10T09:27:59.032789"}	admin	2025-12-10 12:27:59.032789
656	position	UPDATE	{"id": 6, "name": "тест", "description": "тест"}	{"id": 6, "name": "тест", "description": "тес"}	admin	2025-12-10 12:34:24.705039
657	refresh_tokens	DELETE	{"id": 183, "role": "admin", "token": "d3029073b5bdd969dace00795bf615276e4f335c8ab493d9a62cd245f471187d", "username": "roman", "created_at": "2025-12-10T09:21:34.007808"}	\N	admin	2025-12-10 12:34:29.90664
658	refresh_tokens	INSERT	\N	{"id": 185, "role": "manager", "token": "fc9bd9901206160d89f64a4f20687598befe31e9e5c79183cb3ff66af7e54ce1", "username": "anna_sokolova", "created_at": "2025-12-10T09:34:37.725926"}	admin	2025-12-10 12:34:37.725926
663	position	DELETE	{"id": 6, "name": "тест", "description": "тес"}	\N	admin	2025-12-10 12:35:38.122646
689	position	INSERT	\N	{"id": 10, "name": "", "description": ""}	postgres	2025-12-10 14:42:16.624822
26	refresh_tokens	INSERT	\N	{"id": 21, "role": "admin", "token": "c4047bf1b6a35318377d1d62e8c017eae155bef3a323ba8b3749df0c8f6e1d4e", "username": "manager", "created_at": "2025-11-27T14:42:41.252856"}	admin	2025-11-27 17:42:41.252856
2	producer	UPDATE	{"id": 3, "inn": "8901234567", "name": "ООО \\"МикроТех\\"", "surname": "Белов", "firstname": "Дмитрий", "id_address": 8, "patronymic": "Игоревич"}	{"id": 3, "inn": "8901234567", "name": "ООО \\"МикроТех\\"", "surname": "Белочкин", "firstname": "Дмитрий", "id_address": 8, "patronymic": "Игоревич"}	postgres	2025-11-23 12:01:25.747191
3	refresh_tokens	INSERT	\N	{"id": 5, "role": "admin", "token": "cba4fd00c94d24c294c03e229c32c26a883f21d7b64090e1b4e8c84b7fea8d77", "username": "roman", "created_at": "2025-11-26T13:44:34.193637"}	admin	2025-11-26 16:44:34.193637
4	refresh_tokens	INSERT	\N	{"id": 6, "role": "admin", "token": "331f7d0e39b7208afda01cc0de9c9eee633ba0b8ab4e593ea5290ca95d978007", "username": "roman", "created_at": "2025-11-26T13:53:17.617212"}	admin	2025-11-26 16:53:17.617212
5	refresh_tokens	INSERT	\N	{"id": 7, "role": "admin", "token": "94b73e8c98bd3c09f277f15c0bc6b5d25bc139c87dc067cf3e1061a39b76c68a", "username": "roman", "created_at": "2025-11-26T13:53:20.513858"}	admin	2025-11-26 16:53:20.513858
6	refresh_tokens	INSERT	\N	{"id": 8, "role": "admin", "token": "49daff6915a3f11892764200b755529cf7a0e3835acce53083d255d6c0ec3229", "username": "roman", "created_at": "2025-11-26T13:53:21.423941"}	admin	2025-11-26 16:53:21.423941
35	refresh_tokens	INSERT	\N	{"id": 25, "role": "admin", "token": "9185d5b6e4de2a57af618f62cf5f5cde1719477e46834a4794941620275fe6ee", "username": "admin", "created_at": "2025-11-28T09:23:53.178776"}	admin	2025-11-28 12:23:53.178776
7	sys_user	UPDATE	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2b$12$A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0U1V2W3X4Y5Z6 "}	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$rgYYBEQoDW9f3dxPAgweruahkWXVL/EaX85oJaTY.SxpLHVhrRWsC"}	postgres	2025-11-26 17:10:46.647639
8	sys_user	UPDATE	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2b$12$L8Q9zR6nS2tV1WxY3Z4A7uB8C9D0E1F2G3H4I5J6K7L8M9N0O1P2Q"}	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$FVCCd92Vbpubj1004.Df8eVP4LVbyttxm1wXserInQnEbHcE5oFLm"}	postgres	2025-11-26 17:10:46.647639
9	refresh_tokens	INSERT	\N	{"id": 9, "role": "admin", "token": "943f03ab3a4f25a87cc71e5816dc1cadb987c215fb5ac55def363a9ee92bacbc", "username": "artem_volkov", "created_at": "2025-11-26T14:13:11.123677"}	admin	2025-11-26 17:13:11.123677
10	refresh_tokens	INSERT	\N	{"id": 10, "role": "admin", "token": "97c6bfd5e9067a095070646cebe2751d3b3a7ada884fa670f0e55146a89a1d62", "username": "artem_volkov", "created_at": "2025-11-26T14:13:39.912611"}	admin	2025-11-26 17:13:39.912611
11	refresh_tokens	DELETE	{"id": 10, "role": "admin", "token": "97c6bfd5e9067a095070646cebe2751d3b3a7ada884fa670f0e55146a89a1d62", "username": "artem_volkov", "created_at": "2025-11-26T14:13:39.912611"}	\N	admin	2025-11-26 17:14:54.969474
12	refresh_tokens	INSERT	\N	{"id": 11, "role": "admin", "token": "1cbe2f88d2f2ae7f9f9830c50708a987b72746beb26f69714c481d4b68b2a63c", "username": "artem_volkov", "created_at": "2025-11-26T14:19:15.076778"}	admin	2025-11-26 17:19:15.076778
13	refresh_tokens	INSERT	\N	{"id": 12, "role": "admin", "token": "4128f11f7639650ab58e66dc2de8c697259df3a0fff99ffefb1be1a135f82492", "username": "artem_volkov", "created_at": "2025-11-26T14:55:31.582029"}	admin	2025-11-26 17:55:31.582029
14	refresh_tokens	INSERT	\N	{"id": 13, "role": "admin", "token": "ca2cf4331fb90f0dba3b72d21b2619f4c94e05806e17cc725f32d31db19b9639", "username": "artem_volkov", "created_at": "2025-11-26T15:00:45.651163"}	admin	2025-11-26 18:00:45.651163
15	refresh_tokens	INSERT	\N	{"id": 14, "role": "admin", "token": "e69760612a8e12fc6b4c594aa6c91d43f360c7f741c3dc8d47a2b1f0d15d8012", "username": "artem_volkov", "created_at": "2025-11-27T06:29:01.211081"}	admin	2025-11-27 09:29:01.211081
16	sys_user	INSERT	\N	{"id": 4, "login": "manager", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	postgres	2025-11-27 09:41:25.719506
17	sys_user	INSERT	\N	{"id": 5, "login": "moderator", "id_role": 2, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	postgres	2025-11-27 09:41:25.719506
18	sys_user	UPDATE	{"id": 5, "login": "moderator", "id_role": 2, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	{"id": 5, "login": "moderator", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	postgres	2025-11-27 09:41:43.393199
19	refresh_tokens	INSERT	\N	{"id": 15, "role": "manager", "token": "a64ab6b5588249005d97f3620ffa83f3b6e2bf03e19463a0e5bffb667533caee", "username": "manager", "created_at": "2025-11-27T06:55:11.668623"}	manager	2025-11-27 09:55:11.668623
20	refresh_tokens	INSERT	\N	{"id": 16, "role": "admin", "token": "938f447ec5bcc121a17ef5df648da8e40e4806bdae73462c2579e066e8d442a2", "username": "artem_volkov", "created_at": "2025-11-27T06:56:30.238745"}	admin	2025-11-27 09:56:30.238745
21	refresh_tokens	INSERT	\N	{"id": 17, "role": "admin", "token": "10c6f457d5a4eea17421afbb0ba546956096905abded10a241a1330e31f1bf7a", "username": "artem_volkov", "created_at": "2025-11-27T07:09:46.021445"}	admin	2025-11-27 10:09:46.021445
22	refresh_tokens	INSERT	\N	{"id": 18, "role": "manager", "token": "25d631c35949d6aea6bda090c8ba45265658fe0c16e37f0247e95e23c3f66776", "username": "manager", "created_at": "2025-11-27T07:12:43.617149"}	manager	2025-11-27 10:12:43.617149
23	refresh_tokens	INSERT	\N	{"id": 19, "role": "manager", "token": "d369e960e74a00713ba90203a693fb21b2dda030689c52e1f698337c44a0980c", "username": "manager", "created_at": "2025-11-27T07:12:46.164956"}	manager	2025-11-27 10:12:46.164956
24	refresh_tokens	INSERT	\N	{"id": 20, "role": "manager", "token": "5e6ba8e70891f90d174244ec3b80300f862a88a1116ccc2bfcdf19d4f73284e8", "username": "manager", "created_at": "2025-11-27T12:46:28.835829"}	manager	2025-11-27 15:46:28.835829
25	refresh_tokens	DELETE	{"id": 20, "role": "manager", "token": "5e6ba8e70891f90d174244ec3b80300f862a88a1116ccc2bfcdf19d4f73284e8", "username": "manager", "created_at": "2025-11-27T12:46:28.835829"}	\N	admin	2025-11-27 17:41:24.553096
27	employee	INSERT	\N	{"id": 8, "inn": "111111111111", "surname": "test", "firstname": "test", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test", "id_position": 1, "phone_number": "1111111111111111"}	postgres	2025-11-27 18:27:41.815369
28	sys_user	INSERT	\N	{"id": 6, "login": "admin", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	postgres	2025-11-27 18:37:02.562526
225	document_category	DELETE	{"id": 4, "name": "test2", "description": "test1"}	\N	admin	2025-12-08 13:30:59.11395
29	refresh_tokens	INSERT	\N	{"id": 22, "role": "admin", "token": "a439faab054f288efe9c5355a01d02d21d61615c60a760b5aa0a7817e3de8413", "username": "admin", "created_at": "2025-11-27T15:37:15.190072"}	admin	2025-11-27 18:37:15.190072
30	employee	DELETE	{"id": 8, "inn": "111111111111", "surname": "test", "firstname": "test", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test", "id_position": 1, "phone_number": "1111111111111111"}	\N	admin	2025-11-27 18:37:29.955842
31	employee	INSERT	\N	{"id": 9, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-27 19:11:16.739013
32	employee	DELETE	{"id": 9, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	\N	admin	2025-11-27 19:11:29.296145
33	refresh_tokens	INSERT	\N	{"id": 23, "role": "admin", "token": "a64188161c526a29d54cf5007846a90dd8dd9567e8fed04aaa2a2a46dfb26ba8", "username": "admin", "created_at": "2025-11-28T08:31:54.748409"}	admin	2025-11-28 11:31:54.748409
34	refresh_tokens	INSERT	\N	{"id": 24, "role": "admin", "token": "4641efb53de98e5bb5a3c97adb117e1336bd4b8ed70e5178d649132074425e5a", "username": "manager", "created_at": "2025-11-28T08:32:56.011581"}	admin	2025-11-28 11:32:56.011581
36	employee	INSERT	\N	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 12:25:01.630915
37	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 12:28:41.22616
38	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 12:32:47.599062
39	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 2, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-28 12:33:46.830059
40	refresh_tokens	DELETE	{"id": 25, "role": "admin", "token": "9185d5b6e4de2a57af618f62cf5f5cde1719477e46834a4794941620275fe6ee", "username": "admin", "created_at": "2025-11-28T09:23:53.178776"}	\N	admin	2025-11-28 14:56:11.112342
41	refresh_tokens	INSERT	\N	{"id": 26, "role": "admin", "token": "c93bd7b4e8e4f62db2eb2435e4e3ad002f45038ac88d01afb8e110d3065a186a", "username": "admin", "created_at": "2025-11-30T07:12:15.150566"}	admin	2025-11-30 10:12:15.150566
42	refresh_tokens	DELETE	{"id": 26, "role": "admin", "token": "c93bd7b4e8e4f62db2eb2435e4e3ad002f45038ac88d01afb8e110d3065a186a", "username": "admin", "created_at": "2025-11-30T07:12:15.150566"}	\N	admin	2025-11-30 10:12:48.338728
43	refresh_tokens	INSERT	\N	{"id": 27, "role": "admin", "token": "00633a60c1c4944e9f0d4fa9c1d42bab3dc4285613dfe830d2ca69ef64b2b4b1", "username": "manager", "created_at": "2025-11-30T07:32:39.664678"}	admin	2025-11-30 10:32:39.664678
44	refresh_tokens	INSERT	\N	{"id": 28, "role": "admin", "token": "05910c7f2a0f650e7dc2d80ba4d7466d45678aa6e33ee453585057d99df4816b", "username": "manager", "created_at": "2025-11-30T07:44:25.200399"}	admin	2025-11-30 10:44:25.200399
45	refresh_tokens	INSERT	\N	{"id": 29, "role": "admin", "token": "4944a01c570ddec78e028f48feb8c643e7f92a8f0813589b327a15ef091cd3a7", "username": "manager", "created_at": "2025-11-30T08:28:43.838285"}	admin	2025-11-30 11:28:43.838285
46	refresh_tokens	DELETE	{"id": 29, "role": "admin", "token": "4944a01c570ddec78e028f48feb8c643e7f92a8f0813589b327a15ef091cd3a7", "username": "manager", "created_at": "2025-11-30T08:28:43.838285"}	\N	admin	2025-11-30 11:29:08.314482
47	refresh_tokens	INSERT	\N	{"id": 30, "role": "admin", "token": "bdbe5123c0c8105880407442d94f5fbc00fe05e5d312bf5686d3d08024f74177", "username": "manager", "created_at": "2025-11-30T08:29:08.316015"}	admin	2025-11-30 11:29:08.316015
48	refresh_tokens	INSERT	\N	{"id": 31, "role": "admin", "token": "c1ac4cc5bb8c027547a5283e87b77b0063fa9c98a530ab0dbb975155b412a826", "username": "admin", "created_at": "2025-11-30T08:29:21.472275"}	admin	2025-11-30 11:29:21.472275
49	refresh_tokens	DELETE	{"id": 31, "role": "admin", "token": "c1ac4cc5bb8c027547a5283e87b77b0063fa9c98a530ab0dbb975155b412a826", "username": "admin", "created_at": "2025-11-30T08:29:21.472275"}	\N	admin	2025-11-30 11:29:34.610208
50	refresh_tokens	INSERT	\N	{"id": 32, "role": "admin", "token": "e5269021174b218ab7dfc0c09d02446c7e085ef7fbddcf31bf7cc79a15ed6adb", "username": "admin", "created_at": "2025-11-30T08:29:34.611839"}	admin	2025-11-30 11:29:34.611839
51	refresh_tokens	INSERT	\N	{"id": 33, "role": "admin", "token": "81b2147712dcf76a6e615617874b617c0ab35ba65e7847b58843a041e5ff2b24", "username": "admin", "created_at": "2025-11-30T08:29:50.245921"}	admin	2025-11-30 11:29:50.245921
52	refresh_tokens	DELETE	{"id": 33, "role": "admin", "token": "81b2147712dcf76a6e615617874b617c0ab35ba65e7847b58843a041e5ff2b24", "username": "admin", "created_at": "2025-11-30T08:29:50.245921"}	\N	admin	2025-11-30 11:29:55.69218
53	refresh_tokens	INSERT	\N	{"id": 34, "role": "admin", "token": "76fb8be14f37a849518a794e50331f186c0223a77ecf23066d607b95761ccfe8", "username": "admin", "created_at": "2025-11-30T08:29:55.693487"}	admin	2025-11-30 11:29:55.693487
54	refresh_tokens	DELETE	{"id": 34, "role": "admin", "token": "76fb8be14f37a849518a794e50331f186c0223a77ecf23066d607b95761ccfe8", "username": "admin", "created_at": "2025-11-30T08:29:55.693487"}	\N	admin	2025-11-30 11:30:00.359268
55	refresh_tokens	INSERT	\N	{"id": 35, "role": "admin", "token": "5f080e2de4dfc45315af118571437281d9e155efb1a07923011e07c3fc02ff26", "username": "admin", "created_at": "2025-11-30T08:30:00.360945"}	admin	2025-11-30 11:30:00.360945
56	refresh_tokens	INSERT	\N	{"id": 36, "role": "admin", "token": "40f18e21f80e0537f54f0f6b7c21453d1df6f51bc597c4ec7140857c2ed5dae8", "username": "admin", "created_at": "2025-11-30T08:50:22.033023"}	admin	2025-11-30 11:50:22.033023
57	refresh_tokens	INSERT	\N	{"id": 37, "role": "admin", "token": "761e8ed6d58798c8f328573452961a1f237c1386ad6b9c810bc6d5dd9e3c45e1", "username": "manager", "created_at": "2025-11-30T08:50:52.604475"}	admin	2025-11-30 11:50:52.604475
58	refresh_tokens	DELETE	{"id": 36, "role": "admin", "token": "40f18e21f80e0537f54f0f6b7c21453d1df6f51bc597c4ec7140857c2ed5dae8", "username": "admin", "created_at": "2025-11-30T08:50:22.033023"}	\N	admin	2025-11-30 11:51:03.929454
59	refresh_tokens	INSERT	\N	{"id": 38, "role": "admin", "token": "52982be6dd3ff06f3b20aeb25ba5585f5364ee839a8d7a65dfe35f4a87083b49", "username": "admin", "created_at": "2025-11-30T08:51:03.931101"}	admin	2025-11-30 11:51:03.931101
60	refresh_tokens	DELETE	{"id": 37, "role": "admin", "token": "761e8ed6d58798c8f328573452961a1f237c1386ad6b9c810bc6d5dd9e3c45e1", "username": "manager", "created_at": "2025-11-30T08:50:52.604475"}	\N	admin	2025-11-30 11:51:10.605204
61	refresh_tokens	INSERT	\N	{"id": 39, "role": "admin", "token": "b0117da6b1b3be3dfd34e85852271cb9e48a79ccaa3b779bc020325c3437d1e8", "username": "manager", "created_at": "2025-11-30T08:51:10.606166"}	admin	2025-11-30 11:51:10.606166
62	refresh_tokens	INSERT	\N	{"id": 40, "role": "admin", "token": "17392d5f05da99a1c7f973738897a00c0cbdd79f877746176b9a65ac0abb702a", "username": "manager", "created_at": "2025-11-30T08:54:05.622474"}	admin	2025-11-30 11:54:05.622474
63	refresh_tokens	INSERT	\N	{"id": 41, "role": "admin", "token": "bd7032dfb7551d2712450e286d67f600cb561c58eccf00569a811e8664b0a23e", "username": "manager", "created_at": "2025-11-30T08:59:00.768525"}	admin	2025-11-30 11:59:00.768525
64	sys_user	UPDATE	{"id": 4, "login": "manager", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	{"id": 4, "login": "manager_login", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	postgres	2025-11-30 12:00:28.861994
65	sys_user	UPDATE	{"id": 5, "login": "moderator", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	{"id": 5, "login": "moderator_login", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	postgres	2025-11-30 12:00:28.861994
66	sys_user	UPDATE	{"id": 6, "login": "admin", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	{"id": 6, "login": "admin_login", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	postgres	2025-11-30 12:00:28.861994
67	refresh_tokens	INSERT	\N	{"id": 42, "role": "admin", "token": "7334f5e8a5206659e8bd9328af820fa885253a120e4a956724e0270921301d27", "username": "manager_login", "created_at": "2025-11-30T09:00:36.376971"}	admin	2025-11-30 12:00:36.376971
68	refresh_tokens	INSERT	\N	{"id": 43, "role": "manager", "token": "0e5d2ab8cd62d5bbdcc1c1c328592a282f3ed355e5ea0396c46183a971ba3d16", "username": "manager_login", "created_at": "2025-11-30T09:09:32.18135"}	admin	2025-11-30 12:09:32.18135
69	refresh_tokens	DELETE	{"id": 43, "role": "manager", "token": "0e5d2ab8cd62d5bbdcc1c1c328592a282f3ed355e5ea0396c46183a971ba3d16", "username": "manager_login", "created_at": "2025-11-30T09:09:32.18135"}	\N	admin	2025-11-30 12:09:53.258969
70	refresh_tokens	INSERT	\N	{"id": 44, "role": "manager", "token": "92227fe161a5dc011fe1525f513967eb7e4aca999423755e64ffdc57094c55cd", "username": "manager_login", "created_at": "2025-11-30T09:09:53.260424"}	admin	2025-11-30 12:09:53.260424
71	refresh_tokens	INSERT	\N	{"id": 45, "role": "manager", "token": "c1c1be46efb6a4a3fa21b8f3672a6c98c11e339c613240224c572620c817534b", "username": "manager_login", "created_at": "2025-11-30T09:11:04.226608"}	admin	2025-11-30 12:11:04.226608
72	refresh_tokens	DELETE	{"id": 45, "role": "manager", "token": "c1c1be46efb6a4a3fa21b8f3672a6c98c11e339c613240224c572620c817534b", "username": "manager_login", "created_at": "2025-11-30T09:11:04.226608"}	\N	admin	2025-11-30 12:11:19.489622
73	refresh_tokens	INSERT	\N	{"id": 46, "role": "manager", "token": "1386634e8bec9a32fb40ffd6fb22d4bd4786b2ea4da80c83d70dbe2ff5ed7cb9", "username": "manager_login", "created_at": "2025-11-30T09:11:19.491277"}	admin	2025-11-30 12:11:19.491277
74	refresh_tokens	INSERT	\N	{"id": 47, "role": "admin", "token": "05a78610e67b4982f84e54d1820eee7e7519820be5a952eac2eaf418ac446630", "username": "admin_login", "created_at": "2025-11-30T09:12:47.870291"}	admin	2025-11-30 12:12:47.870291
75	refresh_tokens	DELETE	{"id": 47, "role": "admin", "token": "05a78610e67b4982f84e54d1820eee7e7519820be5a952eac2eaf418ac446630", "username": "admin_login", "created_at": "2025-11-30T09:12:47.870291"}	\N	admin	2025-11-30 12:12:55.607542
76	refresh_tokens	INSERT	\N	{"id": 48, "role": "admin", "token": "2bf9eb0b8ed71a7ec7ef9c14eda3fb01bcb75a360850cd28b74edef015b19da4", "username": "admin_login", "created_at": "2025-11-30T09:12:55.60894"}	admin	2025-11-30 12:12:55.60894
77	employee	UPDATE	{"id": 10, "inn": "111111111111", "surname": "test1", "firstname": "test1", "id_gender": 1, "birth_date": "2025-11-27", "id_address": 1, "patronymic": "test1", "id_position": 1, "phone_number": "1111111111111111"}	{"id": 10, "inn": "111111111111", "surname": "test2", "firstname": "test2", "id_gender": 1, "birth_date": "2025-01-01", "id_address": 1, "patronymic": "test2", "id_position": 1, "phone_number": "1111111111111111"}	admin	2025-11-30 12:52:13.449175
78	refresh_tokens	DELETE	{"id": 46, "role": "manager", "token": "1386634e8bec9a32fb40ffd6fb22d4bd4786b2ea4da80c83d70dbe2ff5ed7cb9", "username": "manager_login", "created_at": "2025-11-30T09:11:19.491277"}	\N	admin	2025-11-30 13:14:31.80156
79	refresh_tokens	INSERT	\N	{"id": 49, "role": "manager", "token": "0ca9e2bb281bf54d371f929c5fde835b16f19e004694ab6b5ba36c7eafaebc3a", "username": "manager_login", "created_at": "2025-11-30T10:14:31.808879"}	admin	2025-11-30 13:14:31.808879
80	refresh_tokens	DELETE	{"id": 48, "role": "admin", "token": "2bf9eb0b8ed71a7ec7ef9c14eda3fb01bcb75a360850cd28b74edef015b19da4", "username": "admin_login", "created_at": "2025-11-30T09:12:55.60894"}	\N	admin	2025-11-30 13:17:10.982628
81	refresh_tokens	INSERT	\N	{"id": 50, "role": "admin", "token": "e0db01645df5afb701c0510f905218f930c18c04b4e73902eddcfbf974695d95", "username": "admin_login", "created_at": "2025-11-30T10:17:10.988637"}	admin	2025-11-30 13:17:10.988637
82	employee	INSERT	\N	{"id": 11, "inn": "222222222222", "surname": "a", "firstname": "a", "id_gender": 1, "birth_date": "0001-01-01", "id_address": 1, "patronymic": "a", "id_position": 1, "phone_number": "2222222222222222"}	admin	2025-11-30 13:17:35.035909
83	refresh_tokens	DELETE	{"id": 49, "role": "manager", "token": "0ca9e2bb281bf54d371f929c5fde835b16f19e004694ab6b5ba36c7eafaebc3a", "username": "manager_login", "created_at": "2025-11-30T10:14:31.808879"}	\N	admin	2025-11-30 13:53:00.543844
84	refresh_tokens	INSERT	\N	{"id": 51, "role": "manager", "token": "999efdf14db436045f5ea7b3db3ed280bba96529d03cdc215851bf200bf19ae1", "username": "manager_login", "created_at": "2025-11-30T10:53:00.554936"}	admin	2025-11-30 13:53:00.554936
85	refresh_tokens	DELETE	{"id": 51, "role": "manager", "token": "999efdf14db436045f5ea7b3db3ed280bba96529d03cdc215851bf200bf19ae1", "username": "manager_login", "created_at": "2025-11-30T10:53:00.554936"}	\N	admin	2025-11-30 15:22:42.514068
86	refresh_tokens	INSERT	\N	{"id": 52, "role": "manager", "token": "a7023d162a807bd39e0a90f0a43325a4750b0aecb9c91b49bd4fc8aaf68728bd", "username": "manager_login", "created_at": "2025-11-30T12:22:42.518898"}	admin	2025-11-30 15:22:42.518898
87	refresh_tokens	DELETE	{"id": 50, "role": "admin", "token": "e0db01645df5afb701c0510f905218f930c18c04b4e73902eddcfbf974695d95", "username": "admin_login", "created_at": "2025-11-30T10:17:10.988637"}	\N	admin	2025-11-30 15:22:49.495698
88	refresh_tokens	INSERT	\N	{"id": 53, "role": "admin", "token": "99a9fa7fed06cbfe236377fe27d65480720596cdbc696a0f23526b2026de2a31", "username": "admin_login", "created_at": "2025-11-30T12:22:49.496807"}	admin	2025-11-30 15:22:49.496807
89	refresh_tokens	DELETE	{"id": 53, "role": "admin", "token": "99a9fa7fed06cbfe236377fe27d65480720596cdbc696a0f23526b2026de2a31", "username": "admin_login", "created_at": "2025-11-30T12:22:49.496807"}	\N	admin	2025-11-30 16:28:02.642445
90	refresh_tokens	INSERT	\N	{"id": 54, "role": "admin", "token": "0ba0631536e9d23048183e6997fc134ee1d0bb72d71e61839082719e908987e4", "username": "admin_login", "created_at": "2025-11-30T13:28:02.648157"}	admin	2025-11-30 16:28:02.648157
91	refresh_tokens	DELETE	{"id": 52, "role": "manager", "token": "a7023d162a807bd39e0a90f0a43325a4750b0aecb9c91b49bd4fc8aaf68728bd", "username": "manager_login", "created_at": "2025-11-30T12:22:42.518898"}	\N	admin	2025-11-30 16:30:38.49293
92	refresh_tokens	INSERT	\N	{"id": 55, "role": "manager", "token": "dc8a9108bc26c647475fef62c219badb9d99dee14dce0e19280f033eced13cbd", "username": "manager_login", "created_at": "2025-11-30T13:30:38.501962"}	admin	2025-11-30 16:30:38.501962
93	batch	INSERT	\N	{"id": 8, "cost": 1, "created_at": "2025-11-30T14:27:02.406452", "id_product": 1, "expiration_date": "2025-11-30", "production_date": "2025-11-30"}	postgres	2025-11-30 17:27:02.406452
94	batch	UPDATE	{"id": 8, "cost": 1, "created_at": "2025-11-30T14:27:02.406452", "id_product": 1, "expiration_date": "2025-11-30", "production_date": "2025-11-30"}	{"id": 8, "cost": 2, "created_at": "2025-11-30T14:27:02.406452", "id_product": 1, "expiration_date": "2026-01-30", "production_date": "2025-10-30"}	postgres	2025-11-30 17:28:03.059234
95	batch	INSERT	\N	{"id": 9, "cost": 2, "created_at": "2025-11-30T14:28:46.581513", "id_product": 3, "expiration_date": "2025-12-30", "production_date": "2025-01-30"}	postgres	2025-11-30 17:28:46.581513
96	refresh_tokens	DELETE	{"id": 54, "role": "admin", "token": "0ba0631536e9d23048183e6997fc134ee1d0bb72d71e61839082719e908987e4", "username": "admin_login", "created_at": "2025-11-30T13:28:02.648157"}	\N	admin	2025-11-30 18:21:30.045022
97	refresh_tokens	INSERT	\N	{"id": 56, "role": "admin", "token": "271ee7e19922baa281276e15b39752405e7dea3b50df417a5c73288e3bdaae7c", "username": "admin_login", "created_at": "2025-11-30T15:21:30.050496"}	admin	2025-11-30 18:21:30.050496
98	batch	INSERT	\N	{"id": 10, "cost": 0, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-11-30", "production_date": "2025-11-29"}	admin	2025-11-30 18:25:23.003956
99	batch	UPDATE	{"id": 10, "cost": 0, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-11-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 18:33:52.860007
100	batch	UPDATE	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 18:34:26.726005
101	batch	UPDATE	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 18:35:04.669851
102	batch	UPDATE	{"id": 10, "cost": 100, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	{"id": 10, "cost": 10, "created_at": "2025-11-30T15:25:23.003956", "id_product": 4, "expiration_date": "2025-12-30", "production_date": "2025-11-29"}	admin	2025-11-30 18:35:21.497039
103	refresh_tokens	DELETE	{"id": 55, "role": "manager", "token": "dc8a9108bc26c647475fef62c219badb9d99dee14dce0e19280f033eced13cbd", "username": "manager_login", "created_at": "2025-11-30T13:30:38.501962"}	\N	admin	2025-11-30 19:43:14.956824
104	refresh_tokens	INSERT	\N	{"id": 57, "role": "manager", "token": "755f8c6b5d0b56badc69d2935a7e4f36def3dd84cddd5d2cafda1d34347385b9", "username": "manager_login", "created_at": "2025-11-30T16:43:14.962878"}	admin	2025-11-30 19:43:14.962878
105	refresh_tokens	INSERT	\N	{"id": 58, "role": "admin", "token": "1432d41450719516046bdd01c92fa06cd1d169c8790f023bf140f254cea812e1", "username": "admin_login", "created_at": "2025-12-01T06:06:31.197576"}	admin	2025-12-01 09:06:31.197576
106	refresh_tokens	DELETE	{"id": 58, "role": "admin", "token": "1432d41450719516046bdd01c92fa06cd1d169c8790f023bf140f254cea812e1", "username": "admin_login", "created_at": "2025-12-01T06:06:31.197576"}	\N	admin	2025-12-01 09:06:39.550254
107	refresh_tokens	INSERT	\N	{"id": 59, "role": "admin", "token": "211f8f489af394bc0e59d5d3e468bd64e6f00c4a5856556542ec87d45cb43f09", "username": "admin_login", "created_at": "2025-12-01T06:06:39.552779"}	admin	2025-12-01 09:06:39.552779
108	refresh_tokens	INSERT	\N	{"id": 60, "role": "manager", "token": "868852c8be49faa90ce107fc870fc4814895d8df77a4671723eeb69c902f4113", "username": "manager_login", "created_at": "2025-12-01T06:06:49.834222"}	admin	2025-12-01 09:06:49.834222
109	refresh_tokens	DELETE	{"id": 60, "role": "manager", "token": "868852c8be49faa90ce107fc870fc4814895d8df77a4671723eeb69c902f4113", "username": "manager_login", "created_at": "2025-12-01T06:06:49.834222"}	\N	admin	2025-12-01 09:06:58.816987
110	refresh_tokens	INSERT	\N	{"id": 61, "role": "manager", "token": "113415de5b947858e7bdcf797306349a9de999f368c0241232e5ee7848ce4bef", "username": "manager_login", "created_at": "2025-12-01T06:06:58.81918"}	admin	2025-12-01 09:06:58.81918
111	employee	INSERT	\N	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 6, "phone_number": "1111111111111111"}	postgres	2025-12-05 12:25:30.011977
112	sys_user	INSERT	\N	{"id": 7, "login": "valentin_admin", "id_role": 4, "id_employee": 14, "password_hash": "$2a$10$20LdgaOXwKGG9jQAJXDkMeIjzJo4jn5pMcr/Forby.IdMLDA9vuCK"}	postgres	2025-12-05 12:28:09.382849
113	refresh_tokens	INSERT	\N	{"id": 62, "role": "admin", "token": "88a6d1d348d14aef39c595b470446caf2a3e1579ca0c366f08bd776c3037da5b", "username": "valentin_admin", "created_at": "2025-12-05T09:28:35.024116"}	admin	2025-12-05 12:28:35.024116
114	refresh_tokens	INSERT	\N	{"id": 63, "role": "admin", "token": "d165cd4d7c9f627fe7fd2f7d99e642229e438b9ca9f713a331351e58a04fdef3", "username": "valentin_admin", "created_at": "2025-12-06T07:09:31.652981"}	admin	2025-12-06 10:09:31.652981
115	refresh_tokens	DELETE	{"id": 63, "role": "admin", "token": "d165cd4d7c9f627fe7fd2f7d99e642229e438b9ca9f713a331351e58a04fdef3", "username": "valentin_admin", "created_at": "2025-12-06T07:09:31.652981"}	\N	admin	2025-12-06 10:21:53.016154
116	refresh_tokens	INSERT	\N	{"id": 64, "role": "admin", "token": "08b3e5282f76f7fa9a7e960c15fe7d6b92dd4ee4e3ba41fd4fd0233d68dd7e4f", "username": "valentin_admin", "created_at": "2025-12-06T07:21:53.020384"}	admin	2025-12-06 10:21:53.020384
117	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "placeholder.png", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765007844082536256_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 10:57:24.084569
118	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765007844082536256_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008034406405720_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 11:00:34.408334
119	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008034406405720_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008060255653468_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 11:01:00.259002
120	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008060255653468_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008556902235503_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 11:09:16.903558
121	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/1765008556902235503_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008573472322094_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 11:09:33.475365
122	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008573472322094_бандитка.jpeg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008652953227464_p6.jpg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 11:10:52.953432
123	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008652953227464_p6.jpg", "id_producer": 3, "id_product_category": 3}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008872100895552_7179111216.jpg", "id_producer": 3, "id_product_category": 3}	admin	2025-12-06 11:14:32.10403
124	refresh_tokens	DELETE	{"id": 64, "role": "admin", "token": "08b3e5282f76f7fa9a7e960c15fe7d6b92dd4ee4e3ba41fd4fd0233d68dd7e4f", "username": "valentin_admin", "created_at": "2025-12-06T07:21:53.020384"}	\N	admin	2025-12-06 11:17:10.965933
125	refresh_tokens	INSERT	\N	{"id": 65, "role": "admin", "token": "0a09202fc2fad6bfd6311920a2b2acd6d856f95c8673e7fc078f003702c2c82a", "username": "valentin_admin", "created_at": "2025-12-06T08:17:10.972563"}	admin	2025-12-06 11:17:10.972563
126	refresh_tokens	DELETE	{"id": 65, "role": "admin", "token": "0a09202fc2fad6bfd6311920a2b2acd6d856f95c8673e7fc078f003702c2c82a", "username": "valentin_admin", "created_at": "2025-12-06T08:17:10.972563"}	\N	admin	2025-12-06 11:44:28.402223
127	refresh_tokens	INSERT	\N	{"id": 66, "role": "admin", "token": "3fd9b04bf172bfa89f3ffc55590387274cbe290739b02514dcae507528c257a6", "username": "valentin_admin", "created_at": "2025-12-06T08:44:28.410055"}	admin	2025-12-06 11:44:28.410055
128	refresh_tokens	DELETE	{"id": 66, "role": "admin", "token": "3fd9b04bf172bfa89f3ffc55590387274cbe290739b02514dcae507528c257a6", "username": "valentin_admin", "created_at": "2025-12-06T08:44:28.410055"}	\N	admin	2025-12-06 11:50:16.150939
245	document_content	INSERT	\N	{"id": 14, "id_batch": 3, "quantity": 500, "id_document": 1}	admin	2025-12-08 16:04:12.443516
129	refresh_tokens	INSERT	\N	{"id": 67, "role": "admin", "token": "00b14650f0f376d609bbb9f6bfa77b307d1938777cd07d8a450e5937b1433bdd", "username": "valentin_admin", "created_at": "2025-12-06T08:50:16.169089"}	admin	2025-12-06 11:50:16.169089
130	refresh_tokens	DELETE	{"id": 67, "role": "admin", "token": "00b14650f0f376d609bbb9f6bfa77b307d1938777cd07d8a450e5937b1433bdd", "username": "valentin_admin", "created_at": "2025-12-06T08:50:16.169089"}	\N	admin	2025-12-06 11:50:38.724637
131	refresh_tokens	INSERT	\N	{"id": 68, "role": "admin", "token": "625ccf489d78027be4e630c77554ed67a7b1bbdca458b55edd3f1d2730cac123", "username": "valentin_admin", "created_at": "2025-12-06T08:50:38.726435"}	admin	2025-12-06 11:50:38.726435
316	product	INSERT	\N	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
132	product	UPDATE	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "placeholder.png", "id_producer": 1, "id_product_category": 1}	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "/static/products/1765011046095675919_a4c7c78c78a454e231f7718718ae6195.jpg", "id_producer": 1, "id_product_category": 1}	admin	2025-12-06 11:50:46.097652
133	product	UPDATE	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "placeholder.png", "id_producer": 2, "id_product_category": 2}	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "/static/products/1765011070099983639_images (3).jpeg", "id_producer": 2, "id_product_category": 2}	admin	2025-12-06 11:51:10.100518
134	product	UPDATE	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "placeholder.png", "id_producer": 1, "id_product_category": 1}	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "/static/products/1765011089390225675_images (2).jpeg", "id_producer": 1, "id_product_category": 1}	admin	2025-12-06 11:51:29.391089
135	product	UPDATE	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "placeholder.png", "id_producer": 2, "id_product_category": 2}	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "/static/products/1765011109815931171_images.jpeg", "id_producer": 2, "id_product_category": 2}	admin	2025-12-06 11:51:49.816443
169	document	INSERT	\N	{"id": 8, "date": "2025-01-20", "id_employee": 2, "id_document_category": 2}	postgres	2025-12-06 16:49:52.765176
136	refresh_tokens	DELETE	{"id": 68, "role": "admin", "token": "625ccf489d78027be4e630c77554ed67a7b1bbdca458b55edd3f1d2730cac123", "username": "valentin_admin", "created_at": "2025-12-06T08:50:38.726435"}	\N	admin	2025-12-06 13:45:17.012505
137	refresh_tokens	INSERT	\N	{"id": 69, "role": "admin", "token": "e2752681b877f708f2747682bf6d221971b36044b54571bb810f80c071febdfc", "username": "valentin_admin", "created_at": "2025-12-06T10:45:17.019766"}	admin	2025-12-06 13:45:17.019766
138	refresh_tokens	DELETE	{"id": 62, "role": "admin", "token": "88a6d1d348d14aef39c595b470446caf2a3e1579ca0c366f08bd776c3037da5b", "username": "valentin_admin", "created_at": "2025-12-05T09:28:35.024116"}	\N	postgres	2025-12-06 13:45:56.560168
139	refresh_tokens	DELETE	{"id": 61, "role": "manager", "token": "113415de5b947858e7bdcf797306349a9de999f368c0241232e5ee7848ce4bef", "username": "manager_login", "created_at": "2025-12-01T06:06:58.81918"}	\N	postgres	2025-12-06 13:46:02.613549
140	refresh_tokens	DELETE	{"id": 59, "role": "admin", "token": "211f8f489af394bc0e59d5d3e468bd64e6f00c4a5856556542ec87d45cb43f09", "username": "admin_login", "created_at": "2025-12-01T06:06:39.552779"}	\N	postgres	2025-12-06 13:46:05.258675
141	refresh_tokens	DELETE	{"id": 57, "role": "manager", "token": "755f8c6b5d0b56badc69d2935a7e4f36def3dd84cddd5d2cafda1d34347385b9", "username": "manager_login", "created_at": "2025-11-30T16:43:14.962878"}	\N	postgres	2025-12-06 13:46:07.396837
142	refresh_tokens	DELETE	{"id": 56, "role": "admin", "token": "271ee7e19922baa281276e15b39752405e7dea3b50df417a5c73288e3bdaae7c", "username": "admin_login", "created_at": "2025-11-30T15:21:30.050496"}	\N	postgres	2025-12-06 13:46:10.713063
143	refresh_tokens	DELETE	{"id": 69, "role": "admin", "token": "e2752681b877f708f2747682bf6d221971b36044b54571bb810f80c071febdfc", "username": "valentin_admin", "created_at": "2025-12-06T10:45:17.019766"}	\N	admin	2025-12-06 13:57:31.554838
144	refresh_tokens	INSERT	\N	{"id": 70, "role": "admin", "token": "e5c4ea5d108bdc6cea4eab69ffbc853cec95969d0901318f7303d2a0b77d7a10", "username": "valentin_admin", "created_at": "2025-12-06T10:57:31.561397"}	admin	2025-12-06 13:57:31.561397
145	product	INSERT	\N	{"id": 6, "name": "Placeholder", "image_url": "", "id_producer": 2, "id_product_category": 3}	admin	2025-12-06 14:06:17.546029
146	product	UPDATE	{"id": 6, "name": "Placeholder", "image_url": "", "id_producer": 2, "id_product_category": 3}	{"id": 6, "name": "Placeholder", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 2, "id_product_category": 3}	admin	2025-12-06 14:07:53.080201
147	refresh_tokens	DELETE	{"id": 70, "role": "admin", "token": "e5c4ea5d108bdc6cea4eab69ffbc853cec95969d0901318f7303d2a0b77d7a10", "username": "valentin_admin", "created_at": "2025-12-06T10:57:31.561397"}	\N	admin	2025-12-06 14:13:40.134178
148	refresh_tokens	INSERT	\N	{"id": 71, "role": "admin", "token": "a9b1b3b18dfaf114916b28c16979fd19036e1fd667d8d4afa6e034854a99a98f", "username": "valentin_admin", "created_at": "2025-12-06T11:13:40.147373"}	admin	2025-12-06 14:13:40.147373
149	refresh_tokens	DELETE	{"id": 71, "role": "admin", "token": "a9b1b3b18dfaf114916b28c16979fd19036e1fd667d8d4afa6e034854a99a98f", "username": "valentin_admin", "created_at": "2025-12-06T11:13:40.147373"}	\N	admin	2025-12-06 14:19:39.251792
150	refresh_tokens	INSERT	\N	{"id": 72, "role": "admin", "token": "71b6adff68788397a0013731763f10d0d912fb78a33074e82115e78570b4312f", "username": "valentin_admin", "created_at": "2025-12-06T11:19:39.260462"}	admin	2025-12-06 14:19:39.260462
151	product	UPDATE	{"id": 6, "name": "Placeholder", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 2, "id_product_category": 3}	{"id": 6, "name": "Placehold", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 1, "id_product_category": 1}	admin	2025-12-06 14:19:46.529985
152	product	DELETE	{"id": 6, "name": "Placehold", "image_url": "/static/products/1765019273075046504_product-placeholder.png", "id_producer": 1, "id_product_category": 1}	\N	admin	2025-12-06 14:22:46.408884
153	refresh_tokens	DELETE	{"id": 72, "role": "admin", "token": "71b6adff68788397a0013731763f10d0d912fb78a33074e82115e78570b4312f", "username": "valentin_admin", "created_at": "2025-12-06T11:19:39.260462"}	\N	admin	2025-12-06 15:13:13.129492
154	refresh_tokens	INSERT	\N	{"id": 73, "role": "admin", "token": "f664ffe1be2eccda7122c8c3c18572a69535fdf8aa0ce2b28d15e5255110c895", "username": "valentin_admin", "created_at": "2025-12-06T12:13:13.133744"}	admin	2025-12-06 15:13:13.133744
155	product_category	INSERT	\N	{"id": 4, "name": "тест"}	postgres	2025-12-06 15:28:08.279316
156	refresh_tokens	DELETE	{"id": 73, "role": "admin", "token": "f664ffe1be2eccda7122c8c3c18572a69535fdf8aa0ce2b28d15e5255110c895", "username": "valentin_admin", "created_at": "2025-12-06T12:13:13.133744"}	\N	admin	2025-12-06 15:28:20.146233
157	refresh_tokens	INSERT	\N	{"id": 74, "role": "admin", "token": "b947f9a86494edabc7c731e319d938aa1bd9a7d34cc5260c21cbefb09401ce5b", "username": "valentin_admin", "created_at": "2025-12-06T12:28:20.148218"}	admin	2025-12-06 15:28:20.148218
158	product_category	DELETE	{"id": 4, "name": "тест"}	\N	admin	2025-12-06 15:36:05.680591
716	product	DELETE	{"id": 57, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	\N	postgres	2025-12-10 15:56:38.90379
159	refresh_tokens	DELETE	{"id": 74, "role": "admin", "token": "b947f9a86494edabc7c731e319d938aa1bd9a7d34cc5260c21cbefb09401ce5b", "username": "valentin_admin", "created_at": "2025-12-06T12:28:20.148218"}	\N	admin	2025-12-06 16:11:28.205135
160	refresh_tokens	INSERT	\N	{"id": 75, "role": "admin", "token": "f7737d326e65a407c96a7dcdfff78370597e8ee38c7f83e3ec738668ffd5be69", "username": "valentin_admin", "created_at": "2025-12-06T13:11:28.212287"}	admin	2025-12-06 16:11:28.212287
161	product_category	INSERT	\N	{"id": 5, "name": "Посуда"}	admin	2025-12-06 16:13:59.849689
162	product_category	DELETE	{"id": 5, "name": "Посуда"}	\N	admin	2025-12-06 16:14:57.003044
163	product_category	INSERT	\N	{"id": 7, "name": "Посуда"}	admin	2025-12-06 16:15:02.663377
164	product_category	UPDATE	{"id": 7, "name": "Посуда"}	{"id": 7, "name": "Placeholder"}	admin	2025-12-06 16:18:39.759869
165	product_category	DELETE	{"id": 7, "name": "Placeholder"}	\N	admin	2025-12-06 16:20:09.886505
166	batch	INSERT	\N	{"id": 11, "cost": 134, "created_at": "2025-12-06T13:45:45.295078", "id_product": 3, "expiration_date": "2024-12-05", "production_date": "2024-12-06"}	postgres	2025-12-06 16:45:45.295078
167	document	INSERT	\N	{"id": 7, "date": "2024-12-23", "id_employee": 1, "id_document_category": 1}	postgres	2025-12-06 16:46:25.303401
168	document_content	INSERT	\N	{"id": 12, "id_batch": 11, "quantity": 100, "id_product": 1, "id_document": 7}	postgres	2025-12-06 16:47:12.80487
170	document_content	INSERT	\N	{"id": 13, "id_batch": 11, "quantity": 37, "id_document": 8}	postgres	2025-12-06 16:50:08.846909
171	producer	INSERT	\N	{"id": 4, "inn": "1234323858", "name": "ИП \\"Михайлов\\"", "surname": "Михайлов", "firstname": "Роман", "id_address": 1, "patronymic": "Александрович"}	postgres	2025-12-06 17:19:30.631278
172	producer	INSERT	\N	{"id": 5, "inn": "5467823934", "name": "АО \\"АвтоВлад\\"", "surname": "Судный", "firstname": "Максим", "id_address": 6, "patronymic": "Рэмович"}	postgres	2025-12-06 17:20:51.176793
173	refresh_tokens	INSERT	\N	{"id": 76, "role": "manager", "token": "9c3dc39afb2dffead0a18529248d58cbcab217e3f9606c8ac3886e4a15d66992", "username": "manager_login", "created_at": "2025-12-07T06:52:48.444446"}	admin	2025-12-07 09:52:48.444446
174	product_category	INSERT	\N	{"id": 8, "name": "Посуда"}	manager	2025-12-07 09:52:57.435728
175	refresh_tokens	DELETE	{"id": 75, "role": "admin", "token": "f7737d326e65a407c96a7dcdfff78370597e8ee38c7f83e3ec738668ffd5be69", "username": "valentin_admin", "created_at": "2025-12-06T13:11:28.212287"}	\N	admin	2025-12-07 13:37:52.83045
176	refresh_tokens	INSERT	\N	{"id": 77, "role": "admin", "token": "c1fc0c5a81402767019b601eece71c0bee2060bc7b0819a3a40ec8760f4f1dd0", "username": "valentin_admin", "created_at": "2025-12-07T10:37:52.836468"}	admin	2025-12-07 13:37:52.836468
177	refresh_tokens	DELETE	{"id": 77, "role": "admin", "token": "c1fc0c5a81402767019b601eece71c0bee2060bc7b0819a3a40ec8760f4f1dd0", "username": "valentin_admin", "created_at": "2025-12-07T10:37:52.836468"}	\N	admin	2025-12-07 14:21:40.196783
178	refresh_tokens	INSERT	\N	{"id": 78, "role": "admin", "token": "e4dc483a873c06e0d2e4ed11c67e19940b2fd65e5a96de4a06c37f3e913fa32f", "username": "valentin_admin", "created_at": "2025-12-07T11:21:40.205741"}	admin	2025-12-07 14:21:40.205741
179	refresh_tokens	DELETE	{"id": 78, "role": "admin", "token": "e4dc483a873c06e0d2e4ed11c67e19940b2fd65e5a96de4a06c37f3e913fa32f", "username": "valentin_admin", "created_at": "2025-12-07T11:21:40.205741"}	\N	admin	2025-12-07 15:24:33.991088
180	refresh_tokens	INSERT	\N	{"id": 79, "role": "admin", "token": "5d6088bcee48fed7ef4f35785a47e9f5c80b281585474e624216d5567ce1f849", "username": "valentin_admin", "created_at": "2025-12-07T12:24:33.996466"}	admin	2025-12-07 15:24:33.996466
181	refresh_tokens	DELETE	{"id": 79, "role": "admin", "token": "5d6088bcee48fed7ef4f35785a47e9f5c80b281585474e624216d5567ce1f849", "username": "valentin_admin", "created_at": "2025-12-07T12:24:33.996466"}	\N	admin	2025-12-07 15:56:31.462401
182	refresh_tokens	INSERT	\N	{"id": 80, "role": "admin", "token": "7c1a2e545f5ededc4d9880eb8f58b979382301a7d3aa4d6a3dd45f8afe30324d", "username": "valentin_admin", "created_at": "2025-12-07T12:56:31.477525"}	admin	2025-12-07 15:56:31.477525
183	product_category	INSERT	\N	{"id": 9, "name": "test"}	admin	2025-12-07 15:57:36.228564
184	product_category	DELETE	{"id": 9, "name": "test"}	\N	admin	2025-12-07 15:57:48.399966
185	producer	INSERT	\N	{"id": 6, "inn": "0123456789", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	admin	2025-12-07 16:00:02.180802
186	producer	INSERT	\N	{"id": 8, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	admin	2025-12-07 16:00:32.393072
187	producer	DELETE	{"id": 6, "inn": "0123456789", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	\N	admin	2025-12-07 16:00:50.680936
188	producer	DELETE	{"id": 8, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	\N	admin	2025-12-07 16:00:52.822328
189	producer	INSERT	\N	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	admin	2025-12-07 16:02:58.491127
246	document_content	UPDATE	{"id": 1, "id_batch": 1, "quantity": 5, "id_document": 1}	{"id": 1, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
190	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 3, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:04:35.023077
191	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:04:54.609017
192	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:02.922873
193	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:07.393071
194	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:08.305619
195	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:08.967501
196	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:09.667729
197	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:10.296162
224	document_category	UPDATE	{"id": 4, "name": "test", "description": "test"}	{"id": 4, "name": "test2", "description": "test1"}	admin	2025-12-08 13:30:45.594678
198	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:10.885358
199	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:11.468342
200	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:12.044059
201	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:12.581566
202	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:13.147355
203	producer	UPDATE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	admin	2025-12-07 16:05:25.994683
204	producer	DELETE	{"id": 9, "inn": "0123456790", "name": "test", "surname": "test", "firstname": "test", "id_address": 1, "patronymic": "test"}	\N	admin	2025-12-07 16:05:43.99447
205	refresh_tokens	DELETE	{"id": 80, "role": "admin", "token": "7c1a2e545f5ededc4d9880eb8f58b979382301a7d3aa4d6a3dd45f8afe30324d", "username": "valentin_admin", "created_at": "2025-12-07T12:56:31.477525"}	\N	admin	2025-12-07 18:58:22.542464
206	refresh_tokens	INSERT	\N	{"id": 81, "role": "admin", "token": "05a775164a2c23a61825345f0ef0148e7a2d0b2f88f800bc9410f4e097b2fd2e", "username": "valentin_admin", "created_at": "2025-12-07T15:58:22.553163"}	admin	2025-12-07 18:58:22.553163
207	position	INSERT	\N	{"id": 7, "name": "temp", "description": "temp"}	postgres	2025-12-07 19:39:01.00384
208	position	DELETE	{"id": 7, "name": "temp", "description": "temp"}	\N	admin	2025-12-07 19:40:24.739229
209	refresh_tokens	DELETE	{"id": 81, "role": "admin", "token": "05a775164a2c23a61825345f0ef0148e7a2d0b2f88f800bc9410f4e097b2fd2e", "username": "valentin_admin", "created_at": "2025-12-07T15:58:22.553163"}	\N	admin	2025-12-07 20:00:49.515657
210	refresh_tokens	INSERT	\N	{"id": 82, "role": "admin", "token": "a98b217c5f9c872538b892fd1f04f1de079a78efb8a889b1846e9a777c95406b", "username": "valentin_admin", "created_at": "2025-12-07T17:00:49.523404"}	admin	2025-12-07 20:00:49.523404
211	position	INSERT	\N	{"id": 8, "name": "test", "description": "test"}	admin	2025-12-07 20:04:10.541119
212	position	UPDATE	{"id": 8, "name": "test", "description": "test"}	{"id": 8, "name": "test21", "description": "test12"}	admin	2025-12-07 20:04:44.881632
213	position	DELETE	{"id": 8, "name": "test21", "description": "test12"}	\N	admin	2025-12-07 20:04:56.548691
214	refresh_tokens	DELETE	{"id": 82, "role": "admin", "token": "a98b217c5f9c872538b892fd1f04f1de079a78efb8a889b1846e9a777c95406b", "username": "valentin_admin", "created_at": "2025-12-07T17:00:49.523404"}	\N	admin	2025-12-08 11:48:33.604689
215	refresh_tokens	INSERT	\N	{"id": 83, "role": "admin", "token": "050bc96f21cc7f36a74602bdd3b1973cde806c1c477f0df19b78c7bc8c7cf160", "username": "valentin_admin", "created_at": "2025-12-08T08:48:33.615528"}	admin	2025-12-08 11:48:33.615528
247	document_content	UPDATE	{"id": 2, "id_batch": 2, "quantity": 3, "id_document": 1}	{"id": 2, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
216	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 6, "phone_number": "1111111111111111"}	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	admin	2025-12-08 11:55:13.264927
217	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	admin	2025-12-08 11:56:52.388334
218	refresh_tokens	DELETE	{"id": 83, "role": "admin", "token": "050bc96f21cc7f36a74602bdd3b1973cde806c1c477f0df19b78c7bc8c7cf160", "username": "valentin_admin", "created_at": "2025-12-08T08:48:33.615528"}	\N	admin	2025-12-08 13:12:36.200916
717	product	DELETE	{"id": 58, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	\N	postgres	2025-12-10 15:56:41.017452
219	refresh_tokens	INSERT	\N	{"id": 84, "role": "admin", "token": "77bb2a9b4c761f6fd7554e05bd812b9109b6e221345f9ddddb95f965a006a025", "username": "valentin_admin", "created_at": "2025-12-08T10:12:36.205304"}	admin	2025-12-08 13:12:36.205304
220	address	INSERT	\N	{"id": 16, "city": "test", "region": "test", "street": "test", "subject": "test", "building": 12}	admin	2025-12-08 13:14:36.338868
221	address	UPDATE	{"id": 16, "city": "test", "region": "test", "street": "test", "subject": "test", "building": 12}	{"id": 16, "city": "test1", "region": "test2", "street": "test0", "subject": "test3", "building": 1}	admin	2025-12-08 13:15:12.944608
222	address	DELETE	{"id": 16, "city": "test1", "region": "test2", "street": "test0", "subject": "test3", "building": 1}	\N	admin	2025-12-08 13:15:33.070826
223	document_category	INSERT	\N	{"id": 4, "name": "test", "description": "test"}	admin	2025-12-08 13:30:18.348391
226	refresh_tokens	DELETE	{"id": 84, "role": "admin", "token": "77bb2a9b4c761f6fd7554e05bd812b9109b6e221345f9ddddb95f965a006a025", "username": "valentin_admin", "created_at": "2025-12-08T10:12:36.205304"}	\N	admin	2025-12-08 14:14:54.610279
227	refresh_tokens	INSERT	\N	{"id": 85, "role": "admin", "token": "f12fb44c074cb932351aa7ac412c1ca16f873da98bf45e6c8eda93ec205291c2", "username": "valentin_admin", "created_at": "2025-12-08T11:14:54.619104"}	admin	2025-12-08 14:14:54.619104
228	refresh_tokens	DELETE	{"id": 85, "role": "admin", "token": "f12fb44c074cb932351aa7ac412c1ca16f873da98bf45e6c8eda93ec205291c2", "username": "valentin_admin", "created_at": "2025-12-08T11:14:54.619104"}	\N	admin	2025-12-08 14:58:43.335946
229	refresh_tokens	INSERT	\N	{"id": 86, "role": "admin", "token": "1dd141264597581e199603c9597d659326c48069db263c7ae12e01c87fc0add6", "username": "valentin_admin", "created_at": "2025-12-08T11:58:43.343928"}	admin	2025-12-08 14:58:43.343928
230	refresh_tokens	DELETE	{"id": 86, "role": "admin", "token": "1dd141264597581e199603c9597d659326c48069db263c7ae12e01c87fc0add6", "username": "valentin_admin", "created_at": "2025-12-08T11:58:43.343928"}	\N	admin	2025-12-08 15:50:16.757027
231	refresh_tokens	INSERT	\N	{"id": 87, "role": "admin", "token": "2cb9cd6505793f0c14a9735c3336c3bf7f807d448511f006e67ee025799fcefc", "username": "valentin_admin", "created_at": "2025-12-08T12:50:16.763149"}	admin	2025-12-08 15:50:16.763149
232	document	INSERT	\N	{"id": 9, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	admin	2025-12-08 15:57:23.351389
233	document	DELETE	{"id": 9, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	\N	postgres	2025-12-08 15:58:13.057678
234	document	INSERT	\N	{"id": 10, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	admin	2025-12-08 15:58:16.556003
235	document	UPDATE	{"id": 1, "date": "2024-03-10", "id_employee": 2, "id_document_category": 1}	{"id": 1, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
236	document	UPDATE	{"id": 2, "date": "2024-03-18", "id_employee": 2, "id_document_category": 2}	{"id": 2, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
237	document	UPDATE	{"id": 3, "date": "2024-03-25", "id_employee": 2, "id_document_category": 3}	{"id": 3, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
238	document	UPDATE	{"id": 4, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	{"id": 4, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
239	document	UPDATE	{"id": 5, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	{"id": 5, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
240	document	UPDATE	{"id": 6, "date": "2025-11-22", "id_employee": 1, "id_document_category": 3}	{"id": 6, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
241	document	UPDATE	{"id": 7, "date": "2024-12-23", "id_employee": 1, "id_document_category": 1}	{"id": 7, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
242	document	UPDATE	{"id": 8, "date": "2025-01-20", "id_employee": 2, "id_document_category": 2}	{"id": 8, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
243	document	UPDATE	{"id": 10, "date": "2025-12-08", "id_employee": 2, "id_document_category": 1}	{"id": 10, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	admin	2025-12-08 15:59:25.342038
244	document	DELETE	{"id": 10, "date": "2025-10-08", "id_employee": 1, "id_document_category": 2}	\N	admin	2025-12-08 15:59:56.505616
248	document_content	UPDATE	{"id": 3, "id_batch": 3, "quantity": 10, "id_document": 1}	{"id": 3, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
249	document_content	UPDATE	{"id": 4, "id_batch": 4, "quantity": 15, "id_document": 1}	{"id": 4, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
250	document_content	UPDATE	{"id": 5, "id_batch": 5, "quantity": 2, "id_document": 1}	{"id": 5, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
251	document_content	UPDATE	{"id": 6, "id_batch": 1, "quantity": 4, "id_document": 2}	{"id": 6, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
252	document_content	UPDATE	{"id": 7, "id_batch": 4, "quantity": 3, "id_document": 2}	{"id": 7, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
253	document_content	UPDATE	{"id": 9, "id_batch": 3, "quantity": 2, "id_document": 3}	{"id": 9, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
254	document_content	UPDATE	{"id": 10, "id_batch": 4, "quantity": 1, "id_document": 3}	{"id": 10, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
255	document_content	UPDATE	{"id": 11, "id_batch": 5, "quantity": 1, "id_document": 3}	{"id": 11, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
256	document_content	UPDATE	{"id": 8, "id_batch": 5, "quantity": 2, "id_document": 2}	{"id": 8, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
257	document_content	UPDATE	{"id": 12, "id_batch": 11, "quantity": 100, "id_document": 7}	{"id": 12, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
258	document_content	UPDATE	{"id": 13, "id_batch": 11, "quantity": 37, "id_document": 8}	{"id": 13, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
259	document_content	UPDATE	{"id": 14, "id_batch": 3, "quantity": 500, "id_document": 1}	{"id": 14, "id_batch": 3, "quantity": 5000, "id_document": 1}	admin	2025-12-08 16:06:10.718255
260	document_content	DELETE	{"id": 14, "id_batch": 3, "quantity": 5000, "id_document": 1}	\N	admin	2025-12-08 16:06:26.943108
261	refresh_tokens	DELETE	{"id": 87, "role": "admin", "token": "2cb9cd6505793f0c14a9735c3336c3bf7f807d448511f006e67ee025799fcefc", "username": "valentin_admin", "created_at": "2025-12-08T12:50:16.763149"}	\N	admin	2025-12-08 17:24:58.373132
262	refresh_tokens	INSERT	\N	{"id": 88, "role": "admin", "token": "b1538156433473107447b1fd69239686c3de2b43fbd39bda93dc74612e3b6d54", "username": "valentin_admin", "created_at": "2025-12-08T14:24:58.383009"}	admin	2025-12-08 17:24:58.383009
263	document_content	UPDATE	{"id": 13, "id_batch": 3, "quantity": 5000, "id_document": 1}	{"id": 13, "id_batch": 3, "quantity": 500, "id_document": 1}	admin	2025-12-08 17:25:20.367266
264	document	INSERT	\N	{"id": 1, "date": "2024-03-10", "id_employee": 2, "id_document_category": 1}	postgres	2025-12-08 17:28:39.90088
265	document	INSERT	\N	{"id": 2, "date": "2024-03-18", "id_employee": 2, "id_document_category": 2}	postgres	2025-12-08 17:28:39.90088
266	document	INSERT	\N	{"id": 3, "date": "2024-03-25", "id_employee": 2, "id_document_category": 3}	postgres	2025-12-08 17:28:39.90088
267	document	INSERT	\N	{"id": 4, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	postgres	2025-12-08 17:28:39.90088
268	document	INSERT	\N	{"id": 5, "date": "2025-11-22", "id_employee": 1, "id_document_category": 1}	postgres	2025-12-08 17:28:39.90088
269	document	INSERT	\N	{"id": 6, "date": "2025-11-22", "id_employee": 1, "id_document_category": 3}	postgres	2025-12-08 17:28:39.90088
270	document_content	INSERT	\N	{"id": 1, "id_batch": 1, "quantity": 5, "id_document": 1}	postgres	2025-12-08 17:29:26.098872
271	document_content	INSERT	\N	{"id": 2, "id_batch": 2, "quantity": 3, "id_document": 1}	postgres	2025-12-08 17:29:26.098872
272	document_content	INSERT	\N	{"id": 3, "id_batch": 3, "quantity": 10, "id_document": 1}	postgres	2025-12-08 17:29:26.098872
273	document_content	INSERT	\N	{"id": 4, "id_batch": 4, "quantity": 15, "id_document": 1}	postgres	2025-12-08 17:29:26.098872
274	document_content	INSERT	\N	{"id": 5, "id_batch": 5, "quantity": 2, "id_document": 1}	postgres	2025-12-08 17:29:26.098872
275	document_content	INSERT	\N	{"id": 6, "id_batch": 1, "quantity": 4, "id_document": 2}	postgres	2025-12-08 17:29:26.098872
276	document_content	INSERT	\N	{"id": 7, "id_batch": 4, "quantity": 3, "id_document": 2}	postgres	2025-12-08 17:29:26.098872
277	document_content	INSERT	\N	{"id": 8, "id_batch": 5, "quantity": 2, "id_document": 2}	postgres	2025-12-08 17:29:26.098872
278	document_content	INSERT	\N	{"id": 9, "id_batch": 3, "quantity": 2, "id_document": 3}	postgres	2025-12-08 17:29:26.098872
279	document_content	INSERT	\N	{"id": 10, "id_batch": 4, "quantity": 1, "id_document": 3}	postgres	2025-12-08 17:29:26.098872
280	document_content	INSERT	\N	{"id": 11, "id_batch": 5, "quantity": 1, "id_document": 3}	postgres	2025-12-08 17:29:26.098872
281	refresh_tokens	DELETE	{"id": 88, "role": "admin", "token": "b1538156433473107447b1fd69239686c3de2b43fbd39bda93dc74612e3b6d54", "username": "valentin_admin", "created_at": "2025-12-08T14:24:58.383009"}	\N	admin	2025-12-08 17:54:21.532986
282	refresh_tokens	INSERT	\N	{"id": 89, "role": "admin", "token": "b3bc6fa09deb6ef0221bd9d5fda49b7e7ec6534fbc45bf4e34b31d9b8f6cebfa", "username": "valentin_admin", "created_at": "2025-12-08T14:54:21.536731"}	admin	2025-12-08 17:54:21.536731
283	refresh_tokens	DELETE	{"id": 89, "role": "admin", "token": "b3bc6fa09deb6ef0221bd9d5fda49b7e7ec6534fbc45bf4e34b31d9b8f6cebfa", "username": "valentin_admin", "created_at": "2025-12-08T14:54:21.536731"}	\N	admin	2025-12-08 15:36:55.445537
284	refresh_tokens	INSERT	\N	{"id": 90, "role": "admin", "token": "462baf2b63285c363b6d217eb1c9962adc2cb2495a269694c5a9691068b5abab", "username": "valentin_admin", "created_at": "2025-12-08T12:36:55.456698"}	admin	2025-12-08 15:36:55.456698
285	position	INSERT	\N	{"id": 9, "name": "Системный администратов", "description": "Администрирование информационной системой, полный доступ к ИС"}	admin	2025-12-08 15:37:02.343669
314	product	INSERT	\N	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
315	product	INSERT	\N	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
286	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "1111111111111111"}	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "1111111111111111"}	admin	2025-12-08 15:38:15.068513
287	sys_user	DELETE	{"id": 6, "login": "admin_login", "id_role": 4, "id_employee": 2, "password_hash": "$2a$10$0fBtSXi9CAHsY0i4TON2aeLRaeR1NTn9CENl.LkZbFEsJS.gsagmK"}	\N	admin	2025-12-08 15:41:58.580165
288	address	INSERT	\N	{"id": 17, "city": "Санкт-Петербург", "region": "Центральный", "street": "Невский проспект", "subject": "Санкт-Петербург", "building": 12}	postgres	2025-12-08 17:16:09.019164
289	address	INSERT	\N	{"id": 18, "city": "Выборг", "region": "Выборгский", "street": "Ленинградская улица", "subject": "Ленинградская область", "building": 7}	postgres	2025-12-08 17:16:09.019164
290	address	INSERT	\N	{"id": 19, "city": "Екатеринбург", "region": "Екатеринбургский", "street": "Ленина", "subject": "Свердловская область", "building": 18}	postgres	2025-12-08 17:16:09.019164
859	document_content	DELETE	{"id": 16, "id_batch": 1, "quantity": 10, "id_document": 12}	\N	postgres	2025-12-14 09:43:53.443618
291	address	INSERT	\N	{"id": 20, "city": "Краснодар", "region": "Центральный", "street": "Красная", "subject": "Краснодарский край", "building": 33}	postgres	2025-12-08 17:16:09.019164
292	address	INSERT	\N	{"id": 21, "city": "Химки", "region": "Химкинский", "street": "Ленинградская", "subject": "Московская область", "building": 5}	postgres	2025-12-08 17:16:09.019164
293	address	INSERT	\N	{"id": 22, "city": "Ростов-на-Дону", "region": "Ростовский", "street": "Пушкинская", "subject": "Ростовская область", "building": 20}	postgres	2025-12-08 17:16:09.019164
294	address	INSERT	\N	{"id": 23, "city": "Самара", "region": "Самарский", "street": "Советская", "subject": "Самарская область", "building": 44}	postgres	2025-12-08 17:16:09.019164
295	address	INSERT	\N	{"id": 24, "city": "Челябинск", "region": "Челябинский", "street": "Космонавтов", "subject": "Челябинская область", "building": 3}	postgres	2025-12-08 17:16:09.019164
296	address	INSERT	\N	{"id": 25, "city": "Воронеж", "region": "Центральный", "street": "Комсомольская", "subject": "Воронежская область", "building": 10}	postgres	2025-12-08 17:16:09.019164
297	producer	INSERT	\N	{"id": 18, "inn": "1234567890", "name": "ООО \\"ТехноДом\\"", "surname": "Иванов", "firstname": "Игорь", "id_address": 1, "patronymic": "Сергеевич"}	postgres	2025-12-08 17:16:58.286105
298	producer	INSERT	\N	{"id": 19, "inn": "2345678901", "name": "АО \\"СтройМебель\\"", "surname": "Петрова", "firstname": "Марина", "id_address": 2, "patronymic": "Владимировна"}	postgres	2025-12-08 17:16:58.286105
299	producer	INSERT	\N	{"id": 20, "inn": "3456789012", "name": "ООО \\"ЭлектроникСистем\\"", "surname": "Сидоров", "firstname": "Дмитрий", "id_address": 3, "patronymic": "Александрович"}	postgres	2025-12-08 17:16:58.286105
300	producer	INSERT	\N	{"id": 21, "inn": "4567890123", "name": "ИП \\"Кулинария\\"", "surname": "Кузнецов", "firstname": "Алексей", "id_address": 4, "patronymic": "Игоревич"}	postgres	2025-12-08 17:16:58.286105
301	producer	INSERT	\N	{"id": 22, "inn": "5678901234", "name": "ООО \\"КомфортДом\\"", "surname": "Смирнов", "firstname": "Никита", "id_address": 5, "patronymic": "Петрович"}	postgres	2025-12-08 17:16:58.286105
302	producer	INSERT	\N	{"id": 23, "inn": "6789012345", "name": "АО \\"АвтоПром\\"", "surname": "Морозова", "firstname": "Ольга", "id_address": 6, "patronymic": "Алексеевна"}	postgres	2025-12-08 17:16:58.286105
303	producer	INSERT	\N	{"id": 24, "inn": "7890123456", "name": "ООО \\"МебельЛюкс\\"", "surname": "Федоров", "firstname": "Сергей", "id_address": 7, "patronymic": "Иванович"}	postgres	2025-12-08 17:16:58.286105
304	producer	INSERT	\N	{"id": 25, "inn": "8911234567", "name": "ИП \\"ТехМаркет\\"", "surname": "Григорьев", "firstname": "Павел", "id_address": 8, "patronymic": "Викторович"}	postgres	2025-12-08 17:16:58.286105
305	producer	INSERT	\N	{"id": 26, "inn": "9012345678", "name": "ООО \\"ХолодСервис\\"", "surname": "Васильева", "firstname": "Елена", "id_address": 9, "patronymic": "Александровна"}	postgres	2025-12-08 17:16:58.286105
306	product	INSERT	\N	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
307	product	INSERT	\N	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 17:18:59.134905
308	product	INSERT	\N	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:18:59.134905
309	product	INSERT	\N	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
310	product	INSERT	\N	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
311	product	INSERT	\N	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:18:59.134905
312	product	INSERT	\N	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
313	product	INSERT	\N	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
718	product	INSERT	\N	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 15:58:21.414366
317	product	INSERT	\N	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
318	product	INSERT	\N	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:18:59.134905
319	product	INSERT	\N	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:18:59.134905
320	product	INSERT	\N	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
321	product	INSERT	\N	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:18:59.134905
322	product	INSERT	\N	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
323	product	INSERT	\N	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
324	product	INSERT	\N	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 8}	postgres	2025-12-08 17:18:59.134905
325	product	INSERT	\N	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
326	product	INSERT	\N	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
327	product	INSERT	\N	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
328	product	INSERT	\N	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:18:59.134905
329	product	INSERT	\N	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 17:18:59.134905
330	product	INSERT	\N	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
331	product	INSERT	\N	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
332	product	INSERT	\N	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:18:59.134905
333	product	INSERT	\N	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
334	product	INSERT	\N	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:18:59.134905
335	product	INSERT	\N	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:18:59.134905
336	product	INSERT	\N	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:19:30.879792
337	product	INSERT	\N	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
338	product	INSERT	\N	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
339	product	INSERT	\N	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:19:30.879792
340	product	INSERT	\N	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
341	product	INSERT	\N	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
342	product	INSERT	\N	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
343	product	INSERT	\N	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
344	product	INSERT	\N	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
345	product	INSERT	\N	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:19:30.879792
346	product	INSERT	\N	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
347	product	INSERT	\N	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:19:30.879792
348	product	INSERT	\N	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
349	product	INSERT	\N	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
350	product	INSERT	\N	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
351	product	INSERT	\N	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
352	product	INSERT	\N	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 17:19:30.879792
353	product	INSERT	\N	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:19:30.879792
354	product	INSERT	\N	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:19:30.879792
355	product	INSERT	\N	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:19:30.879792
356	product	UPDATE	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
357	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
358	product	UPDATE	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
359	product	UPDATE	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
360	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
361	product	UPDATE	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
362	product	UPDATE	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
363	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
364	product	UPDATE	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
365	product	UPDATE	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
366	product	UPDATE	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
367	product	UPDATE	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
368	product	UPDATE	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
369	product	UPDATE	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
370	product	UPDATE	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
371	product	UPDATE	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
372	product	UPDATE	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
373	product	UPDATE	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
374	product	UPDATE	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 8}	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
375	product	UPDATE	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
376	product	UPDATE	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
377	product	UPDATE	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
378	product	UPDATE	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
379	product	UPDATE	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
380	product	UPDATE	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
381	product	UPDATE	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
382	product	UPDATE	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
383	product	UPDATE	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
384	product	UPDATE	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
385	product	UPDATE	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
386	product	UPDATE	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
387	product	UPDATE	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
388	product	UPDATE	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
389	product	UPDATE	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
390	product	UPDATE	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
391	product	UPDATE	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
392	product	UPDATE	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
393	product	UPDATE	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
394	product	UPDATE	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
395	product	UPDATE	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
396	product	UPDATE	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
397	product	UPDATE	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
398	product	UPDATE	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
399	product	UPDATE	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
400	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
401	product	UPDATE	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
402	product	UPDATE	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 17:23:06.705619
403	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	postgres	2025-12-08 17:23:06.705619
404	product	UPDATE	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	postgres	2025-12-08 17:23:06.705619
405	product	UPDATE	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	postgres	2025-12-08 17:23:06.705619
406	refresh_tokens	DELETE	{"id": 90, "role": "admin", "token": "462baf2b63285c363b6d217eb1c9962adc2cb2495a269694c5a9691068b5abab", "username": "valentin_admin", "created_at": "2025-12-08T12:36:55.456698"}	\N	admin	2025-12-08 17:25:02.748657
407	refresh_tokens	INSERT	\N	{"id": 91, "role": "admin", "token": "94191638876168d9c7aedb4d5d8c0769219ca41db4e06102d75ce16106e0c7ef", "username": "valentin_admin", "created_at": "2025-12-08T14:25:02.755384"}	admin	2025-12-08 17:25:02.755384
408	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765203936575570958_product-placeholder.png", "id_producer": 20, "id_product_category": 3}	admin	2025-12-08 17:25:36.579025
409	product	UPDATE	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "/static/products/1765205408580666042_9.avif", "id_producer": 26, "id_product_category": 3}	admin	2025-12-08 17:50:08.58171
597	refresh_tokens	INSERT	\N	{"id": 161, "role": "admin", "token": "43c31d509e0359bce2f9d52e7a17fdac43a29464181809727dc69b02567808e8", "username": "roman", "created_at": "2025-12-09T17:28:55.341515"}	admin	2025-12-09 20:28:55.341515
410	product	UPDATE	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "/static/products/1765205423056717632_10.webp", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:50:23.057518
411	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765205429991122927_11.jpg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:50:29.99166
412	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765205429991122927_11.jpg", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765205440110440418_11.jpg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:50:40.11107
860	document_content	DELETE	{"id": 17, "id_batch": 1, "quantity": 10, "id_document": 12}	\N	postgres	2025-12-14 09:43:53.443618
413	product	UPDATE	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "/static/products/1765205452018769299_12.jpeg", "id_producer": 21, "id_product_category": 8}	admin	2025-12-08 17:50:52.019086
414	product	UPDATE	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "/static/products/1765205465161011013_13.jpg", "id_producer": 24, "id_product_category": 2}	admin	2025-12-08 17:51:05.161558
415	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205479544053381_14.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:51:19.545105
416	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205479544053381_14.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205487200669926_15.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:51:27.201307
417	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205487200669926_15.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205505533275379_16-.jpg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:51:45.533991
418	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205505533275379_16-.jpg", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765205524070403429_14.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:52:04.070957
419	product	UPDATE	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "/static/products/1765205530989364252_15.jpeg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:52:10.989805
420	product	UPDATE	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "/static/products/1765205538458021339_16-.jpg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:52:18.458462
421	product	UPDATE	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "/static/products/1765205549156924260_17.jpeg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:52:29.157203
422	product	UPDATE	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "/static/products/1765205562290618336_18.jpeg", "id_producer": 19, "id_product_category": 1}	admin	2025-12-08 17:52:42.29117
423	product	UPDATE	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "/static/products/1765205573041308591_19.avif", "id_producer": 26, "id_product_category": 3}	admin	2025-12-08 17:52:53.041881
460	refresh_tokens	DELETE	{"id": 92, "role": "admin", "token": "7f9886647cdfa4bdf84dd0954e92f457c03a8302a9c12772cb39932c088573eb", "username": "valentin_admin", "created_at": "2025-12-08T16:54:05.282923"}	\N	admin	2025-12-08 20:02:00.814436
424	product	UPDATE	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "/static/products/1765205584128660513_20.jpeg", "id_producer": 26, "id_product_category": 3}	admin	2025-12-08 17:53:04.129114
425	product	UPDATE	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "/static/products/1765205595127459587_21.jpeg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:53:15.127741
426	product	UPDATE	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "/static/products/1765205605996546425_22.jpeg", "id_producer": 21, "id_product_category": 8}	admin	2025-12-08 17:53:25.99684
427	product	UPDATE	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "/static/products/1765205618048903084_23.jpeg", "id_producer": 24, "id_product_category": 2}	admin	2025-12-08 17:53:38.049306
428	product	UPDATE	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "/static/products/1765205628465314922_24.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:53:48.465809
429	product	UPDATE	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 8}	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "/static/products/1765205640054667886_25.webp", "id_producer": 24, "id_product_category": 8}	admin	2025-12-08 17:54:00.055162
469	refresh_tokens	INSERT	\N	{"id": 97, "role": "manager", "token": "cf949023c1695ebf656da3580d2b6c20662ca9db845c371b4fec80ae3e30b6ed", "username": "anna_sokolova", "created_at": "2025-12-09T11:42:34.342747"}	admin	2025-12-09 14:42:34.342747
430	product	UPDATE	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "/static/products/1765205655858996796_26.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:54:15.85945
431	product	UPDATE	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "/static/products/1765205673974680054_27.webp", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:54:33.975205
432	product	UPDATE	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "/static/products/1765205684816340587_28.webp", "id_producer": 19, "id_product_category": 1}	admin	2025-12-08 17:54:44.817134
433	product	UPDATE	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "/static/products/1765205696339956217_29.jpeg", "id_producer": 26, "id_product_category": 3}	admin	2025-12-08 17:54:56.340262
434	product	UPDATE	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "/static/products/1765205708359142459_30.png", "id_producer": 20, "id_product_category": 3}	admin	2025-12-08 17:55:08.359932
435	product	UPDATE	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/1765205719261295589_31.jpg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:55:19.261824
436	product	UPDATE	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/1765205719261295589_31.jpg", "id_producer": 20, "id_product_category": 2}	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/1765205722212345257_31.jpg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:55:22.212856
437	product	UPDATE	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "/static/products/1765205734811023180_32.webp", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:55:34.811514
438	product	UPDATE	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "/static/products/1765205761391543761_34.jpeg", "id_producer": 24, "id_product_category": 2}	admin	2025-12-08 17:56:01.391891
439	product	UPDATE	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "/static/products/1765205773609017920_35.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:56:13.609364
440	product	UPDATE	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "/static/products/1765205792574984887_38.jpg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:56:32.575405
441	product	UPDATE	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "/static/products/1765205804730533337_39.jpg", "id_producer": 19, "id_product_category": 1}	admin	2025-12-08 17:56:44.731434
442	product	UPDATE	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "/static/products/1765205815959577467_40.jpeg", "id_producer": 26, "id_product_category": 3}	admin	2025-12-08 17:56:55.960041
443	product	UPDATE	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "/static/products/1765205827626538500_41.jpeg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:57:07.626784
444	product	UPDATE	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "/static/products/1765205850908937761_43.jpeg", "id_producer": 24, "id_product_category": 2}	admin	2025-12-08 17:57:30.909499
445	product	UPDATE	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "/static/products/1765205864107465878_44.jpeg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:57:44.107855
446	product	UPDATE	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "/static/products/1765205876341915467_45.jpg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:57:56.342985
447	product	UPDATE	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "/static/products/1765205890486289126_46.jpeg", "id_producer": 21, "id_product_category": 8}	admin	2025-12-08 17:58:10.486865
448	product	UPDATE	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/1765205904948249133_47.jpeg", "id_producer": 19, "id_product_category": 1}	admin	2025-12-08 17:58:24.948859
449	product	UPDATE	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "/static/products/placeholder.png", "id_producer": 26, "id_product_category": 3}	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "/static/products/1765205926391147379_48.jpeg", "id_producer": 26, "id_product_category": 3}	admin	2025-12-08 17:58:46.392088
450	product	UPDATE	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/1765205936483095342_49.jpg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:58:56.483416
451	product	UPDATE	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/1765205936483095342_49.jpg", "id_producer": 20, "id_product_category": 2}	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/1765205938523145552_49.jpg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-08 17:58:58.523588
452	product	UPDATE	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/1765205949295874542_50.jpeg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-08 17:59:09.296493
453	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765205958320515130_51.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:59:18.321164
454	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765205958320515130_51.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765205959722191006_51.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-08 17:59:19.722565
455	product	UPDATE	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 2}	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/1765205970189001719_52.jpeg", "id_producer": 24, "id_product_category": 2}	admin	2025-12-08 17:59:30.189538
456	product	UPDATE	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/1765205980936305918_53.jpeg", "id_producer": 20, "id_product_category": 3}	admin	2025-12-08 17:59:40.936734
457	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765205992498019007_54.jpeg", "id_producer": 19, "id_product_category": 1}	admin	2025-12-08 17:59:52.498468
458	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765203936575570958_product-placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	postgres	2025-12-08 18:01:36.926421
459	refresh_tokens	INSERT	\N	{"id": 92, "role": "admin", "token": "7f9886647cdfa4bdf84dd0954e92f457c03a8302a9c12772cb39932c088573eb", "username": "valentin_admin", "created_at": "2025-12-08T16:54:05.282923"}	admin	2025-12-08 19:54:05.282923
461	refresh_tokens	INSERT	\N	{"id": 93, "role": "admin", "token": "e6804e775a2e5536837f154954002d97d9bcf26f8894e5c39e7a865cc16539f4", "username": "valentin_admin", "created_at": "2025-12-08T17:02:00.817486"}	admin	2025-12-08 20:02:00.817486
462	refresh_tokens	DELETE	{"id": 91, "role": "admin", "token": "94191638876168d9c7aedb4d5d8c0769219ca41db4e06102d75ce16106e0c7ef", "username": "valentin_admin", "created_at": "2025-12-08T14:25:02.755384"}	\N	postgres	2025-12-09 13:24:46.141075
463	refresh_tokens	DELETE	{"id": 93, "role": "admin", "token": "e6804e775a2e5536837f154954002d97d9bcf26f8894e5c39e7a865cc16539f4", "username": "valentin_admin", "created_at": "2025-12-08T17:02:00.817486"}	\N	admin	2025-12-09 13:24:52.576118
464	refresh_tokens	INSERT	\N	{"id": 94, "role": "admin", "token": "3cab747bbc116fa2785683b39e21749b294e0f92a206b969b64dde95c36f7650", "username": "valentin_admin", "created_at": "2025-12-09T10:24:52.580623"}	admin	2025-12-09 13:24:52.580623
465	refresh_tokens	INSERT	\N	{"id": 95, "role": "manager", "token": "ada97ea2f4660b2a007194ace869f8dad9757a5274947c81fd70eccd342b8bb7", "username": "manager_login", "created_at": "2025-12-09T10:51:34.674601"}	admin	2025-12-09 13:51:34.674601
713	product	INSERT	\N	{"id": 60, "name": "тест", "image_url": "", "id_producer": 3, "id_product_category": 2}	admin	2025-12-10 15:55:53.9862
466	sys_user	UPDATE	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$rgYYBEQoDW9f3dxPAgweruahkWXVL/EaX85oJaTY.SxpLHVhrRWsC"}	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$WbkGixzo3Ytz4sbIJeoWQub6aw9l1ftilNY7jUR/jwqzgNTcQ3XpW"}	postgres	2025-12-09 13:55:17.768599
467	sys_user	UPDATE	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$WbkGixzo3Ytz4sbIJeoWQub6aw9l1ftilNY7jUR/jwqzgNTcQ3XpW"}	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$ONDNHqgfrEHpioEyaVSDxOG3icMHs3nEsqP1TpzC9jYgB142ezb26"}	postgres	2025-12-09 13:55:56.899788
468	refresh_tokens	INSERT	\N	{"id": 96, "role": "manager", "token": "1c5e24a97707e3e50ebe82592562c8ba4192e885a32afd5450a80b0aff632465", "username": "anna_sokolova", "created_at": "2025-12-09T10:56:05.522899"}	admin	2025-12-09 13:56:05.522899
470	refresh_tokens	INSERT	\N	{"id": 98, "role": "manager", "token": "9c48d048079056764fc1f6d57477947f60c2be83ca554f2f4575ea7d1d086c64", "username": "anna_sokolova", "created_at": "2025-12-09T11:44:12.473663"}	admin	2025-12-09 14:44:12.473663
471	refresh_tokens	INSERT	\N	{"id": 99, "role": "admin", "token": "63391c417deb86b437ff30b682adf65cb0c4ef9d8aa79df04ca882d255cf0ff7", "username": "valentin_admin", "created_at": "2025-12-09T11:46:59.050982"}	admin	2025-12-09 14:46:59.050982
472	refresh_tokens	INSERT	\N	{"id": 100, "role": "admin", "token": "202081708e02bb629986713ba8b726bdb3e686c0f33ad2b8a0832ea0e2cd6bd0", "username": "valentin_admin", "created_at": "2025-12-09T11:49:10.804409"}	admin	2025-12-09 14:49:10.804409
473	refresh_tokens	INSERT	\N	{"id": 101, "role": "admin", "token": "6302d72a31c382137cb182c22cae6acac0c40df1b375393c5f6c2bb6bbac63dd", "username": "valentin_admin", "created_at": "2025-12-09T11:49:36.539889"}	admin	2025-12-09 14:49:36.539889
474	refresh_tokens	INSERT	\N	{"id": 102, "role": "admin", "token": "72f8b205fc42f51aa7b0ecbc62e5e9e95ab92769283d268b0fd2b0a2e7a28270", "username": "valentin_admin", "created_at": "2025-12-09T11:51:27.215036"}	admin	2025-12-09 14:51:27.215036
475	refresh_tokens	INSERT	\N	{"id": 103, "role": "manager", "token": "d72b1d7c24f17d0fa3b0d8ed1ba31f9ded7973af026d4e9a98e8b075750d12c7", "username": "anna_sokolova", "created_at": "2025-12-09T12:02:01.532397"}	admin	2025-12-09 15:02:01.532397
476	refresh_tokens	DELETE	{"id": 103, "role": "manager", "token": "d72b1d7c24f17d0fa3b0d8ed1ba31f9ded7973af026d4e9a98e8b075750d12c7", "username": "anna_sokolova", "created_at": "2025-12-09T12:02:01.532397"}	\N	admin	2025-12-09 15:02:54.89841
477	refresh_tokens	INSERT	\N	{"id": 104, "role": "admin", "token": "4bfa627c579dee54aab5d784c0297a7cff8364b351279ae722deb9499bcc2983", "username": "valentin_admin", "created_at": "2025-12-09T12:05:21.759537"}	admin	2025-12-09 15:05:21.759537
478	refresh_tokens	DELETE	{"id": 104, "role": "admin", "token": "4bfa627c579dee54aab5d784c0297a7cff8364b351279ae722deb9499bcc2983", "username": "valentin_admin", "created_at": "2025-12-09T12:05:21.759537"}	\N	admin	2025-12-09 15:19:37.741917
479	refresh_tokens	INSERT	\N	{"id": 105, "role": "admin", "token": "7cd7dfd7114c1bb8ce365fb1a04769a8ca3b38b020770d832307a9465d2ca75b", "username": "valentin_admin", "created_at": "2025-12-09T12:19:37.752407"}	admin	2025-12-09 15:19:37.752407
480	refresh_tokens	INSERT	\N	{"id": 106, "role": "manager", "token": "006c03fdfd5d3490ddd3bb9b995e0c30cb4df7d68da17b316cd074c7d4af579f", "username": "anna_sokolova", "created_at": "2025-12-09T12:22:42.57126"}	admin	2025-12-09 15:22:42.57126
481	refresh_tokens	INSERT	\N	{"id": 107, "role": "manager", "token": "210e4eadc172f2d73ae69358b5ba22d74f2889cae684cc00af0c4b9a6ac4e979", "username": "anna_sokolova", "created_at": "2025-12-09T12:23:39.427171"}	admin	2025-12-09 15:23:39.427171
482	refresh_tokens	DELETE	{"id": 106, "role": "manager", "token": "006c03fdfd5d3490ddd3bb9b995e0c30cb4df7d68da17b316cd074c7d4af579f", "username": "anna_sokolova", "created_at": "2025-12-09T12:22:42.57126"}	\N	admin	2025-12-09 15:24:01.820721
483	refresh_tokens	DELETE	{"id": 107, "role": "manager", "token": "210e4eadc172f2d73ae69358b5ba22d74f2889cae684cc00af0c4b9a6ac4e979", "username": "anna_sokolova", "created_at": "2025-12-09T12:23:39.427171"}	\N	admin	2025-12-09 15:24:04.000472
484	refresh_tokens	DELETE	{"id": 105, "role": "admin", "token": "7cd7dfd7114c1bb8ce365fb1a04769a8ca3b38b020770d832307a9465d2ca75b", "username": "valentin_admin", "created_at": "2025-12-09T12:19:37.752407"}	\N	admin	2025-12-09 15:24:05.868972
485	refresh_tokens	INSERT	\N	{"id": 108, "role": "manager", "token": "57a748747bc4003b00ad09ba7bb0f3eadc6bcf9d8a660c1f7491499a20e9ba5a", "username": "anna_sokolova", "created_at": "2025-12-09T12:24:33.975463"}	admin	2025-12-09 15:24:33.975463
486	refresh_tokens	DELETE	{"id": 108, "role": "manager", "token": "57a748747bc4003b00ad09ba7bb0f3eadc6bcf9d8a660c1f7491499a20e9ba5a", "username": "anna_sokolova", "created_at": "2025-12-09T12:24:33.975463"}	\N	admin	2025-12-09 15:24:56.633213
487	refresh_tokens	INSERT	\N	{"id": 109, "role": "manager", "token": "43c4ec5f0188fc00c45ca15cef292bfc8aef26e2ffdf1522499c748f9d9fdc50", "username": "anna_sokolova", "created_at": "2025-12-09T12:25:19.624641"}	admin	2025-12-09 15:25:19.624641
488	refresh_tokens	INSERT	\N	{"id": 110, "role": "manager", "token": "0e718980fad4114e75fa7e7016504dc15780845a011bc094d54526c5b81533d5", "username": "anna_sokolova", "created_at": "2025-12-09T12:26:50.795891"}	admin	2025-12-09 15:26:50.795891
489	refresh_tokens	DELETE	{"id": 109, "role": "manager", "token": "43c4ec5f0188fc00c45ca15cef292bfc8aef26e2ffdf1522499c748f9d9fdc50", "username": "anna_sokolova", "created_at": "2025-12-09T12:25:19.624641"}	\N	admin	2025-12-09 15:26:56.24697
490	refresh_tokens	INSERT	\N	{"id": 111, "role": "manager", "token": "1c2acd335ae39b160a9d8c78dc566fb2bee05f85c4a50d069fd8f6a8abbd80fd", "username": "anna_sokolova", "created_at": "2025-12-09T12:29:48.768848"}	admin	2025-12-09 15:29:48.768848
491	refresh_tokens	DELETE	{"id": 111, "role": "manager", "token": "1c2acd335ae39b160a9d8c78dc566fb2bee05f85c4a50d069fd8f6a8abbd80fd", "username": "anna_sokolova", "created_at": "2025-12-09T12:29:48.768848"}	\N	admin	2025-12-09 15:30:08.626854
492	refresh_tokens	DELETE	{"id": 110, "role": "manager", "token": "0e718980fad4114e75fa7e7016504dc15780845a011bc094d54526c5b81533d5", "username": "anna_sokolova", "created_at": "2025-12-09T12:26:50.795891"}	\N	admin	2025-12-09 15:34:33.060415
493	refresh_tokens	INSERT	\N	{"id": 112, "role": "manager", "token": "a2fa5fa50c1aff9c2bbf7adec5674e5f1f47acd4bd5df5d2140dd9b6d93239fa", "username": "anna_sokolova", "created_at": "2025-12-09T12:34:45.346962"}	admin	2025-12-09 15:34:45.346962
494	refresh_tokens	DELETE	{"id": 112, "role": "manager", "token": "a2fa5fa50c1aff9c2bbf7adec5674e5f1f47acd4bd5df5d2140dd9b6d93239fa", "username": "anna_sokolova", "created_at": "2025-12-09T12:34:45.346962"}	\N	admin	2025-12-09 15:36:03.654057
496	refresh_tokens	DELETE	{"id": 113, "role": "manager", "token": "595cb504cdc827e0b54a79c43363c6a5e36fc89ff4a3380c5e4f4a7061f8eaf2", "username": "anna_sokolova", "created_at": "2025-12-09T12:36:19.952073"}	\N	admin	2025-12-09 15:38:39.59039
497	refresh_tokens	INSERT	\N	{"id": 114, "role": "manager", "token": "1a7c6e8535e3827b7f532a45145bfd5af22e4b172b1e1e8d5adfb85b2a171943", "username": "anna_sokolova", "created_at": "2025-12-09T12:38:58.255596"}	admin	2025-12-09 15:38:58.255596
498	refresh_tokens	INSERT	\N	{"id": 115, "role": "manager", "token": "420acc15ec8186fbd14fdf36da3c45d00d8159533a33577ff4df6beae6970d11", "username": "anna_sokolova", "created_at": "2025-12-09T12:42:27.696936"}	admin	2025-12-09 15:42:27.696936
499	refresh_tokens	DELETE	{"id": 114, "role": "manager", "token": "1a7c6e8535e3827b7f532a45145bfd5af22e4b172b1e1e8d5adfb85b2a171943", "username": "anna_sokolova", "created_at": "2025-12-09T12:38:58.255596"}	\N	admin	2025-12-09 15:43:32.264007
500	refresh_tokens	DELETE	{"id": 115, "role": "manager", "token": "420acc15ec8186fbd14fdf36da3c45d00d8159533a33577ff4df6beae6970d11", "username": "anna_sokolova", "created_at": "2025-12-09T12:42:27.696936"}	\N	admin	2025-12-09 15:43:34.088489
501	refresh_tokens	INSERT	\N	{"id": 116, "role": "manager", "token": "39d923c267b97c8fe9a839b6bff815cccf89af1c2a729ea81d8b430d6a226b07", "username": "anna_sokolova", "created_at": "2025-12-09T12:43:40.456157"}	admin	2025-12-09 15:43:40.456157
502	refresh_tokens	DELETE	{"id": 116, "role": "manager", "token": "39d923c267b97c8fe9a839b6bff815cccf89af1c2a729ea81d8b430d6a226b07", "username": "anna_sokolova", "created_at": "2025-12-09T12:43:40.456157"}	\N	admin	2025-12-09 15:44:41.165922
503	refresh_tokens	INSERT	\N	{"id": 117, "role": "manager", "token": "6fb626fec248d357b8b5eb1fa12e32c6524c899602b3506d4f8b8f46a8325b60", "username": "anna_sokolova", "created_at": "2025-12-09T12:45:06.688129"}	admin	2025-12-09 15:45:06.688129
504	refresh_tokens	DELETE	{"id": 117, "role": "manager", "token": "6fb626fec248d357b8b5eb1fa12e32c6524c899602b3506d4f8b8f46a8325b60", "username": "anna_sokolova", "created_at": "2025-12-09T12:45:06.688129"}	\N	admin	2025-12-09 15:46:17.372376
505	refresh_tokens	INSERT	\N	{"id": 118, "role": "manager", "token": "a19eccfe09c94b3f36047d5f4bb2b91f7d6df133f78413c4fe771495b69da46b", "username": "anna_sokolova", "created_at": "2025-12-09T12:46:30.181883"}	admin	2025-12-09 15:46:30.181883
506	refresh_tokens	DELETE	{"id": 118, "role": "manager", "token": "a19eccfe09c94b3f36047d5f4bb2b91f7d6df133f78413c4fe771495b69da46b", "username": "anna_sokolova", "created_at": "2025-12-09T12:46:30.181883"}	\N	admin	2025-12-09 15:47:16.382323
507	refresh_tokens	INSERT	\N	{"id": 119, "role": "manager", "token": "530d6a75976a2224e07aca365c732a40a010fe9fc4fd1388fdacd0e6f8b51124", "username": "anna_sokolova", "created_at": "2025-12-09T12:47:26.093812"}	admin	2025-12-09 15:47:26.093812
508	refresh_tokens	DELETE	{"id": 119, "role": "manager", "token": "530d6a75976a2224e07aca365c732a40a010fe9fc4fd1388fdacd0e6f8b51124", "username": "anna_sokolova", "created_at": "2025-12-09T12:47:26.093812"}	\N	admin	2025-12-09 15:47:29.079951
509	sys_user	UPDATE	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$FVCCd92Vbpubj1004.Df8eVP4LVbyttxm1wXserInQnEbHcE5oFLm"}	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$qUXAZvUmIqXTyQHy6UvM0eNx8o8P9cmTe5Qv3pIwlsQMwQO1SzkNG"}	admin	2025-12-09 15:50:33.316973
510	sys_user	UPDATE	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$qUXAZvUmIqXTyQHy6UvM0eNx8o8P9cmTe5Qv3pIwlsQMwQO1SzkNG"}	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$z9I2uGqAHHc5paoMn9T5yOXLEEDnWMj/Pmwegsv/vdagYct7RKN1O"}	admin	2025-12-09 15:51:04.683874
511	refresh_tokens	INSERT	\N	{"id": 120, "role": "admin", "token": "b8962de86cede4d3a214001bff47227e409168dc5c0f2aada55f37b5f99daae5", "username": "artem_volkov", "created_at": "2025-12-09T12:51:08.264498"}	admin	2025-12-09 15:51:08.264498
512	refresh_tokens	DELETE	{"id": 120, "role": "admin", "token": "b8962de86cede4d3a214001bff47227e409168dc5c0f2aada55f37b5f99daae5", "username": "artem_volkov", "created_at": "2025-12-09T12:51:08.264498"}	\N	admin	2025-12-09 15:53:24.608973
513	refresh_tokens	INSERT	\N	{"id": 121, "role": "admin", "token": "91efc5bfa675fed4f89e697ef7faa9fedb35647588f5639f52e8947aa40820e0", "username": "artem_volkov", "created_at": "2025-12-09T12:53:24.614576"}	admin	2025-12-09 15:53:24.614576
514	refresh_tokens	INSERT	\N	{"id": 122, "role": "manager", "token": "015b749c2c2c78b468d0c303f7b8eb19b06147f5fe900c773b7b96892b9bf5e6", "username": "anna_sokolova", "created_at": "2025-12-09T13:06:47.405052"}	admin	2025-12-09 16:06:47.405052
515	refresh_tokens	DELETE	{"id": 122, "role": "manager", "token": "015b749c2c2c78b468d0c303f7b8eb19b06147f5fe900c773b7b96892b9bf5e6", "username": "anna_sokolova", "created_at": "2025-12-09T13:06:47.405052"}	\N	admin	2025-12-09 16:23:41.148548
516	refresh_tokens	INSERT	\N	{"id": 123, "role": "admin", "token": "033b73fd801932ce7b4e9deb13c57b25a4c413a9af3cf1f482efab5f2ed3c71e", "username": "artem_volkov", "created_at": "2025-12-09T13:24:04.408174"}	admin	2025-12-09 16:24:04.408174
517	refresh_tokens	DELETE	{"id": 123, "role": "admin", "token": "033b73fd801932ce7b4e9deb13c57b25a4c413a9af3cf1f482efab5f2ed3c71e", "username": "artem_volkov", "created_at": "2025-12-09T13:24:04.408174"}	\N	admin	2025-12-09 16:24:24.17098
518	refresh_tokens	INSERT	\N	{"id": 124, "role": "admin", "token": "ec19a1842a6fd820e1bed0ef3f9d920d6087311adf0ecbd9ddecec7f4867b08f", "username": "artem_volkov", "created_at": "2025-12-09T13:26:31.035874"}	admin	2025-12-09 16:26:31.035874
519	refresh_tokens	DELETE	{"id": 124, "role": "admin", "token": "ec19a1842a6fd820e1bed0ef3f9d920d6087311adf0ecbd9ddecec7f4867b08f", "username": "artem_volkov", "created_at": "2025-12-09T13:26:31.035874"}	\N	admin	2025-12-09 16:26:54.935346
520	refresh_tokens	INSERT	\N	{"id": 125, "role": "moderator", "token": "1747bd2b588f58ac59f3ff07ff5c2deb05ea97df8f633088c318d23b9265d7b2", "username": "moderator_login", "created_at": "2025-12-09T13:27:02.094803"}	admin	2025-12-09 16:27:02.094803
521	refresh_tokens	DELETE	{"id": 121, "role": "admin", "token": "91efc5bfa675fed4f89e697ef7faa9fedb35647588f5639f52e8947aa40820e0", "username": "artem_volkov", "created_at": "2025-12-09T12:53:24.614576"}	\N	admin	2025-12-09 16:31:53.389539
522	refresh_tokens	INSERT	\N	{"id": 126, "role": "admin", "token": "d075bb38e7e4e6373a1dc5290aa6e062bbc706a6259654d2d40eff03da0ee531", "username": "artem_volkov", "created_at": "2025-12-09T13:31:53.402496"}	admin	2025-12-09 16:31:53.402496
523	refresh_tokens	INSERT	\N	{"id": 127, "role": "manager", "token": "16293c4ea466be843e4236de25d0826048d508173ca0ab34af5f8a51ee7188ce", "username": "anna_sokolova", "created_at": "2025-12-09T13:37:11.531115"}	admin	2025-12-09 16:37:11.531115
524	refresh_tokens	INSERT	\N	{"id": 128, "role": "admin", "token": "927ba55fb6bab277a3991a077ed5a43c46eb956c43e72934a6680242484fa3be", "username": "artem_volkov", "created_at": "2025-12-09T13:37:34.840008"}	admin	2025-12-09 16:37:34.840008
539	refresh_tokens	DELETE	{"id": 126, "role": "admin", "token": "d075bb38e7e4e6373a1dc5290aa6e062bbc706a6259654d2d40eff03da0ee531", "username": "artem_volkov", "created_at": "2025-12-09T13:31:53.402496"}	\N	admin	2025-12-09 17:04:17.924845
540	refresh_tokens	INSERT	\N	{"id": 136, "role": "admin", "token": "2ece59a0d9e0673630fcf6a82be35ed4190f310c14426771c8c99fbd1546afad", "username": "artem_volkov", "created_at": "2025-12-09T14:04:17.942263"}	admin	2025-12-09 17:04:17.942263
541	sys_user	UPDATE	{"id": 7, "login": "valentin_admin", "id_role": 4, "id_employee": 14, "password_hash": "$2a$10$20LdgaOXwKGG9jQAJXDkMeIjzJo4jn5pMcr/Forby.IdMLDA9vuCK"}	{"id": 7, "login": "roman", "id_role": 4, "id_employee": 14, "password_hash": "$2a$10$4MWSzOFhEH9X4P25w7YgCeJkH5FoB8lx4S69iRPsnFunJiPOXWYDa"}	admin	2025-12-09 17:09:00.10985
569	refresh_tokens	DELETE	{"id": 143, "role": "admin", "token": "df2f89e63a805b31e0879a03b2748cbdc040ea49ff13b743d5880af421fd2044", "username": "roman", "created_at": "2025-12-09T15:01:49.333168"}	\N	postgres	2025-12-09 19:23:43.84588
542	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Баранов", "firstname": "Валентин", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "1111111111111111"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	admin	2025-12-09 17:09:32.305196
543	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2025-12-05", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	admin	2025-12-09 17:09:45.67012
544	refresh_tokens	DELETE	{"id": 135, "role": "admin", "token": "2157dd8188715d6d02ef1ff582598d46f820bcb8fa3dd2f04fd1145490e418dd", "username": "artem_volkov", "created_at": "2025-12-09T14:00:20.767336"}	\N	admin	2025-12-09 17:09:52.014868
545	position	UPDATE	{"id": 9, "name": "Системный администратов", "description": "Администрирование информационной системой, полный доступ к ИС"}	{"id": 9, "name": "Системный администратор", "description": "Администрирование информационной системой, полный доступ к ИС"}	admin	2025-12-09 17:13:44.495143
546	refresh_tokens	INSERT	\N	{"id": 137, "role": "admin", "token": "f1a00b2dfa1e722168a1444286846e017f6e2619af60220936e1e69f4d075451", "username": "roman", "created_at": "2025-12-09T14:16:33.713064"}	admin	2025-12-09 17:16:33.713064
547	refresh_tokens	INSERT	\N	{"id": 138, "role": "admin", "token": "bc1c7ded5a61a23e44600fa3de039a2745e607c821bd951d92e7d6b7212db6e8", "username": "roman", "created_at": "2025-12-09T14:54:00.012871"}	admin	2025-12-09 17:54:00.012871
548	refresh_tokens	DELETE	{"id": 137, "role": "admin", "token": "f1a00b2dfa1e722168a1444286846e017f6e2619af60220936e1e69f4d075451", "username": "roman", "created_at": "2025-12-09T14:16:33.713064"}	\N	admin	2025-12-09 17:54:39.827807
549	refresh_tokens	INSERT	\N	{"id": 139, "role": "admin", "token": "e84ee2c7d60f0609c341bfefb7136b3eff794c22f1de180046ad3bea04febdd9", "username": "roman", "created_at": "2025-12-09T14:54:56.850433"}	admin	2025-12-09 17:54:56.850433
550	refresh_tokens	DELETE	{"id": 139, "role": "admin", "token": "e84ee2c7d60f0609c341bfefb7136b3eff794c22f1de180046ad3bea04febdd9", "username": "roman", "created_at": "2025-12-09T14:54:56.850433"}	\N	admin	2025-12-09 17:55:00.370954
551	refresh_tokens	INSERT	\N	{"id": 140, "role": "admin", "token": "96ec9e72042904efc1f7db30964982e93b0802c2ff0c6ca26d3f331d33ff8eb2", "username": "roman", "created_at": "2025-12-09T14:55:13.907446"}	admin	2025-12-09 17:55:13.907446
552	refresh_tokens	DELETE	{"id": 140, "role": "admin", "token": "96ec9e72042904efc1f7db30964982e93b0802c2ff0c6ca26d3f331d33ff8eb2", "username": "roman", "created_at": "2025-12-09T14:55:13.907446"}	\N	admin	2025-12-09 17:56:41.940384
553	refresh_tokens	INSERT	\N	{"id": 141, "role": "admin", "token": "b689bcfbb22314df6241e24ae860f621dda6bd241efd6e75c93945fc80b19965", "username": "roman", "created_at": "2025-12-09T14:56:41.943389"}	admin	2025-12-09 17:56:41.943389
554	refresh_tokens	DELETE	{"id": 141, "role": "admin", "token": "b689bcfbb22314df6241e24ae860f621dda6bd241efd6e75c93945fc80b19965", "username": "roman", "created_at": "2025-12-09T14:56:41.943389"}	\N	admin	2025-12-09 17:56:41.981721
555	refresh_tokens	INSERT	\N	{"id": 142, "role": "admin", "token": "bca6f4e2556c0cdeac9b1a0e6606b0b67186c96f12dfa9069c67e8b96df04c40", "username": "roman", "created_at": "2025-12-09T15:00:44.150674"}	admin	2025-12-09 18:00:44.150674
556	refresh_tokens	DELETE	{"id": 142, "role": "admin", "token": "bca6f4e2556c0cdeac9b1a0e6606b0b67186c96f12dfa9069c67e8b96df04c40", "username": "roman", "created_at": "2025-12-09T15:00:44.150674"}	\N	admin	2025-12-09 18:01:49.31012
557	refresh_tokens	INSERT	\N	{"id": 143, "role": "admin", "token": "df2f89e63a805b31e0879a03b2748cbdc040ea49ff13b743d5880af421fd2044", "username": "roman", "created_at": "2025-12-09T15:01:49.333168"}	admin	2025-12-09 18:01:49.333168
558	refresh_tokens	INSERT	\N	{"id": 144, "role": "admin", "token": "260f80a53636ffaa7dfbfec63ad09ef38d94a08d4af5a3fe6b12e024376f4dfb", "username": "roman", "created_at": "2025-12-09T15:01:49.336952"}	admin	2025-12-09 18:01:49.336952
559	refresh_tokens	DELETE	{"id": 144, "role": "admin", "token": "260f80a53636ffaa7dfbfec63ad09ef38d94a08d4af5a3fe6b12e024376f4dfb", "username": "roman", "created_at": "2025-12-09T15:01:49.336952"}	\N	admin	2025-12-09 18:03:13.376958
560	refresh_tokens	INSERT	\N	{"id": 146, "role": "admin", "token": "615a3f96995557524aad272d6b6131a8d20cf15861115ea11afbe1d13a48dd81", "username": "roman", "created_at": "2025-12-09T15:03:13.403999"}	admin	2025-12-09 18:03:13.403999
561	refresh_tokens	INSERT	\N	{"id": 145, "role": "admin", "token": "371b903083be1eb37461c18c88441516430f783692be369ecfb7988e4298d63d", "username": "roman", "created_at": "2025-12-09T15:03:13.403955"}	admin	2025-12-09 18:03:13.403955
562	refresh_tokens	DELETE	{"id": 145, "role": "admin", "token": "371b903083be1eb37461c18c88441516430f783692be369ecfb7988e4298d63d", "username": "roman", "created_at": "2025-12-09T15:03:13.403955"}	\N	admin	2025-12-09 19:08:30.734161
563	refresh_tokens	INSERT	\N	{"id": 147, "role": "admin", "token": "3462978b83a5de85a950ad270e2805e91a7ee8609da83d22fab7512e94411f44", "username": "roman", "created_at": "2025-12-09T16:08:30.742766"}	admin	2025-12-09 19:08:30.742766
564	refresh_tokens	INSERT	\N	{"id": 148, "role": "admin", "token": "211eae25c7351853a8702e235310e7eaa4e30b2ae0b83134239acf3437e6c9da", "username": "roman", "created_at": "2025-12-09T16:08:30.742792"}	admin	2025-12-09 19:08:30.742792
565	refresh_tokens	DELETE	{"id": 125, "role": "moderator", "token": "1747bd2b588f58ac59f3ff07ff5c2deb05ea97df8f633088c318d23b9265d7b2", "username": "moderator_login", "created_at": "2025-12-09T13:27:02.094803"}	\N	postgres	2025-12-09 19:23:43.84588
566	refresh_tokens	DELETE	{"id": 127, "role": "manager", "token": "16293c4ea466be843e4236de25d0826048d508173ca0ab34af5f8a51ee7188ce", "username": "anna_sokolova", "created_at": "2025-12-09T13:37:11.531115"}	\N	postgres	2025-12-09 19:23:43.84588
567	refresh_tokens	DELETE	{"id": 136, "role": "admin", "token": "2ece59a0d9e0673630fcf6a82be35ed4190f310c14426771c8c99fbd1546afad", "username": "artem_volkov", "created_at": "2025-12-09T14:04:17.942263"}	\N	postgres	2025-12-09 19:23:43.84588
568	refresh_tokens	DELETE	{"id": 138, "role": "admin", "token": "bc1c7ded5a61a23e44600fa3de039a2745e607c821bd951d92e7d6b7212db6e8", "username": "roman", "created_at": "2025-12-09T14:54:00.012871"}	\N	postgres	2025-12-09 19:23:43.84588
570	refresh_tokens	DELETE	{"id": 146, "role": "admin", "token": "615a3f96995557524aad272d6b6131a8d20cf15861115ea11afbe1d13a48dd81", "username": "roman", "created_at": "2025-12-09T15:03:13.403999"}	\N	postgres	2025-12-09 19:23:43.84588
571	refresh_tokens	DELETE	{"id": 147, "role": "admin", "token": "3462978b83a5de85a950ad270e2805e91a7ee8609da83d22fab7512e94411f44", "username": "roman", "created_at": "2025-12-09T16:08:30.742766"}	\N	postgres	2025-12-09 19:23:43.84588
572	refresh_tokens	INSERT	\N	{"id": 149, "role": "admin", "token": "d45c876d4e48e4e9b0f547bd3c417f2794331ebf926646081aac9cebb21c3cad", "username": "artem_volkov", "created_at": "2025-12-09T16:23:59.750484"}	admin	2025-12-09 19:23:59.750484
573	refresh_tokens	INSERT	\N	{"id": 150, "role": "admin", "token": "43700c931d0d3e8cebd2a8474d0dec5325178257ebb601669b65dc94e6b96ad7", "username": "roman", "created_at": "2025-12-09T17:09:11.778166"}	admin	2025-12-09 20:09:11.778166
574	refresh_tokens	INSERT	\N	{"id": 151, "role": "admin", "token": "f0f8e157ac787c59d5c42e8758de0010f077f3bf413d6d6c62abdbb23276d3ad", "username": "roman", "created_at": "2025-12-09T17:09:30.1471"}	admin	2025-12-09 20:09:30.1471
575	refresh_tokens	INSERT	\N	{"id": 152, "role": "admin", "token": "bee96f53ad2e433734d41b207faaf1f226b9e0a59b672ddd09e0abe49d8f4600", "username": "artem_volkov", "created_at": "2025-12-09T17:09:50.208105"}	admin	2025-12-09 20:09:50.208105
576	refresh_tokens	INSERT	\N	{"id": 153, "role": "admin", "token": "a379584c32b74c8d034e59558fc8aaebaf0fcc93307804267e6b891c85703794", "username": "artem_volkov", "created_at": "2025-12-09T17:10:10.999035"}	admin	2025-12-09 20:10:10.999035
577	refresh_tokens	INSERT	\N	{"id": 154, "role": "admin", "token": "f461e99e52918b7243831b06b0ce4b0bac15d44674f343755cfcf853eef71c0e", "username": "roman", "created_at": "2025-12-09T17:10:29.338018"}	admin	2025-12-09 20:10:29.338018
578	refresh_tokens	DELETE	{"id": 148, "role": "admin", "token": "211eae25c7351853a8702e235310e7eaa4e30b2ae0b83134239acf3437e6c9da", "username": "roman", "created_at": "2025-12-09T16:08:30.742792"}	\N	postgres	2025-12-09 20:10:58.096145
579	refresh_tokens	DELETE	{"id": 149, "role": "admin", "token": "d45c876d4e48e4e9b0f547bd3c417f2794331ebf926646081aac9cebb21c3cad", "username": "artem_volkov", "created_at": "2025-12-09T16:23:59.750484"}	\N	postgres	2025-12-09 20:10:58.096145
580	refresh_tokens	DELETE	{"id": 150, "role": "admin", "token": "43700c931d0d3e8cebd2a8474d0dec5325178257ebb601669b65dc94e6b96ad7", "username": "roman", "created_at": "2025-12-09T17:09:11.778166"}	\N	postgres	2025-12-09 20:10:58.096145
581	refresh_tokens	DELETE	{"id": 151, "role": "admin", "token": "f0f8e157ac787c59d5c42e8758de0010f077f3bf413d6d6c62abdbb23276d3ad", "username": "roman", "created_at": "2025-12-09T17:09:30.1471"}	\N	postgres	2025-12-09 20:10:58.096145
582	refresh_tokens	DELETE	{"id": 152, "role": "admin", "token": "bee96f53ad2e433734d41b207faaf1f226b9e0a59b672ddd09e0abe49d8f4600", "username": "artem_volkov", "created_at": "2025-12-09T17:09:50.208105"}	\N	postgres	2025-12-09 20:10:58.096145
583	refresh_tokens	DELETE	{"id": 153, "role": "admin", "token": "a379584c32b74c8d034e59558fc8aaebaf0fcc93307804267e6b891c85703794", "username": "artem_volkov", "created_at": "2025-12-09T17:10:10.999035"}	\N	postgres	2025-12-09 20:10:58.096145
584	refresh_tokens	DELETE	{"id": 154, "role": "admin", "token": "f461e99e52918b7243831b06b0ce4b0bac15d44674f343755cfcf853eef71c0e", "username": "roman", "created_at": "2025-12-09T17:10:29.338018"}	\N	postgres	2025-12-09 20:10:58.096145
585	refresh_tokens	INSERT	\N	{"id": 155, "role": "admin", "token": "8905f52237a9183207a397a8109caa83f18850dd1c29ae5762f474b19ff8c8d6", "username": "artem_volkov", "created_at": "2025-12-09T17:12:30.012626"}	admin	2025-12-09 20:12:30.012626
586	refresh_tokens	DELETE	{"id": 155, "role": "admin", "token": "8905f52237a9183207a397a8109caa83f18850dd1c29ae5762f474b19ff8c8d6", "username": "artem_volkov", "created_at": "2025-12-09T17:12:30.012626"}	\N	postgres	2025-12-09 20:14:30.310874
587	refresh_tokens	INSERT	\N	{"id": 156, "role": "admin", "token": "6a50191faabb5b8e788662287f08e292427b9e3daf1627243002779307a50dcb", "username": "roman", "created_at": "2025-12-09T17:15:50.75675"}	admin	2025-12-09 20:15:50.75675
588	refresh_tokens	DELETE	{"id": 156, "role": "admin", "token": "6a50191faabb5b8e788662287f08e292427b9e3daf1627243002779307a50dcb", "username": "roman", "created_at": "2025-12-09T17:15:50.75675"}	\N	admin	2025-12-09 20:15:50.821323
589	refresh_tokens	INSERT	\N	{"id": 157, "role": "admin", "token": "b0e7a19ed315966fc55a61dc2c32b296ef8b31c93577044d340d07bf8b31a195", "username": "roman", "created_at": "2025-12-09T17:16:28.32844"}	admin	2025-12-09 20:16:28.32844
590	refresh_tokens	DELETE	{"id": 157, "role": "admin", "token": "b0e7a19ed315966fc55a61dc2c32b296ef8b31c93577044d340d07bf8b31a195", "username": "roman", "created_at": "2025-12-09T17:16:28.32844"}	\N	admin	2025-12-09 20:16:28.387689
591	refresh_tokens	INSERT	\N	{"id": 158, "role": "admin", "token": "1c093445cb38a36c7966126c476feee53036007ad6c95d0c3c899ee65836b87a", "username": "roman", "created_at": "2025-12-09T17:21:08.889994"}	admin	2025-12-09 20:21:08.889994
592	refresh_tokens	DELETE	{"id": 158, "role": "admin", "token": "1c093445cb38a36c7966126c476feee53036007ad6c95d0c3c899ee65836b87a", "username": "roman", "created_at": "2025-12-09T17:21:08.889994"}	\N	admin	2025-12-09 20:21:08.947731
593	refresh_tokens	INSERT	\N	{"id": 159, "role": "admin", "token": "67af4f870982ff5e27d879bd7e78a6fd2593cfbdcaef8c419405283fd2beb711", "username": "roman", "created_at": "2025-12-09T17:22:16.662421"}	admin	2025-12-09 20:22:16.662421
594	refresh_tokens	INSERT	\N	{"id": 160, "role": "admin", "token": "019306bb2eecfcc2649d38e56be0bde178e2bbeac0ed741ca254e885bd7807a4", "username": "roman", "created_at": "2025-12-09T17:22:55.367552"}	admin	2025-12-09 20:22:55.367552
595	refresh_tokens	DELETE	{"id": 159, "role": "admin", "token": "67af4f870982ff5e27d879bd7e78a6fd2593cfbdcaef8c419405283fd2beb711", "username": "roman", "created_at": "2025-12-09T17:22:16.662421"}	\N	postgres	2025-12-09 20:28:09.679727
596	refresh_tokens	DELETE	{"id": 160, "role": "admin", "token": "019306bb2eecfcc2649d38e56be0bde178e2bbeac0ed741ca254e885bd7807a4", "username": "roman", "created_at": "2025-12-09T17:22:55.367552"}	\N	admin	2025-12-09 20:28:55.31882
714	product	DELETE	{"id": 59, "name": "тест", "image_url": "", "id_producer": 3, "id_product_category": 2}	\N	postgres	2025-12-10 15:56:25.919956
598	batch	UPDATE	{"id": 1, "cost": 125500, "created_at": "2025-10-15T08:39:40.31846", "id_product": 1, "expiration_date": "2034-01-15", "production_date": "2024-01-15"}	{"id": 1, "cost": 125500, "created_at": "2025-10-15T08:39:40.31846", "id_product": 1, "expiration_date": "2024-01-15", "production_date": "2024-01-15"}	postgres	2025-12-09 20:41:22.216215
599	refresh_tokens	INSERT	\N	{"id": 162, "role": "manager", "token": "aeddb994277e010f0a0059ce9edb5ee4bf48570bff564bb2d77b0dda6afc55c5", "username": "anna_sokolova", "created_at": "2025-12-09T17:47:26.57573"}	admin	2025-12-09 20:47:26.57573
600	refresh_tokens	DELETE	{"id": 162, "role": "manager", "token": "aeddb994277e010f0a0059ce9edb5ee4bf48570bff564bb2d77b0dda6afc55c5", "username": "anna_sokolova", "created_at": "2025-12-09T17:47:26.57573"}	\N	admin	2025-12-10 07:47:51.581666
601	refresh_tokens	INSERT	\N	{"id": 163, "role": "manager", "token": "7f07acde7b0a51986c42859c141d27a158a2e85ab57e1158b0636990aae6c05d", "username": "anna_sokolova", "created_at": "2025-12-10T04:47:51.591143"}	admin	2025-12-10 07:47:51.591143
602	refresh_tokens	INSERT	\N	{"id": 164, "role": "manager", "token": "8db75a6a1b39be467e42a22b98266ce26a7bd104b292db011aa7eba7559c8e82", "username": "anna_sokolova", "created_at": "2025-12-10T04:47:51.591169"}	admin	2025-12-10 07:47:51.591169
603	refresh_tokens	DELETE	{"id": 164, "role": "manager", "token": "8db75a6a1b39be467e42a22b98266ce26a7bd104b292db011aa7eba7559c8e82", "username": "anna_sokolova", "created_at": "2025-12-10T04:47:51.591169"}	\N	admin	2025-12-10 07:47:54.32666
604	refresh_tokens	INSERT	\N	{"id": 165, "role": "admin", "token": "243aca4b717c535a074fbe1fe4db79939871fb7744cc20189e491bdadd718c8c", "username": "roman", "created_at": "2025-12-10T04:48:01.537222"}	admin	2025-12-10 07:48:01.537222
605	refresh_tokens	DELETE	{"id": 161, "role": "admin", "token": "43c31d509e0359bce2f9d52e7a17fdac43a29464181809727dc69b02567808e8", "username": "roman", "created_at": "2025-12-09T17:28:55.341515"}	\N	postgres	2025-12-10 07:50:02.528069
606	refresh_tokens	DELETE	{"id": 163, "role": "manager", "token": "7f07acde7b0a51986c42859c141d27a158a2e85ab57e1158b0636990aae6c05d", "username": "anna_sokolova", "created_at": "2025-12-10T04:47:51.591143"}	\N	postgres	2025-12-10 07:50:02.528069
607	refresh_tokens	INSERT	\N	{"id": 166, "role": "admin", "token": "ac926712407d64244a5f65255f53ec68c39c62f0c03a9a6f79ffc7076c71f2da", "username": "artem_volkov", "created_at": "2025-12-10T05:48:52.423552"}	admin	2025-12-10 08:48:52.423552
608	refresh_tokens	DELETE	{"id": 166, "role": "admin", "token": "ac926712407d64244a5f65255f53ec68c39c62f0c03a9a6f79ffc7076c71f2da", "username": "artem_volkov", "created_at": "2025-12-10T05:48:52.423552"}	\N	admin	2025-12-10 08:48:57.268197
609	refresh_tokens	INSERT	\N	{"id": 167, "role": "admin", "token": "641066ca1d4ec67d9e60d818f0ca35b06da12a2d23dbf8bf40ea33bed7921af5", "username": "artem_volkov", "created_at": "2025-12-10T05:48:57.269461"}	admin	2025-12-10 08:48:57.269461
610	refresh_tokens	DELETE	{"id": 165, "role": "admin", "token": "243aca4b717c535a074fbe1fe4db79939871fb7744cc20189e491bdadd718c8c", "username": "roman", "created_at": "2025-12-10T04:48:01.537222"}	\N	admin	2025-12-10 08:52:46.574511
611	refresh_tokens	INSERT	\N	{"id": 168, "role": "admin", "token": "d35b5bd51637060f94d1f0276f0edaeb767fa5ccb3f408e5a1327515151b02e6", "username": "roman", "created_at": "2025-12-10T05:52:46.577638"}	admin	2025-12-10 08:52:46.577638
612	refresh_tokens	DELETE	{"id": 167, "role": "admin", "token": "641066ca1d4ec67d9e60d818f0ca35b06da12a2d23dbf8bf40ea33bed7921af5", "username": "artem_volkov", "created_at": "2025-12-10T05:48:57.269461"}	\N	admin	2025-12-10 09:05:15.53836
613	refresh_tokens	INSERT	\N	{"id": 169, "role": "admin", "token": "31400520ea619303bf8e6221ad68cefe3ed9ff8e438c5cbf46adc01dc63b3582", "username": "artem_volkov", "created_at": "2025-12-10T06:05:15.54683"}	admin	2025-12-10 09:05:15.54683
614	refresh_tokens	DELETE	{"id": 168, "role": "admin", "token": "d35b5bd51637060f94d1f0276f0edaeb767fa5ccb3f408e5a1327515151b02e6", "username": "roman", "created_at": "2025-12-10T05:52:46.577638"}	\N	admin	2025-12-10 09:08:24.666904
615	refresh_tokens	INSERT	\N	{"id": 170, "role": "manager", "token": "9f3f108c40aff2e9e39c02731d3d3e414a22bd01433c97323ad380fd2d576b9c", "username": "anna_sokolova", "created_at": "2025-12-10T06:08:30.704371"}	admin	2025-12-10 09:08:30.704371
616	refresh_tokens	DELETE	{"id": 170, "role": "manager", "token": "9f3f108c40aff2e9e39c02731d3d3e414a22bd01433c97323ad380fd2d576b9c", "username": "anna_sokolova", "created_at": "2025-12-10T06:08:30.704371"}	\N	admin	2025-12-10 09:11:00.89916
617	refresh_tokens	INSERT	\N	{"id": 171, "role": "manager", "token": "62d3273b1c2f2564dd41996a8679d2df90af939f2e25980f9d92417d8a9d96c3", "username": "anna_sokolova", "created_at": "2025-12-10T06:11:06.529829"}	admin	2025-12-10 09:11:06.529829
618	refresh_tokens	DELETE	{"id": 171, "role": "manager", "token": "62d3273b1c2f2564dd41996a8679d2df90af939f2e25980f9d92417d8a9d96c3", "username": "anna_sokolova", "created_at": "2025-12-10T06:11:06.529829"}	\N	admin	2025-12-10 09:13:25.579359
619	refresh_tokens	INSERT	\N	{"id": 172, "role": "admin", "token": "000a8ee7d0404fc833e6c634800d8c36e1f375200ba4d242c7e403674bfaca78", "username": "roman", "created_at": "2025-12-10T06:13:31.475488"}	admin	2025-12-10 09:13:31.475488
620	refresh_tokens	DELETE	{"id": 169, "role": "admin", "token": "31400520ea619303bf8e6221ad68cefe3ed9ff8e438c5cbf46adc01dc63b3582", "username": "artem_volkov", "created_at": "2025-12-10T06:05:15.54683"}	\N	admin	2025-12-10 10:07:47.745147
621	refresh_tokens	INSERT	\N	{"id": 173, "role": "admin", "token": "d83c5d2c3155982d3f1f92b676b94edb84a06ab1e07078b4cd50d72aab3d9478", "username": "artem_volkov", "created_at": "2025-12-10T07:07:47.753939"}	admin	2025-12-10 10:07:47.753939
622	refresh_tokens	DELETE	{"id": 172, "role": "admin", "token": "000a8ee7d0404fc833e6c634800d8c36e1f375200ba4d242c7e403674bfaca78", "username": "roman", "created_at": "2025-12-10T06:13:31.475488"}	\N	admin	2025-12-10 10:15:51.194817
623	refresh_tokens	INSERT	\N	{"id": 174, "role": "admin", "token": "4d9d7fb7da9b7c7db687cc2cc75ea001526026cbd3cbed1759628db85986ee09", "username": "roman", "created_at": "2025-12-10T07:15:51.199457"}	admin	2025-12-10 10:15:51.199457
624	refresh_tokens	INSERT	\N	{"id": 175, "role": "admin", "token": "2a4c49c433505c1a2f472f8879fdc47c8e7af8211c5867b17580a632da14d84f", "username": "roman", "created_at": "2025-12-10T07:15:51.199579"}	admin	2025-12-10 10:15:51.199579
625	refresh_tokens	DELETE	{"id": 174, "role": "admin", "token": "4d9d7fb7da9b7c7db687cc2cc75ea001526026cbd3cbed1759628db85986ee09", "username": "roman", "created_at": "2025-12-10T07:15:51.199457"}	\N	admin	2025-12-10 10:18:28.372981
626	refresh_tokens	INSERT	\N	{"id": 176, "role": "manager", "token": "0b894fcc2e44822e41e7d997d2b0f79e98ced992c833e5f3b5d282e12b177184", "username": "anna_sokolova", "created_at": "2025-12-10T07:18:35.999613"}	admin	2025-12-10 10:18:35.999613
627	refresh_tokens	DELETE	{"id": 176, "role": "manager", "token": "0b894fcc2e44822e41e7d997d2b0f79e98ced992c833e5f3b5d282e12b177184", "username": "anna_sokolova", "created_at": "2025-12-10T07:18:35.999613"}	\N	admin	2025-12-10 10:21:22.379968
628	refresh_tokens	INSERT	\N	{"id": 177, "role": "admin", "token": "f203907549a2e3319ebda42af8b66dc0ea27cafa6eaa470da1e7a07e6b61c702", "username": "roman", "created_at": "2025-12-10T07:21:26.578641"}	admin	2025-12-10 10:21:26.578641
629	refresh_tokens	DELETE	{"id": 173, "role": "admin", "token": "d83c5d2c3155982d3f1f92b676b94edb84a06ab1e07078b4cd50d72aab3d9478", "username": "artem_volkov", "created_at": "2025-12-10T07:07:47.753939"}	\N	admin	2025-12-10 11:07:16.619152
861	document_content	INSERT	\N	{"id": 18, "id_batch": 1, "quantity": 10, "id_document": 12}	admin	2025-12-14 09:44:31.38504
630	refresh_tokens	INSERT	\N	{"id": 178, "role": "admin", "token": "db94695ac58c98bda2a0b6ac2090df0cdf986fb771bf4046c593dd41d2c0c525", "username": "artem_volkov", "created_at": "2025-12-10T08:07:16.626705"}	admin	2025-12-10 11:07:16.626705
631	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765354206743876625_washing_machine.jpeg", "id_producer": 20, "id_product_category": 3}	admin	2025-12-10 11:10:06.747938
632	product	UPDATE	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "/static/products/1765354277653639797_7-.webp", "id_producer": 19, "id_product_category": 1}	admin	2025-12-10 11:11:17.655518
633	product	UPDATE	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "/static/products/1765354399815235298_33.jpeg", "id_producer": 21, "id_product_category": 8}	admin	2025-12-10 11:13:19.817225
634	product	UPDATE	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "/static/products/1765354467797030094_42.webp", "id_producer": 25, "id_product_category": 2}	admin	2025-12-10 11:14:27.798408
635	product	UPDATE	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "/static/products/placeholder.png", "id_producer": 24, "id_product_category": 1}	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "/static/products/1765354505917253083_36.jpg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-10 11:15:05.917799
636	product	UPDATE	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/1765354556503655135_36.jpg", "id_producer": 21, "id_product_category": 8}	admin	2025-12-10 11:15:56.506305
637	product	UPDATE	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/1765354556503655135_36.jpg", "id_producer": 21, "id_product_category": 8}	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/1765354561164319012_37.webp", "id_producer": 21, "id_product_category": 8}	admin	2025-12-10 11:16:01.165523
638	refresh_tokens	DELETE	{"id": 177, "role": "admin", "token": "f203907549a2e3319ebda42af8b66dc0ea27cafa6eaa470da1e7a07e6b61c702", "username": "roman", "created_at": "2025-12-10T07:21:26.578641"}	\N	admin	2025-12-10 11:16:41.541481
639	refresh_tokens	INSERT	\N	{"id": 179, "role": "manager", "token": "9a6d99a510bdf6f3a7c93cc27586ad4315c3424782510330a66bd9344c881fd9", "username": "anna_sokolova", "created_at": "2025-12-10T08:16:49.551471"}	admin	2025-12-10 11:16:49.551471
640	refresh_tokens	DELETE	{"id": 179, "role": "manager", "token": "9a6d99a510bdf6f3a7c93cc27586ad4315c3424782510330a66bd9344c881fd9", "username": "anna_sokolova", "created_at": "2025-12-10T08:16:49.551471"}	\N	admin	2025-12-10 11:25:48.651618
641	refresh_tokens	INSERT	\N	{"id": 180, "role": "admin", "token": "1579a3a6236343a5f0bc0750b4594a5a1283b86b9403953401bf5d9d1ddd7fc5", "username": "roman", "created_at": "2025-12-10T08:25:57.182241"}	admin	2025-12-10 11:25:57.182241
642	refresh_tokens	DELETE	{"id": 178, "role": "admin", "token": "db94695ac58c98bda2a0b6ac2090df0cdf986fb771bf4046c593dd41d2c0c525", "username": "artem_volkov", "created_at": "2025-12-10T08:07:16.626705"}	\N	admin	2025-12-10 11:27:25.750573
643	refresh_tokens	INSERT	\N	{"id": 181, "role": "admin", "token": "fc34f3e30d4f944ee1ebfc7a65204af20cf426f6590f5940665d7aaa3136d38d", "username": "artem_volkov", "created_at": "2025-12-10T08:27:25.754516"}	admin	2025-12-10 11:27:25.754516
644	role	INSERT	\N	{"id": 5, "name": "тест", "sys_role": "test", "description": "тест"}	admin	2025-12-10 11:48:58.736978
645	role	UPDATE	{"id": 5, "name": "тест", "sys_role": "test", "description": "тест"}	{"id": 5, "name": "тест1", "sys_role": "test", "description": "тест"}	admin	2025-12-10 11:49:22.467503
646	role	DELETE	{"id": 5, "name": "тест1", "sys_role": "test", "description": "тест"}	\N	admin	2025-12-10 11:49:30.14078
647	sys_user	INSERT	\N	{"id": 8, "login": "рома", "id_role": 1, "id_employee": 11, "password_hash": "$2a$10$D34u6E7wlrn3V4vgWC73Tuwa.spqssMjSRSXxjP9tOMRrVtaV9F.W"}	admin	2025-12-10 12:20:39.150183
648	refresh_tokens	DELETE	{"id": 180, "role": "admin", "token": "1579a3a6236343a5f0bc0750b4594a5a1283b86b9403953401bf5d9d1ddd7fc5", "username": "roman", "created_at": "2025-12-10T08:25:57.182241"}	\N	admin	2025-12-10 12:20:43.290557
649	refresh_tokens	INSERT	\N	{"id": 182, "role": "moderator", "token": "d168373b13a18372315b879852924803a7d313ad197767b459d5ed0c15be823e", "username": "рома", "created_at": "2025-12-10T09:20:48.789553"}	admin	2025-12-10 12:20:48.789553
650	refresh_tokens	DELETE	{"id": 182, "role": "moderator", "token": "d168373b13a18372315b879852924803a7d313ad197767b459d5ed0c15be823e", "username": "рома", "created_at": "2025-12-10T09:20:48.789553"}	\N	admin	2025-12-10 12:21:28.064562
651	refresh_tokens	INSERT	\N	{"id": 183, "role": "admin", "token": "d3029073b5bdd969dace00795bf615276e4f335c8ab493d9a62cd245f471187d", "username": "roman", "created_at": "2025-12-10T09:21:34.007808"}	admin	2025-12-10 12:21:34.007808
652	sys_user	DELETE	{"id": 8, "login": "рома", "id_role": 1, "id_employee": 11, "password_hash": "$2a$10$D34u6E7wlrn3V4vgWC73Tuwa.spqssMjSRSXxjP9tOMRrVtaV9F.W"}	\N	admin	2025-12-10 12:21:42.387522
653	sys_user	DELETE	{"id": 4, "login": "manager_login", "id_role": 2, "id_employee": 4, "password_hash": "$2a$10$Y5LoyZuEZ0j/GMkOtP6j3et/Ir8BBkMIjnIuJdHZ3VFT7ioiEhmbu"}	\N	admin	2025-12-10 12:26:57.530247
715	product	DELETE	{"id": 60, "name": "тест", "image_url": "", "id_producer": 3, "id_product_category": 2}	\N	postgres	2025-12-10 15:56:28.190415
659	refresh_tokens	DELETE	{"id": 185, "role": "manager", "token": "fc9bd9901206160d89f64a4f20687598befe31e9e5c79183cb3ff66af7e54ce1", "username": "anna_sokolova", "created_at": "2025-12-10T09:34:37.725926"}	\N	admin	2025-12-10 12:34:49.102708
796	refresh_tokens	DELETE	{"id": 213, "role": "admin", "token": "8832c2a3675e55f9d61fcc23ac850579bad8e936c21a87fae14db6affd9df26f", "username": "roman", "created_at": "2025-12-10T19:41:05.045515"}	\N	admin	2025-12-10 19:54:23.808705
660	refresh_tokens	INSERT	\N	{"id": 186, "role": "moderator", "token": "d8aa3644d12310df490d25020b279c1f7e8f919d6b15cf1f5eac912b6eb2e75c", "username": "moderator_login", "created_at": "2025-12-10T09:34:59.826734"}	admin	2025-12-10 12:34:59.826734
661	refresh_tokens	DELETE	{"id": 186, "role": "moderator", "token": "d8aa3644d12310df490d25020b279c1f7e8f919d6b15cf1f5eac912b6eb2e75c", "username": "moderator_login", "created_at": "2025-12-10T09:34:59.826734"}	\N	admin	2025-12-10 12:35:13.403562
662	refresh_tokens	INSERT	\N	{"id": 187, "role": "admin", "token": "6120cc95a7d7df646b85396bbafe92ccc05497b3ef07bfe9f111ec208765da3d", "username": "roman", "created_at": "2025-12-10T09:35:17.731862"}	admin	2025-12-10 12:35:17.731862
664	employee	INSERT	\N	{"id": 16, "inn": "111111121111", "surname": "Иванов", "firstname": "Иван", "id_gender": 1, "birth_date": "2025-12-03", "id_address": 2, "patronymic": "Иванович", "id_position": 4, "phone_number": "+7 911 111-11-11"}	admin	2025-12-10 13:00:58.092958
665	employee	UPDATE	{"id": 16, "inn": "111111121111", "surname": "Иванов", "firstname": "Иван", "id_gender": 1, "birth_date": "2025-12-03", "id_address": 2, "patronymic": "Иванович", "id_position": 4, "phone_number": "+7 911 111-11-11"}	{"id": 16, "inn": "111111121111", "surname": "Иванов", "firstname": "Иван", "id_gender": 2, "birth_date": "2025-12-03", "id_address": 2, "patronymic": "Иванович", "id_position": 4, "phone_number": "+7 911 111-11-11"}	admin	2025-12-10 13:01:11.126115
666	employee	DELETE	{"id": 16, "inn": "111111121111", "surname": "Иванов", "firstname": "Иван", "id_gender": 2, "birth_date": "2025-12-03", "id_address": 2, "patronymic": "Иванович", "id_position": 4, "phone_number": "+7 911 111-11-11"}	\N	admin	2025-12-10 13:01:21.137538
667	employee	DELETE	{"id": 11, "inn": "222222222222", "surname": "a", "firstname": "a", "id_gender": 1, "birth_date": "0001-01-01", "id_address": 1, "patronymic": "a", "id_position": 1, "phone_number": "2222222222222222"}	\N	admin	2025-12-10 13:02:39.14873
668	employee	DELETE	{"id": 10, "inn": "111111111111", "surname": "test2", "firstname": "test2", "id_gender": 1, "birth_date": "2025-01-01", "id_address": 1, "patronymic": "test2", "id_position": 1, "phone_number": "1111111111111111"}	\N	admin	2025-12-10 13:02:55.668515
669	employee	UPDATE	{"id": 1, "inn": "525201234567", "surname": "Волчков", "firstname": "Артем", "id_gender": 1, "birth_date": "1985-05-12", "id_address": 1, "patronymic": "Дмитриевич", "id_position": 1, "phone_number": "+7 911 123-45-67"}	{"id": 1, "inn": "525201234567", "surname": "Волков", "firstname": "Артем", "id_gender": 1, "birth_date": "1985-05-12", "id_address": 1, "patronymic": "Дмитриевич", "id_position": 1, "phone_number": "+7 911 123-45-67"}	admin	2025-12-10 13:03:11.314621
670	refresh_tokens	DELETE	{"id": 187, "role": "admin", "token": "6120cc95a7d7df646b85396bbafe92ccc05497b3ef07bfe9f111ec208765da3d", "username": "roman", "created_at": "2025-12-10T09:35:17.731862"}	\N	admin	2025-12-10 13:03:32.460119
671	refresh_tokens	INSERT	\N	{"id": 188, "role": "admin", "token": "9123ed7125708448a527e30324b616093c4c9810e20a5c32bd01f641bfdfef5d", "username": "artem_volkov", "created_at": "2025-12-10T10:03:47.381985"}	admin	2025-12-10 13:03:47.381985
672	refresh_tokens	INSERT	\N	{"id": 189, "role": "admin", "token": "d99f5c8751efaa0d24939686201cf9f3059e26a5a959e212e6d855c1bdda5068", "username": "artem_volkov", "created_at": "2025-12-10T10:04:24.10852"}	admin	2025-12-10 13:04:24.10852
674	refresh_tokens	DELETE	{"id": 189, "role": "admin", "token": "d99f5c8751efaa0d24939686201cf9f3059e26a5a959e212e6d855c1bdda5068", "username": "artem_volkov", "created_at": "2025-12-10T10:04:24.10852"}	\N	admin	2025-12-10 13:05:22.331585
675	refresh_tokens	INSERT	\N	{"id": 190, "role": "moderator", "token": "23340bc69091007c9fbc940af880eb0122f8ae59e2f764c2add6ffb0b21724fe", "username": "artem_volkov", "created_at": "2025-12-10T10:05:28.302346"}	admin	2025-12-10 13:05:28.302346
676	refresh_tokens	DELETE	{"id": 190, "role": "moderator", "token": "23340bc69091007c9fbc940af880eb0122f8ae59e2f764c2add6ffb0b21724fe", "username": "artem_volkov", "created_at": "2025-12-10T10:05:28.302346"}	\N	admin	2025-12-10 13:06:16.588973
673	sys_user	UPDATE	{"id": 1, "login": "artem_volkov", "id_role": 4, "id_employee": 1, "password_hash": "$2a$10$z9I2uGqAHHc5paoMn9T5yOXLEEDnWMj/Pmwegsv/vdagYct7RKN1O"}	{"id": 1, "login": "artem_volkov", "id_role": 1, "id_employee": 1, "password_hash": "$2a$10$z9I2uGqAHHc5paoMn9T5yOXLEEDnWMj/Pmwegsv/vdagYct7RKN1O"}	postgres	2025-12-10 13:04:59.774149
677	refresh_tokens	INSERT	\N	{"id": 191, "role": "admin", "token": "38ec2ca0cee453aaa20b828c8625649b9c63cc3f0f5da3db39cd8075b6c57c57", "username": "roman", "created_at": "2025-12-10T10:55:12.51442"}	admin	2025-12-10 13:55:12.51442
678	employee	INSERT	\N	{"id": 17, "inn": "111112213111", "surname": "test", "firstname": "test", "id_gender": 3, "birth_date": "2001-06-16", "id_address": 24, "patronymic": "test", "id_position": 3, "phone_number": "+7 900 000-00-00"}	admin	2025-12-10 13:57:59.686401
679	sys_user	INSERT	\N	{"id": 9, "login": "test", "id_role": 2, "id_employee": 17, "password_hash": "$2a$10$jOiUC7j6gA0qCYuxQRUEOeN62hUua/rz6OlrmQuGfGRPbB0rZ8o02"}	admin	2025-12-10 13:58:25.155906
680	refresh_tokens	DELETE	{"id": 191, "role": "admin", "token": "38ec2ca0cee453aaa20b828c8625649b9c63cc3f0f5da3db39cd8075b6c57c57", "username": "roman", "created_at": "2025-12-10T10:55:12.51442"}	\N	admin	2025-12-10 13:58:29.507052
681	refresh_tokens	INSERT	\N	{"id": 192, "role": "manager", "token": "35d27155c74fef0c7c8b0a1f844f6e59baf1673a4c6959d56c26ce8dc3dfa6a1", "username": "test", "created_at": "2025-12-10T10:58:35.209923"}	admin	2025-12-10 13:58:35.209923
682	refresh_tokens	DELETE	{"id": 192, "role": "manager", "token": "35d27155c74fef0c7c8b0a1f844f6e59baf1673a4c6959d56c26ce8dc3dfa6a1", "username": "test", "created_at": "2025-12-10T10:58:35.209923"}	\N	admin	2025-12-10 13:59:10.698179
683	refresh_tokens	INSERT	\N	{"id": 193, "role": "moderator", "token": "65d0640c347d31d37d5f86af7c37ac717d85df3e47fe7eb3ed4155bd2086f101", "username": "artem_volkov", "created_at": "2025-12-10T10:59:43.364798"}	admin	2025-12-10 13:59:43.364798
684	refresh_tokens	DELETE	{"id": 193, "role": "moderator", "token": "65d0640c347d31d37d5f86af7c37ac717d85df3e47fe7eb3ed4155bd2086f101", "username": "artem_volkov", "created_at": "2025-12-10T10:59:43.364798"}	\N	admin	2025-12-10 14:00:02.605159
685	refresh_tokens	INSERT	\N	{"id": 194, "role": "admin", "token": "616ee039f4bf98b8b926013f67fa81a96e9ecac51757739c17e70172807d0818", "username": "roman", "created_at": "2025-12-10T11:00:06.783251"}	admin	2025-12-10 14:00:06.783251
686	refresh_tokens	DELETE	{"id": 184, "role": "admin", "token": "260f321ad83c08bae3f50f72a22aa90a04f4001d8e70a30b7ab0c1da368afcfd", "username": "artem_volkov", "created_at": "2025-12-10T09:27:59.032789"}	\N	admin	2025-12-10 14:01:07.363761
687	refresh_tokens	INSERT	\N	{"id": 195, "role": "admin", "token": "35aa425010e4b3d1566b561bd946f53ad478f2bb34b9fa0d5e8f1d0b62b27487", "username": "artem_volkov", "created_at": "2025-12-10T11:01:07.371037"}	admin	2025-12-10 14:01:07.371037
688	refresh_tokens	INSERT	\N	{"id": 196, "role": "admin", "token": "bac59e1c13b36de9b379e33ea6764869798c29c74a92849e5486cb6e5845446b", "username": "roman", "created_at": "2025-12-10T11:11:13.638082"}	admin	2025-12-10 14:11:13.638082
690	position	INSERT	\N	{"id": 11, "name": "", "description": ""}	postgres	2025-12-10 14:42:16.624822
691	position	INSERT	\N	{"id": 12, "name": "", "description": ""}	postgres	2025-12-10 14:42:16.624822
692	position	INSERT	\N	{"id": 13, "name": "", "description": ""}	postgres	2025-12-10 14:42:16.624822
693	position	INSERT	\N	{"id": 14, "name": "", "description": ""}	postgres	2025-12-10 14:42:16.624822
694	position	INSERT	\N	{"id": 15, "name": "", "description": ""}	postgres	2025-12-10 14:42:26.037612
695	refresh_tokens	INSERT	\N	{"id": 197, "role": "admin", "token": "cca2e5c4c7021433cdb5a12fbeee568cc8c0ecd1e2b5955bb75b4d43f6799733", "username": "roman", "created_at": "2025-12-10T11:48:08.735993"}	admin	2025-12-10 14:48:08.735993
696	position	DELETE	{"id": 10, "name": "", "description": ""}	\N	postgres	2025-12-10 14:50:14.652158
697	position	DELETE	{"id": 11, "name": "", "description": ""}	\N	postgres	2025-12-10 14:50:14.652158
698	position	DELETE	{"id": 12, "name": "", "description": ""}	\N	postgres	2025-12-10 14:50:14.652158
699	position	DELETE	{"id": 13, "name": "", "description": ""}	\N	postgres	2025-12-10 14:50:14.652158
700	position	DELETE	{"id": 14, "name": "", "description": ""}	\N	postgres	2025-12-10 14:50:14.652158
701	position	DELETE	{"id": 15, "name": "", "description": ""}	\N	postgres	2025-12-10 14:50:14.652158
702	refresh_tokens	INSERT	\N	{"id": 198, "role": "admin", "token": "def2e6b322bee4116cb407d5062a10f588c3da0feb927d2d31c98bc9aacbd758", "username": "roman", "created_at": "2025-12-10T11:54:06.583138"}	admin	2025-12-10 14:54:06.583138
703	address	INSERT	\N	{"id": 26, "city": "тест", "region": "тест", "street": "тест", "subject": "тест", "building": 1}	admin	2025-12-10 14:57:15.529695
704	address	UPDATE	{"id": 26, "city": "тест", "region": "тест", "street": "тест", "subject": "тест", "building": 1}	{"id": 26, "city": "тес", "region": "тест", "street": "тест", "subject": "тест", "building": 1}	admin	2025-12-10 14:57:30.704536
705	address	DELETE	{"id": 26, "city": "тес", "region": "тест", "street": "тест", "subject": "тест", "building": 1}	\N	admin	2025-12-10 14:57:38.180615
706	refresh_tokens	DELETE	{"id": 195, "role": "admin", "token": "35aa425010e4b3d1566b561bd946f53ad478f2bb34b9fa0d5e8f1d0b62b27487", "username": "artem_volkov", "created_at": "2025-12-10T11:01:07.371037"}	\N	admin	2025-12-10 15:04:50.552673
707	refresh_tokens	INSERT	\N	{"id": 199, "role": "admin", "token": "0e9bae1bacdd4c705a529e7c202c56e2f072f4dd5c768d6743ba3f8e1ddc6108", "username": "artem_volkov", "created_at": "2025-12-10T12:04:50.5637"}	admin	2025-12-10 15:04:50.5637
708	refresh_tokens	DELETE	{"id": 198, "role": "admin", "token": "def2e6b322bee4116cb407d5062a10f588c3da0feb927d2d31c98bc9aacbd758", "username": "roman", "created_at": "2025-12-10T11:54:06.583138"}	\N	admin	2025-12-10 15:54:30.02306
709	refresh_tokens	INSERT	\N	{"id": 200, "role": "admin", "token": "f586dcf7f2e3e55923bf03c439e84982bbe607509a27ef666df1cce238592bfc", "username": "roman", "created_at": "2025-12-10T12:54:30.047903"}	admin	2025-12-10 15:54:30.047903
710	product	INSERT	\N	{"id": 57, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 15:54:30.065446
711	product	INSERT	\N	{"id": 58, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 15:54:45.204504
712	product	INSERT	\N	{"id": 59, "name": "тест", "image_url": "", "id_producer": 3, "id_product_category": 2}	admin	2025-12-10 15:55:42.732558
719	product	UPDATE	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 15:58:37.197515
720	product	UPDATE	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 16:02:43.689711
721	product	UPDATE	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 16:03:57.165964
722	product	UPDATE	{"id": 61, "name": "тест", "image_url": "", "id_producer": 2, "id_product_category": 1}	{"id": 61, "name": "тест", "image_url": "/static/products/1765371837304980715_ChatGPT Image 1 дек. 2025 г., 20_44_55.png", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 16:03:57.311062
723	product	INSERT	\N	{"id": 62, "name": "test", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 3}	admin	2025-12-10 16:04:40.895658
724	product	UPDATE	{"id": 62, "name": "test", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 3}	{"id": 62, "name": "test", "image_url": "/static/products/1765371880975374596_photo_2025-12-01 19.13.31.jpeg", "id_producer": 21, "id_product_category": 3}	admin	2025-12-10 16:04:40.978631
725	product	UPDATE	{"id": 62, "name": "test", "image_url": "/static/products/1765371880975374596_photo_2025-12-01 19.13.31.jpeg", "id_producer": 21, "id_product_category": 3}	{"id": 62, "name": "tes", "image_url": "", "id_producer": 21, "id_product_category": 3}	admin	2025-12-10 16:04:48.282274
726	product	UPDATE	{"id": 62, "name": "tes", "image_url": "", "id_producer": 21, "id_product_category": 3}	{"id": 62, "name": "tes", "image_url": "", "id_producer": 21, "id_product_category": 3}	admin	2025-12-10 16:05:14.001898
727	product	UPDATE	{"id": 62, "name": "tes", "image_url": "", "id_producer": 21, "id_product_category": 3}	{"id": 62, "name": "tes", "image_url": "/static/products/1765371914141222875_placeholder.png", "id_producer": 21, "id_product_category": 3}	admin	2025-12-10 16:05:14.151675
797	refresh_tokens	INSERT	\N	{"id": 214, "role": "moderator", "token": "5fcf6d8687bef4a39aa9a45600f67b217aa242d8d4b48dcc3491edb08df78a6b", "username": "moderator_login", "created_at": "2025-12-10T19:54:30.673316"}	admin	2025-12-10 19:54:30.673316
728	product	UPDATE	{"id": 62, "name": "tes", "image_url": "/static/products/1765371914141222875_placeholder.png", "id_producer": 21, "id_product_category": 3}	{"id": 62, "name": "te", "image_url": "", "id_producer": 21, "id_product_category": 3}	admin	2025-12-10 16:05:18.476539
729	product	DELETE	{"id": 62, "name": "te", "image_url": "", "id_producer": 21, "id_product_category": 3}	\N	admin	2025-12-10 16:10:47.103671
730	product	DELETE	{"id": 61, "name": "тест", "image_url": "/static/products/1765371837304980715_ChatGPT Image 1 дек. 2025 г., 20_44_55.png", "id_producer": 2, "id_product_category": 1}	\N	admin	2025-12-10 16:11:54.779179
731	product	INSERT	\N	{"id": 63, "name": "тест", "image_url": "/static/products/placeholder.png", "id_producer": 1, "id_product_category": 1}	admin	2025-12-10 16:12:08.625531
732	product	UPDATE	{"id": 63, "name": "тест", "image_url": "/static/products/placeholder.png", "id_producer": 1, "id_product_category": 1}	{"id": 63, "name": "тест", "image_url": "/static/products/1765372328739177387_photo_2025-11-28 22.11.30.jpeg", "id_producer": 1, "id_product_category": 1}	admin	2025-12-10 16:12:08.74213
733	product	UPDATE	{"id": 63, "name": "тест", "image_url": "/static/products/1765372328739177387_photo_2025-11-28 22.11.30.jpeg", "id_producer": 1, "id_product_category": 1}	{"id": 63, "name": "тес", "image_url": "/static/products/1765372328739177387_photo_2025-11-28 22.11.30.jpeg", "id_producer": 1, "id_product_category": 1}	admin	2025-12-10 16:12:13.65638
734	product	UPDATE	{"id": 63, "name": "тес", "image_url": "/static/products/1765372328739177387_photo_2025-11-28 22.11.30.jpeg", "id_producer": 1, "id_product_category": 1}	{"id": 63, "name": "тес", "image_url": "/static/products/1765372328739177387_photo_2025-11-28 22.11.30.jpeg", "id_producer": 2, "id_product_category": 1}	admin	2025-12-10 16:12:17.939922
735	product	DELETE	{"id": 63, "name": "тес", "image_url": "/static/products/1765372328739177387_photo_2025-11-28 22.11.30.jpeg", "id_producer": 2, "id_product_category": 1}	\N	admin	2025-12-10 16:12:21.133785
736	product	INSERT	\N	{"id": 64, "name": "те", "image_url": "/static/products/placeholder.png", "id_producer": 5, "id_product_category": 2}	admin	2025-12-10 16:12:40.344099
737	product	DELETE	{"id": 64, "name": "те", "image_url": "/static/products/placeholder.png", "id_producer": 5, "id_product_category": 2}	\N	admin	2025-12-10 16:12:43.92176
738	refresh_tokens	DELETE	{"id": 200, "role": "admin", "token": "f586dcf7f2e3e55923bf03c439e84982bbe607509a27ef666df1cce238592bfc", "username": "roman", "created_at": "2025-12-10T12:54:30.047903"}	\N	admin	2025-12-10 16:22:16.959593
739	refresh_tokens	INSERT	\N	{"id": 201, "role": "manager", "token": "4a57c27bea5495e62cb3be3f8dda576706c5db9c0c668fd50d4fa7d3ddb8e0fe", "username": "anna_sokolova", "created_at": "2025-12-10T13:22:23.466726"}	admin	2025-12-10 16:22:23.466726
740	refresh_tokens	DELETE	{"id": 201, "role": "manager", "token": "4a57c27bea5495e62cb3be3f8dda576706c5db9c0c668fd50d4fa7d3ddb8e0fe", "username": "anna_sokolova", "created_at": "2025-12-10T13:22:23.466726"}	\N	admin	2025-12-10 16:23:12.551108
741	refresh_tokens	INSERT	\N	{"id": 202, "role": "moderator", "token": "ad0c8ce65da7299d59769e98dec9daa5e1b91d04aea060ba368f8f686d0cc4c4", "username": "moderator_login", "created_at": "2025-12-10T13:23:29.447706"}	admin	2025-12-10 16:23:29.447706
742	refresh_tokens	DELETE	{"id": 202, "role": "moderator", "token": "ad0c8ce65da7299d59769e98dec9daa5e1b91d04aea060ba368f8f686d0cc4c4", "username": "moderator_login", "created_at": "2025-12-10T13:23:29.447706"}	\N	admin	2025-12-10 16:24:04.344023
743	refresh_tokens	INSERT	\N	{"id": 203, "role": "admin", "token": "598e6a2f016fffe4094993aad1207027e87bdede47d2f79e0dafb4859f57b21e", "username": "roman", "created_at": "2025-12-10T13:24:08.564651"}	admin	2025-12-10 16:24:08.564651
744	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765354206743876625_washing_machine.jpeg", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	admin	2025-12-10 16:27:03.963448
745	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765373224025730926_8.jpeg", "id_producer": 20, "id_product_category": 3}	admin	2025-12-10 16:27:04.09224
748	refresh_tokens	DELETE	{"id": 199, "role": "admin", "token": "0e9bae1bacdd4c705a529e7c202c56e2f072f4dd5c768d6743ba3f8e1ddc6108", "username": "artem_volkov", "created_at": "2025-12-10T12:04:50.5637"}	\N	admin	2025-12-10 16:44:46.782929
749	refresh_tokens	INSERT	\N	{"id": 204, "role": "admin", "token": "85516cd64f8aa03b58757e5278c437d23604ccb86b06031a66152a9e53fee6d6", "username": "artem_volkov", "created_at": "2025-12-10T16:44:46.78871"}	admin	2025-12-10 16:44:46.78871
750	product_category	INSERT	\N	{"id": 10, "name": "тест"}	admin	2025-12-10 16:52:44.523289
751	product_category	UPDATE	{"id": 10, "name": "тест"}	{"id": 10, "name": "тес"}	admin	2025-12-10 16:53:53.871093
752	product_category	DELETE	{"id": 10, "name": "тес"}	\N	admin	2025-12-10 16:53:57.537549
753	product_category	INSERT	\N	{"id": 11, "name": "test"}	admin	2025-12-10 16:54:07.809085
754	product	INSERT	\N	{"id": 65, "name": "test", "image_url": "/static/products/placeholder.png", "id_producer": 2, "id_product_category": 11}	admin	2025-12-10 16:54:17.651653
755	product	DELETE	{"id": 65, "name": "test", "image_url": "/static/products/placeholder.png", "id_producer": 2, "id_product_category": 11}	\N	admin	2025-12-10 16:54:37.285683
756	product_category	DELETE	{"id": 11, "name": "test"}	\N	admin	2025-12-10 16:54:45.682839
757	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "+7 921 693-19-54"}	admin	2025-12-10 16:56:12.215641
798	refresh_tokens	INSERT	\N	{"id": 215, "role": "admin", "token": "a5e258eef5226161bdab1d10e48a41b74a858c48e73ee0fca55722a2af558598", "username": "roman", "created_at": "2025-12-11T09:36:43.690361"}	admin	2025-12-11 09:36:43.690361
758	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "+7 921 693-19-54"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	admin	2025-12-10 16:56:19.002557
759	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "+7 921 693-19-54"}	admin	2025-12-10 16:56:24.608054
760	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 4, "phone_number": "+7 921 693-19-54"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	admin	2025-12-10 16:56:41.232033
761	document_category	INSERT	\N	{"id": 5, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
762	document_category	INSERT	\N	{"id": 6, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
763	document_category	INSERT	\N	{"id": 7, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
764	document_category	INSERT	\N	{"id": 8, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
765	document_category	INSERT	\N	{"id": 9, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
766	document_category	INSERT	\N	{"id": 10, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
767	document_category	INSERT	\N	{"id": 11, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
768	document_category	INSERT	\N	{"id": 12, "name": "", "description": ""}	postgres	2025-12-10 17:05:02.961683
769	document_category	INSERT	\N	{"id": 13, "name": "test", "description": "test"}	admin	2025-12-10 17:05:16.354462
770	document_category	UPDATE	{"id": 13, "name": "test", "description": "test"}	{"id": 13, "name": "tes", "description": "test"}	admin	2025-12-10 17:05:21.274623
771	document_category	DELETE	{"id": 13, "name": "tes", "description": "test"}	\N	admin	2025-12-10 17:05:26.44672
772	document_category	DELETE	{"id": 5, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
773	document_category	DELETE	{"id": 6, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
774	document_category	DELETE	{"id": 7, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
775	document_category	DELETE	{"id": 8, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
776	document_category	DELETE	{"id": 9, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
777	document_category	DELETE	{"id": 10, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
778	document_category	DELETE	{"id": 11, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
779	document_category	DELETE	{"id": 12, "name": "", "description": ""}	\N	postgres	2025-12-10 17:05:39.177672
780	refresh_tokens	DELETE	{"id": 203, "role": "admin", "token": "598e6a2f016fffe4094993aad1207027e87bdede47d2f79e0dafb4859f57b21e", "username": "roman", "created_at": "2025-12-10T13:24:08.564651"}	\N	admin	2025-12-10 17:25:17.986729
781	refresh_tokens	INSERT	\N	{"id": 205, "role": "admin", "token": "96cfae208f7a7f7f604a5ceaa3af06ae5a3270606d195f9458d2f76c2d7bac00", "username": "roman", "created_at": "2025-12-10T17:25:17.993073"}	admin	2025-12-10 17:25:17.993073
782	refresh_tokens	INSERT	\N	{"id": 206, "role": "admin", "token": "a86dcf9b9b29cc3b90d43c609d82cb51f7b0d4593b00930be41c1c84fe122c17", "username": "roman", "created_at": "2025-12-10T17:25:17.993127"}	admin	2025-12-10 17:25:17.993127
783	producer	INSERT	\N	{"id": 27, "inn": "1112213131", "name": "test", "surname": "test", "firstname": "test", "id_address": 18, "patronymic": "test"}	admin	2025-12-10 17:25:40.791467
784	producer	UPDATE	{"id": 27, "inn": "1112213131", "name": "test", "surname": "test", "firstname": "test", "id_address": 18, "patronymic": "test"}	{"id": 27, "inn": "1112213141", "name": "tes", "surname": "test", "firstname": "tes", "id_address": 1, "patronymic": "test"}	admin	2025-12-10 17:25:50.109583
785	producer	DELETE	{"id": 27, "inn": "1112213141", "name": "tes", "surname": "test", "firstname": "tes", "id_address": 1, "patronymic": "test"}	\N	admin	2025-12-10 17:25:54.398809
786	refresh_tokens	INSERT	\N	{"id": 207, "role": "admin", "token": "667af1d546a4a3b4f5888b3e57ab05ea1f13c35a4f335341791d00007b566d98", "username": "roman", "created_at": "2025-12-10T17:36:57.226631"}	admin	2025-12-10 17:36:57.226631
787	refresh_tokens	DELETE	{"id": 207, "role": "admin", "token": "667af1d546a4a3b4f5888b3e57ab05ea1f13c35a4f335341791d00007b566d98", "username": "roman", "created_at": "2025-12-10T17:36:57.226631"}	\N	admin	2025-12-10 17:46:37.43651
788	refresh_tokens	INSERT	\N	{"id": 208, "role": "admin", "token": "ae9f678dfa0b94c45ee4eace5f096fb66b0e589e24f8fdb9808edf3c0a928446", "username": "roman", "created_at": "2025-12-10T17:46:45.282233"}	admin	2025-12-10 17:46:45.282233
789	refresh_tokens	DELETE	{"id": 204, "role": "admin", "token": "85516cd64f8aa03b58757e5278c437d23604ccb86b06031a66152a9e53fee6d6", "username": "artem_volkov", "created_at": "2025-12-10T16:44:46.78871"}	\N	admin	2025-12-10 17:50:38.351278
790	refresh_tokens	INSERT	\N	{"id": 209, "role": "admin", "token": "d18b4e19a850007353a0d2a9a9a884eca2a6c87e2f48098416b3407ea79309ac", "username": "artem_volkov", "created_at": "2025-12-10T17:50:38.361631"}	admin	2025-12-10 17:50:38.361631
791	refresh_tokens	DELETE	{"id": 208, "role": "admin", "token": "ae9f678dfa0b94c45ee4eace5f096fb66b0e589e24f8fdb9808edf3c0a928446", "username": "roman", "created_at": "2025-12-10T17:46:45.282233"}	\N	admin	2025-12-10 18:02:00.900974
792	refresh_tokens	INSERT	\N	{"id": 210, "role": "manager", "token": "3f11095c1cd268b904d8a2d421eaea467aa0b1d76ce039a188685b182045d47d", "username": "anna_sokolova", "created_at": "2025-12-10T18:02:08.424851"}	admin	2025-12-10 18:02:08.424851
793	refresh_tokens	INSERT	\N	{"id": 211, "role": "admin", "token": "2fddf117639cbd38b120cf530cf91640436ba836171c04d830454c9c1e9da07a", "username": "roman", "created_at": "2025-12-10T19:21:19.060457"}	admin	2025-12-10 19:21:19.060457
794	refresh_tokens	INSERT	\N	{"id": 212, "role": "admin", "token": "d5e2026a3300963a284ffcb07262d42fbf72e5a6b5c8898fe1bc4c92607af8c7", "username": "roman", "created_at": "2025-12-10T19:28:53.799891"}	admin	2025-12-10 19:28:53.799891
795	refresh_tokens	INSERT	\N	{"id": 213, "role": "admin", "token": "8832c2a3675e55f9d61fcc23ac850579bad8e936c21a87fae14db6affd9df26f", "username": "roman", "created_at": "2025-12-10T19:41:05.045515"}	admin	2025-12-10 19:41:05.045515
799	refresh_tokens	DELETE	{"id": 175, "role": "admin", "token": "2a4c49c433505c1a2f472f8879fdc47c8e7af8211c5867b17580a632da14d84f", "username": "roman", "created_at": "2025-12-10T07:15:51.199579"}	\N	admin	2025-12-11 10:32:18.496088
800	refresh_tokens	INSERT	\N	{"id": 216, "role": "admin", "token": "a484ed8e4683304072c53e7d85b7282980de9485b1580fd631424433519c592f", "username": "roman", "created_at": "2025-12-11T10:32:18.501816"}	admin	2025-12-11 10:32:18.501816
801	refresh_tokens	DELETE	{"id": 215, "role": "admin", "token": "a5e258eef5226161bdab1d10e48a41b74a858c48e73ee0fca55722a2af558598", "username": "roman", "created_at": "2025-12-11T09:36:43.690361"}	\N	admin	2025-12-11 10:36:44.637719
802	refresh_tokens	INSERT	\N	{"id": 217, "role": "admin", "token": "7f5be2c7ef3cb5d5a51baefbc5bc4e2c532095fc24d0498946013e6db9e96831", "username": "roman", "created_at": "2025-12-11T10:36:44.644326"}	admin	2025-12-11 10:36:44.644326
803	refresh_tokens	INSERT	\N	{"id": 218, "role": "admin", "token": "de2a622bfb09dc652cd4842a42427144c77815f79442705a7de8a9f6684acd11", "username": "roman", "created_at": "2025-12-11T10:36:44.644384"}	admin	2025-12-11 10:36:44.644384
804	refresh_tokens	INSERT	\N	{"id": 219, "role": "admin", "token": "7a88c6d866e0e2b2d6c22fc7b6e1c0d55e320bce5067e641b36e29aee91d1cd6", "username": "roman", "created_at": "2025-12-11T10:36:44.644516"}	admin	2025-12-11 10:36:44.644516
805	refresh_tokens	INSERT	\N	{"id": 220, "role": "admin", "token": "0201dd26389492cea2ec3187e01e4f076ffe441c4589a33ea6fae3029b36e9ac", "username": "roman", "created_at": "2025-12-11T10:36:44.644719"}	admin	2025-12-11 10:36:44.644719
806	employee	INSERT	\N	{"id": 18, "inn": "111313131234", "surname": "тест", "firstname": "тест", "id_gender": 3, "birth_date": "2025-12-03", "id_address": 8, "patronymic": "тест", "id_position": 4, "phone_number": "+7 921 693-15-43"}	admin	2025-12-11 10:37:20.465064
807	employee	UPDATE	{"id": 18, "inn": "111313131234", "surname": "тест", "firstname": "тест", "id_gender": 3, "birth_date": "2025-12-03", "id_address": 8, "patronymic": "тест", "id_position": 4, "phone_number": "+7 921 693-15-43"}	{"id": 18, "inn": "111313141234", "surname": "тест", "firstname": "тес", "id_gender": 3, "birth_date": "2025-12-26", "id_address": 8, "patronymic": "тест", "id_position": 2, "phone_number": "+7 921 693-15-41"}	admin	2025-12-11 10:37:36.01111
808	employee	DELETE	{"id": 18, "inn": "111313141234", "surname": "тест", "firstname": "тес", "id_gender": 3, "birth_date": "2025-12-26", "id_address": 8, "patronymic": "тест", "id_position": 2, "phone_number": "+7 921 693-15-41"}	\N	admin	2025-12-11 10:37:40.853632
809	employee	INSERT	\N	{"id": 19, "inn": "123234364325", "surname": "тест", "firstname": "тест", "id_gender": 2, "birth_date": "2025-11-05", "id_address": 8, "patronymic": "тест", "id_position": 4, "phone_number": "4672346326462346"}	admin	2025-12-11 10:42:52.390501
810	employee	UPDATE	{"id": 19, "inn": "123234364325", "surname": "тест", "firstname": "тест", "id_gender": 2, "birth_date": "2025-11-05", "id_address": 8, "patronymic": "тест", "id_position": 4, "phone_number": "4672346326462346"}	{"id": 19, "inn": "123234364325", "surname": "тест", "firstname": "тест", "id_gender": 2, "birth_date": "2025-11-05", "id_address": 8, "patronymic": "тест", "id_position": 4, "phone_number": "+7 911 123-45-67"}	admin	2025-12-11 10:43:16.834472
811	employee	DELETE	{"id": 19, "inn": "123234364325", "surname": "тест", "firstname": "тест", "id_gender": 2, "birth_date": "2025-11-05", "id_address": 8, "patronymic": "тест", "id_position": 4, "phone_number": "+7 911 123-45-67"}	\N	admin	2025-12-11 10:43:21.477791
812	refresh_tokens	INSERT	\N	{"id": 221, "role": "admin", "token": "a3501cc2a75b6e9af39bd6fab4f75904cb1b68fc9ae9f7e2bd49788aa35ed127", "username": "roman", "created_at": "2025-12-11T11:55:43.394672"}	admin	2025-12-11 11:55:43.394672
813	refresh_tokens	DELETE	{"id": 221, "role": "admin", "token": "a3501cc2a75b6e9af39bd6fab4f75904cb1b68fc9ae9f7e2bd49788aa35ed127", "username": "roman", "created_at": "2025-12-11T11:55:43.394672"}	\N	admin	2025-12-11 11:56:33.637507
814	refresh_tokens	INSERT	\N	{"id": 222, "role": "manager", "token": "8c3740c9889878da88e7b95b91523df89a3151d65a981c5fc1bf0ce8536a1226", "username": "anna_sokolova", "created_at": "2025-12-11T11:56:41.532994"}	admin	2025-12-11 11:56:41.532994
815	refresh_tokens	DELETE	{"id": 222, "role": "manager", "token": "8c3740c9889878da88e7b95b91523df89a3151d65a981c5fc1bf0ce8536a1226", "username": "anna_sokolova", "created_at": "2025-12-11T11:56:41.532994"}	\N	admin	2025-12-11 11:57:01.301805
816	refresh_tokens	INSERT	\N	{"id": 223, "role": "admin", "token": "834a1be08f0993d9a582b49542be9fc5321c8e4d25efcbd2afdf92c04006637f", "username": "roman", "created_at": "2025-12-11T11:57:06.201445"}	admin	2025-12-11 11:57:06.201445
817	refresh_tokens	DELETE	{"id": 223, "role": "admin", "token": "834a1be08f0993d9a582b49542be9fc5321c8e4d25efcbd2afdf92c04006637f", "username": "roman", "created_at": "2025-12-11T11:57:06.201445"}	\N	admin	2025-12-11 11:59:03.40917
818	refresh_tokens	INSERT	\N	{"id": 224, "role": "admin", "token": "701a87ef486229d1db8c718f401741d996a4ec5eba2dd14183d272683d366cd1", "username": "roman", "created_at": "2025-12-11T11:49:27.56543"}	admin	2025-12-11 11:49:27.56543
819	refresh_tokens	INSERT	\N	{"id": 225, "role": "admin", "token": "7f94091b6dd7dd4c05e6c2b57a5d41948f2990ee75b11698208a3ac90dc90faa", "username": "roman", "created_at": "2025-12-11T12:56:30.930871"}	admin	2025-12-11 12:56:30.930871
820	refresh_tokens	INSERT	\N	{"id": 226, "role": "admin", "token": "0f05fc852646e48a02658199e1e121465036dea1076dba8931f6cafabd4b1ba4", "username": "roman", "created_at": "2025-12-11T14:24:09.982786"}	admin	2025-12-11 14:24:09.982786
821	refresh_tokens	DELETE	{"id": 226, "role": "admin", "token": "0f05fc852646e48a02658199e1e121465036dea1076dba8931f6cafabd4b1ba4", "username": "roman", "created_at": "2025-12-11T14:24:09.982786"}	\N	admin	2025-12-11 14:28:18.289296
822	refresh_tokens	INSERT	\N	{"id": 227, "role": "moderator", "token": "6c286f1a7da8087c7fced975b547a0e423909f28b0ee0fb56a1271f1b6552f0a", "username": "artem_volkov", "created_at": "2025-12-11T14:28:38.894322"}	admin	2025-12-11 14:28:38.894322
823	refresh_tokens	DELETE	{"id": 227, "role": "moderator", "token": "6c286f1a7da8087c7fced975b547a0e423909f28b0ee0fb56a1271f1b6552f0a", "username": "artem_volkov", "created_at": "2025-12-11T14:28:38.894322"}	\N	admin	2025-12-11 14:29:24.688267
824	refresh_tokens	INSERT	\N	{"id": 228, "role": "manager", "token": "a3fd5514da28ad089ef35ba7e76ae3c2fc4b110fc1b92a75ff3a349f5f92d70f", "username": "anna_sokolova", "created_at": "2025-12-11T14:29:31.914279"}	admin	2025-12-11 14:29:31.914279
825	refresh_tokens	DELETE	{"id": 228, "role": "manager", "token": "a3fd5514da28ad089ef35ba7e76ae3c2fc4b110fc1b92a75ff3a349f5f92d70f", "username": "anna_sokolova", "created_at": "2025-12-11T14:29:31.914279"}	\N	admin	2025-12-11 14:53:51.179201
826	refresh_tokens	INSERT	\N	{"id": 229, "role": "admin", "token": "13fda6fff23f9211746573a3bff14f4ea3014cfa0df0c1dfcc6061dcb9f9ff7e", "username": "roman", "created_at": "2025-12-11T14:53:57.744773"}	admin	2025-12-11 14:53:57.744773
827	product	INSERT	\N	{"id": 66, "name": "temp", "image_url": "/static/products/placeholder.png", "id_producer": 1, "id_product_category": 1}	admin	2025-12-11 15:09:11.051929
828	role	DELETE	{"id": 6, "name": "тест", "sys_role": "тест", "description": "тест"}	\N	postgres	2025-12-11 15:15:18.679369
829	refresh_tokens	INSERT	\N	{"id": 230, "role": "admin", "token": "718fc4aba671be934b3de1d05ead93c6736e12b1b4b47b839c93e77f28bc29d8", "username": "roman", "created_at": "2025-12-11T16:17:36.189206"}	admin	2025-12-11 16:17:36.189206
830	product	DELETE	{"id": 66, "name": "temp", "image_url": "/static/products/placeholder.png", "id_producer": 1, "id_product_category": 1}	\N	admin	2025-12-11 16:29:37.348726
832	refresh_tokens	INSERT	\N	{"id": 231, "role": "admin", "token": "5a1b2b03e8843648da7d60c17c43570ea353a72549fe48ef28f6103f1bfbb224", "username": "roman", "created_at": "2025-12-12T08:29:33.730885"}	admin	2025-12-12 08:29:33.730885
833	refresh_tokens	DELETE	{"id": 231, "role": "admin", "token": "5a1b2b03e8843648da7d60c17c43570ea353a72549fe48ef28f6103f1bfbb224", "username": "roman", "created_at": "2025-12-12T08:29:33.730885"}	\N	admin	2025-12-12 08:33:43.4265
834	refresh_tokens	INSERT	\N	{"id": 232, "role": "admin", "token": "a022fe3a0bf27f7e0e42516e5327863c3ed53c5922ecf21850bf20ee9844db10", "username": "roman", "created_at": "2025-12-12T12:10:15.386483"}	admin	2025-12-12 12:10:15.386483
835	refresh_tokens	DELETE	{"id": 232, "role": "admin", "token": "a022fe3a0bf27f7e0e42516e5327863c3ed53c5922ecf21850bf20ee9844db10", "username": "roman", "created_at": "2025-12-12T12:10:15.386483"}	\N	admin	2025-12-12 17:51:28.872135
836	refresh_tokens	INSERT	\N	{"id": 233, "role": "admin", "token": "0c2aad6a106adcc0f0699973e41d932c8c8bb6e8146e69c0fd907c0795207e03", "username": "roman", "created_at": "2025-12-12T17:51:28.877506"}	admin	2025-12-12 17:51:28.877506
837	refresh_tokens	INSERT	\N	{"id": 234, "role": "admin", "token": "9b1f08b0ed7a75f093aab1d3e84bd73426643784b64902bf54aea8d8cae3272c", "username": "roman", "created_at": "2025-12-12T17:51:28.877918"}	admin	2025-12-12 17:51:28.877918
838	refresh_tokens	INSERT	\N	{"id": 235, "role": "admin", "token": "a5a1bfc6562780a746b6161df00d0f4e83e3abd2048e19b12c1fb76111f634e4", "username": "roman", "created_at": "2025-12-14T07:22:12.808696"}	admin	2025-12-14 07:22:12.808696
839	refresh_tokens	INSERT	\N	{"id": 236, "role": "moderator", "token": "d93a43c06924ff85f2834990839a63be0043086e3211055c7abe00502ab2f3d6", "username": "artem_volkov", "created_at": "2025-12-14T07:34:58.69473"}	admin	2025-12-14 07:34:58.69473
840	refresh_tokens	DELETE	{"id": 236, "role": "moderator", "token": "d93a43c06924ff85f2834990839a63be0043086e3211055c7abe00502ab2f3d6", "username": "artem_volkov", "created_at": "2025-12-14T07:34:58.69473"}	\N	admin	2025-12-14 07:38:40.757772
841	refresh_tokens	INSERT	\N	{"id": 237, "role": "admin", "token": "160f026995984121e26f3b6b9e57d40b885ac15fe97926eff2477a1d0d846c91", "username": "roman", "created_at": "2025-12-14T07:39:38.973288"}	admin	2025-12-14 07:39:38.973288
842	refresh_tokens	INSERT	\N	{"id": 238, "role": "admin", "token": "571668cb72590fa345cbc5819f16849bcf821299841dc74a7fb55beafe37b92d", "username": "roman", "created_at": "2025-12-14T08:39:32.263942"}	admin	2025-12-14 08:39:32.263942
843	refresh_tokens	DELETE	{"id": 237, "role": "admin", "token": "160f026995984121e26f3b6b9e57d40b885ac15fe97926eff2477a1d0d846c91", "username": "roman", "created_at": "2025-12-14T07:39:38.973288"}	\N	admin	2025-12-14 09:09:42.851955
844	refresh_tokens	INSERT	\N	{"id": 239, "role": "admin", "token": "a79f59be425390ee7b33c2584146522a5805466911e391f25542a3ec3c358df7", "username": "roman", "created_at": "2025-12-14T09:09:42.859728"}	admin	2025-12-14 09:09:42.859728
845	document	INSERT	\N	{"id": 11, "date": "2025-12-14", "id_employee": 14, "id_document_category": 1}	admin	2025-12-14 09:23:37.916814
846	document_content	INSERT	\N	{"id": 15, "id_batch": 1, "quantity": 11, "id_document": 11}	admin	2025-12-14 09:25:45.767704
847	document	UPDATE	{"id": 11, "date": "2025-12-14", "id_employee": 14, "id_document_category": 1}	{"id": 11, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 09:25:48.292054
848	document_content	DELETE	{"id": 15, "id_batch": 1, "quantity": 11, "id_document": 11}	\N	postgres	2025-12-14 09:27:55.059143
849	document	DELETE	{"id": 11, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	\N	admin	2025-12-14 09:32:26.698902
850	document	INSERT	\N	{"id": 12, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 09:32:59.273678
851	document	UPDATE	{"id": 12, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	{"id": 12, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 09:35:15.910314
852	refresh_tokens	DELETE	{"id": 238, "role": "admin", "token": "571668cb72590fa345cbc5819f16849bcf821299841dc74a7fb55beafe37b92d", "username": "roman", "created_at": "2025-12-14T08:39:32.263942"}	\N	admin	2025-12-14 09:42:34.028362
853	refresh_tokens	INSERT	\N	{"id": 240, "role": "admin", "token": "8dae547f3d7dd9320135e600894fd355f3c76174431ec8e6cd14ceb8d3214caa", "username": "roman", "created_at": "2025-12-14T09:42:34.036465"}	admin	2025-12-14 09:42:34.036465
855	refresh_tokens	INSERT	\N	{"id": 241, "role": "admin", "token": "6e3e1bbd9bba3337baea306d4f9e8d8693275fea7eea7f6f99835fbe9e041395", "username": "roman", "created_at": "2025-12-14T09:42:34.036505"}	admin	2025-12-14 09:42:34.036505
854	refresh_tokens	INSERT	\N	{"id": 242, "role": "admin", "token": "42c2f9d8d09b1a3b0eebbd98e1919fb88f3b47e213c315de75aa599f0740ec53", "username": "roman", "created_at": "2025-12-14T09:42:34.036532"}	admin	2025-12-14 09:42:34.036532
856	refresh_tokens	INSERT	\N	{"id": 243, "role": "admin", "token": "5fa9cc3a65800f84bcf7d7303b126179fa864f8967a7dd804e18dc8e16d36f55", "username": "roman", "created_at": "2025-12-14T09:42:34.036614"}	admin	2025-12-14 09:42:34.036614
857	document_content	INSERT	\N	{"id": 16, "id_batch": 1, "quantity": 10, "id_document": 12}	admin	2025-12-14 09:43:07.589629
858	document_content	INSERT	\N	{"id": 17, "id_batch": 1, "quantity": 10, "id_document": 12}	admin	2025-12-14 09:43:14.264804
864	document_content	INSERT	\N	{"id": 19, "id_batch": 1, "quantity": 10, "id_document": 12}	admin	2025-12-14 09:46:14.289828
862	document	UPDATE	{"id": 12, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	{"id": 12, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 09:45:48.010613
863	document_content	DELETE	{"id": 18, "id_batch": 1, "quantity": 10, "id_document": 12}	\N	postgres	2025-12-14 09:46:03.866071
865	document_content	DELETE	{"id": 19, "id_batch": 1, "quantity": 10, "id_document": 12}	\N	postgres	2025-12-14 09:46:34.150082
866	document	DELETE	{"id": 12, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	\N	admin	2025-12-14 09:49:40.32
867	document	INSERT	\N	{"id": 13, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 09:50:29.224696
868	document_content	INSERT	\N	{"id": 20, "id_batch": 1, "quantity": 10, "id_document": 13}	admin	2025-12-14 09:50:41.537753
869	document_content	DELETE	{"id": 20, "id_batch": 1, "quantity": 10, "id_document": 13}	\N	postgres	2025-12-14 09:52:44.122598
870	document_content	INSERT	\N	{"id": 21, "id_batch": 4, "quantity": 10, "id_document": 13}	admin	2025-12-14 10:10:35.659693
871	refresh_tokens	DELETE	{"id": 239, "role": "admin", "token": "a79f59be425390ee7b33c2584146522a5805466911e391f25542a3ec3c358df7", "username": "roman", "created_at": "2025-12-14T09:09:42.859728"}	\N	admin	2025-12-14 10:13:08.873891
872	refresh_tokens	INSERT	\N	{"id": 244, "role": "admin", "token": "de27e16cb2b0ea85655cd06241391b37a204beb075c38e3de23fcef24c9f06bc", "username": "roman", "created_at": "2025-12-14T10:13:08.886217"}	admin	2025-12-14 10:13:08.886217
873	document_content	INSERT	\N	{"id": 22, "id_batch": 4, "quantity": 2, "id_document": 13}	admin	2025-12-14 10:15:55.955374
874	document	UPDATE	{"id": 13, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	{"id": 13, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 10:16:01.947311
875	document	INSERT	\N	{"id": 14, "date": "2025-12-14", "id_employee": 14, "id_document_category": 1}	admin	2025-12-14 10:16:21.610503
876	document_content	INSERT	\N	{"id": 23, "id_batch": 1, "quantity": 1, "id_document": 14}	admin	2025-12-14 10:24:13.390238
877	document	INSERT	\N	{"id": 15, "date": "2025-12-14", "id_employee": 14, "id_document_category": 1}	admin	2025-12-14 10:24:27.751429
878	document_content	INSERT	\N	{"id": 24, "id_batch": 10, "quantity": 10, "id_document": 15}	admin	2025-12-14 10:24:38.322355
879	document_content	INSERT	\N	{"id": 25, "id_batch": 11, "quantity": 5, "id_document": 15}	admin	2025-12-14 10:24:45.247246
880	document	INSERT	\N	{"id": 16, "date": "2025-12-14", "id_employee": 14, "id_document_category": 3}	admin	2025-12-14 10:25:15.893615
881	document_content	INSERT	\N	{"id": 26, "id_batch": 10, "quantity": 10, "id_document": 16}	admin	2025-12-14 10:31:39.907913
882	document	INSERT	\N	{"id": 17, "date": "2025-12-14", "id_employee": 14, "id_document_category": 2}	admin	2025-12-14 10:32:10.528862
883	document_content	INSERT	\N	{"id": 27, "id_batch": 10, "quantity": 9, "id_document": 17}	admin	2025-12-14 10:32:14.925137
884	document_content	INSERT	\N	{"id": 28, "id_batch": 10, "quantity": 1, "id_document": 17}	admin	2025-12-14 10:32:21.862173
885	refresh_tokens	INSERT	\N	{"id": 245, "role": "admin", "token": "f51978acf71dfc519f1a0f408e83ab4fb4e04f76284999d9dfab3212c8d3dbd2", "username": "roman", "created_at": "2025-12-14T10:52:05.115373"}	admin	2025-12-14 10:52:05.115373
886	refresh_tokens	DELETE	{"id": 245, "role": "admin", "token": "f51978acf71dfc519f1a0f408e83ab4fb4e04f76284999d9dfab3212c8d3dbd2", "username": "roman", "created_at": "2025-12-14T10:52:05.115373"}	\N	admin	2025-12-14 11:10:31.626852
887	refresh_tokens	INSERT	\N	{"id": 246, "role": "manager", "token": "4cbed94b1cf405990482a3646c0cb175a03fae15bb9c3a0d6822caa79526056d", "username": "anna_sokolova", "created_at": "2025-12-14T11:10:40.171811"}	admin	2025-12-14 11:10:40.171811
888	refresh_tokens	DELETE	{"id": 246, "role": "manager", "token": "4cbed94b1cf405990482a3646c0cb175a03fae15bb9c3a0d6822caa79526056d", "username": "anna_sokolova", "created_at": "2025-12-14T11:10:40.171811"}	\N	admin	2025-12-14 11:11:40.062009
889	refresh_tokens	INSERT	\N	{"id": 247, "role": "moderator", "token": "1a71268e8820dcf48251dff3050cfb3b52a2e1b6efe13af0adae9fba56adc8b8", "username": "artem_volkov", "created_at": "2025-12-14T11:11:54.2864"}	admin	2025-12-14 11:11:54.2864
890	refresh_tokens	DELETE	{"id": 247, "role": "moderator", "token": "1a71268e8820dcf48251dff3050cfb3b52a2e1b6efe13af0adae9fba56adc8b8", "username": "artem_volkov", "created_at": "2025-12-14T11:11:54.2864"}	\N	admin	2025-12-14 11:12:26.348355
891	refresh_tokens	INSERT	\N	{"id": 248, "role": "manager", "token": "d43bb6cff815ac16bb65436490e85b914a891a188a41ae23f6299d6e7977552d", "username": "anna_sokolova", "created_at": "2025-12-14T11:12:33.250979"}	admin	2025-12-14 11:12:33.250979
892	refresh_tokens	DELETE	{"id": 248, "role": "manager", "token": "d43bb6cff815ac16bb65436490e85b914a891a188a41ae23f6299d6e7977552d", "username": "anna_sokolova", "created_at": "2025-12-14T11:12:33.250979"}	\N	admin	2025-12-14 11:13:06.305453
893	refresh_tokens	INSERT	\N	{"id": 249, "role": "moderator", "token": "daed641a3cf9cefd4e4524395f51a8144b805ba97739e017c86b1ad320a15cd7", "username": "artem_volkov", "created_at": "2025-12-14T11:13:13.297161"}	admin	2025-12-14 11:13:13.297161
894	refresh_tokens	DELETE	{"id": 249, "role": "moderator", "token": "daed641a3cf9cefd4e4524395f51a8144b805ba97739e017c86b1ad320a15cd7", "username": "artem_volkov", "created_at": "2025-12-14T11:13:13.297161"}	\N	admin	2025-12-14 11:21:12.505599
895	refresh_tokens	INSERT	\N	{"id": 250, "role": "admin", "token": "70d7ec97abb7dc12d1be9a39bd849555a25551061021b1443cb9fbede5c30026", "username": "roman", "created_at": "2025-12-14T11:21:16.805759"}	admin	2025-12-14 11:21:16.805759
896	sys_user	DELETE	{"id": 9, "login": "test", "id_role": 2, "id_employee": 17, "password_hash": "$2a$10$jOiUC7j6gA0qCYuxQRUEOeN62hUua/rz6OlrmQuGfGRPbB0rZ8o02"}	\N	admin	2025-12-14 11:21:26.57429
\.


--
-- Data for Name: batch; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.batch (id, cost, production_date, expiration_date, id_product, created_at) FROM stdin;
2	48800	2025-02-01	2027-02-01	2	2025-10-15 08:39:40.31846
3	18900	2025-02-20	2029-02-20	3	2025-10-15 08:39:40.31846
5	89990	2025-03-05	2028-03-05	2	2025-10-15 08:39:40.31846
4	24300	2024-01-20	2034-02-20	1	2025-10-15 08:39:40.31846
8	2	2025-10-30	2026-01-30	1	2025-11-30 14:27:02.406452
9	2	2025-01-30	2025-12-30	3	2025-11-30 14:28:46.581513
10	10	2025-11-29	2025-12-30	4	2025-11-30 15:25:23.003956
11	134	2024-12-06	2024-12-05	3	2025-12-06 13:45:45.295078
1	125500	2024-01-15	2024-01-15	1	2025-10-15 08:39:40.31846
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
13	2025-12-14	14	2
14	2025-12-14	14	1
15	2025-12-14	14	1
16	2025-12-14	14	3
17	2025-12-14	14	2
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
21	13	4	10
22	13	4	2
23	14	1	1
24	15	10	10
25	15	11	5
26	16	10	10
27	17	10	9
28	17	10	1
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.employee (id, surname, firstname, patronymic, id_gender, inn, phone_number, id_address, birth_date, id_position) FROM stdin;
2	Соколова	Анна	Сергеевна	2	525209876543	+7 911 987-65-43	2	1992-08-23	2
3	Павлов	Иван	Олегович	1	525205678901	+7 911 456-78-90	3	1988-11-08	3
4	Орлов	Денис	Романович	1	525203456789	+7 911 234-56-78	4	1995-02-17	3
5	Никитин	Петр	Алексеевич	1	525201987654	+7 911 765-43-21	5	1983-07-30	3
1	Волков	Артем	Дмитриевич	1	525201234567	+7 911 123-45-67	1	1985-05-12	1
17	test	test	test	3	111112213111	+7 900 000-00-00	24	2001-06-16	3
14	Михайлов	Роман	Александрович	1	111111111112	+7 921 693-19-54	1	2005-07-22	9
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
9	Системный администратор	Администрирование информационной системой, полный доступ к ИС
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
18	ООО "ТехноДом"	1	1234567890	Иванов	Игорь	Сергеевич
19	АО "СтройМебель"	2	2345678901	Петрова	Марина	Владимировна
20	ООО "ЭлектроникСистем"	3	3456789012	Сидоров	Дмитрий	Александрович
21	ИП "Кулинария"	4	4567890123	Кузнецов	Алексей	Игоревич
22	ООО "КомфортДом"	5	5678901234	Смирнов	Никита	Петрович
23	АО "АвтоПром"	6	6789012345	Морозова	Ольга	Алексеевна
24	ООО "МебельЛюкс"	7	7890123456	Федоров	Сергей	Иванович
25	ИП "ТехМаркет"	8	8911234567	Григорьев	Павел	Викторович
26	ООО "ХолодСервис"	9	9012345678	Васильева	Елена	Александровна
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (id, name, id_product_category, id_producer, image_url) FROM stdin;
1	Кухонный гарнитур "Уют"	1	1	/static/products/1765011046095675919_a4c7c78c78a454e231f7718718ae6195.jpg
2	Стиральная машина "SM-5000"	2	2	/static/products/1765011070099983639_images (3).jpeg
4	Офисное кресло "Director"	1	1	/static/products/1765011089390225675_images (2).jpeg
5	Холодильник "Frost+ 300"	2	2	/static/products/1765011109815931171_images.jpeg
7	Кухонный гарнитур "Модерн"	1	19	/static/products/1765354277653639797_7-.webp
8	Стиральная машина "EcoWash 3000"	3	20	/static/products/1765373224025730926_8.jpeg
3	Материнская плата "Gamer XTREME"	2	3	/static/products/1765008872100895552_7179111216.jpg
9	Холодильник "CoolFridge X"	3	26	/static/products/1765205408580666042_9.avif
10	Материнская плата "Gamer Pro"	2	20	/static/products/1765205423056717632_10.webp
11	Офисное кресло "Comfort"	1	24	/static/products/1765205440110440418_11.jpg
12	Сковорода "Chef 28"	8	21	/static/products/1765205452018769299_12.jpeg
13	Лампа настольная "LightUp"	2	24	/static/products/1765205465161011013_13.jpg
14	Дрель "PowerTool 300"	2	25	/static/products/1765205524070403429_14.jpeg
15	Постельное белье "Luxury"	1	24	/static/products/1765205530989364252_15.jpeg
16	Газонокосилка "GreenCut"	2	25	/static/products/1765205538458021339_16-.jpg
17	Стул "WoodChair"	1	24	/static/products/1765205549156924260_17.jpeg
18	Тумба под ТВ "Classic"	1	19	/static/products/1765205562290618336_18.jpeg
19	Плита "HeatMaster"	3	26	/static/products/1765205573041308591_19.avif
20	Холодильник "FreezePlus"	3	26	/static/products/1765205584128660513_20.jpeg
21	Телевизор "SmartVision"	2	20	/static/products/1765205595127459587_21.jpeg
22	Сковорода "PanExpert"	8	21	/static/products/1765205605996546425_22.jpeg
23	Лампа "BrightHome"	2	24	/static/products/1765205618048903084_23.jpeg
24	Шуруповерт "DrillMax"	2	25	/static/products/1765205628465314922_24.jpeg
25	Полотенца "SoftLine"	8	24	/static/products/1765205640054667886_25.webp
26	Газонокосилка "EcoCut"	2	25	/static/products/1765205655858996796_26.jpeg
27	Диван "Relax"	1	24	/static/products/1765205673974680054_27.webp
28	Кухонный стол "Classic"	1	19	/static/products/1765205684816340587_28.webp
29	Микроволновка "QuickHeat"	3	26	/static/products/1765205696339956217_29.jpeg
32	Стул "Office"	1	24	/static/products/1765205734811023180_32.webp
55	Сковорода "Chef Classic"	8	21	/static/products/placeholder.png
56	Дрель "ProDrill 500"	2	25	/static/products/placeholder.png
30	Стиральная машина "UltraWash"	3	20	/static/products/1765205708359142459_30.png
44	Диван "SoftRelax"	1	24	/static/products/1765205864107465878_44.jpeg
31	Материнская плата "ProBoard"	2	20	/static/products/1765205722212345257_31.jpg
34	Лампа потолочная "SkyLight"	2	24	/static/products/1765205761391543761_34.jpeg
35	Дрель "MaxDrill"	2	25	/static/products/1765205773609017920_35.jpeg
38	Стул "Comfort Plus"	1	24	/static/products/1765205792574984887_38.jpg
39	Кухонный гарнитур "Элегант"	1	19	/static/products/1765205804730533337_39.jpg
40	Холодильник "Arctic 500"	3	26	/static/products/1765205815959577467_40.jpeg
41	Телевизор "UltraHD 55"	2	20	/static/products/1765205827626538500_41.jpeg
43	Лампа "DeskLight"	2	24	/static/products/1765205850908937761_43.jpeg
45	Постельное белье "Premium"	1	24	/static/products/1765205876341915467_45.jpg
46	Кастрюля "ProCook"	8	21	/static/products/1765205890486289126_46.jpeg
47	Шкаф для одежды "Classic Wardrobe"	1	19	/static/products/1765205904948249133_47.jpeg
48	Микроволновка "SpeedHeat"	3	26	/static/products/1765205926391147379_48.jpeg
49	Материнская плата "Extreme Gamer"	2	20	/static/products/1765205938523145552_49.jpg
50	Стул "ErgoChair"	1	24	/static/products/1765205949295874542_50.jpeg
51	Газонокосилка "PowerCut"	2	25	/static/products/1765205959722191006_51.jpeg
52	Лампа потолочная "BrightSky"	2	24	/static/products/1765205970189001719_52.jpeg
53	Стиральная машина "WashMaster 4000"	3	20	/static/products/1765205980936305918_53.jpeg
54	Кухонный стол "Modern"	1	19	/static/products/1765205992498019007_54.jpeg
33	Кастрюля "CookMaster"	8	21	/static/products/1765354399815235298_33.jpeg
42	Дрель "HandyDrill"	2	25	/static/products/1765354467797030094_42.webp
36	Постельное белье "Comfort"	1	24	/static/products/1765354505917253083_36.jpg
37	Сковорода "Chef Pro 30"	8	21	/static/products/1765354561164319012_37.webp
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
240	8dae547f3d7dd9320135e600894fd355f3c76174431ec8e6cd14ceb8d3214caa	roman	admin	2025-12-14 09:42:34.036465
241	6e3e1bbd9bba3337baea306d4f9e8d8693275fea7eea7f6f99835fbe9e041395	roman	admin	2025-12-14 09:42:34.036505
242	42c2f9d8d09b1a3b0eebbd98e1919fb88f3b47e213c315de75aa599f0740ec53	roman	admin	2025-12-14 09:42:34.036532
243	5fa9cc3a65800f84bcf7d7303b126179fa864f8967a7dd804e18dc8e16d36f55	roman	admin	2025-12-14 09:42:34.036614
244	de27e16cb2b0ea85655cd06241391b37a204beb075c38e3de23fcef24c9f06bc	roman	admin	2025-12-14 10:13:08.886217
250	70d7ec97abb7dc12d1be9a39bd849555a25551061021b1443cb9fbede5c30026	roman	admin	2025-12-14 11:21:16.805759
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
5	moderator_login	$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK	1	5
2	anna_sokolova	$2a$10$ONDNHqgfrEHpioEyaVSDxOG3icMHs3nEsqP1TpzC9jYgB142ezb26	2	2
7	roman	$2a$10$4MWSzOFhEH9X4P25w7YgCeJkH5FoB8lx4S69iRPsnFunJiPOXWYDa	4	14
1	artem_volkov	$2a$10$z9I2uGqAHHc5paoMn9T5yOXLEEDnWMj/Pmwegsv/vdagYct7RKN1O	1	1
\.


--
-- Name: address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.address_id_seq', 26, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 896, true);


--
-- Name: batch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.batch_id_seq', 11, true);


--
-- Name: document_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_category_id_seq', 13, true);


--
-- Name: document_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_content_id_seq', 28, true);


--
-- Name: document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_id_seq', 17, true);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_id_seq', 19, true);


--
-- Name: gender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gender_id_seq', 3, true);


--
-- Name: position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_id_seq', 15, true);


--
-- Name: producer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producer_id_seq', 27, true);


--
-- Name: product_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_category_id_seq', 11, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 66, true);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refresh_tokens_id_seq', 250, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 6, true);


--
-- Name: sys_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sys_user_id_seq', 9, true);


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
-- Name: product_name; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX product_name ON public.product USING btree (name);


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
-- Name: audit_log trigger_delete_old; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_delete_old BEFORE INSERT ON public.audit_log FOR EACH ROW EXECUTE FUNCTION public.delete_old();


--
-- Name: batch batch_id_product_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.batch
    ADD CONSTRAINT batch_id_product_fkey FOREIGN KEY (id_product) REFERENCES public.product(id) ON DELETE CASCADE;


--
-- Name: document_content document_content_id_batch_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content
    ADD CONSTRAINT document_content_id_batch_fkey FOREIGN KEY (id_batch) REFERENCES public.batch(id) ON DELETE CASCADE;


--
-- Name: document_content document_content_id_document_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document_content
    ADD CONSTRAINT document_content_id_document_fkey FOREIGN KEY (id_document) REFERENCES public.document(id) ON DELETE CASCADE;


--
-- Name: document document_id_document_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_document_category_fkey FOREIGN KEY (id_document_category) REFERENCES public.document_category(id) ON DELETE CASCADE;


--
-- Name: document document_id_employee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.document
    ADD CONSTRAINT document_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id) ON DELETE CASCADE;


--
-- Name: employee employee_id_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_id_address_fkey FOREIGN KEY (id_address) REFERENCES public.address(id) ON DELETE CASCADE;


--
-- Name: employee employee_id_gender_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_id_gender_fkey FOREIGN KEY (id_gender) REFERENCES public.gender(id) ON DELETE CASCADE;


--
-- Name: employee employee_id_position_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_id_position_fkey FOREIGN KEY (id_position) REFERENCES public."position"(id) ON DELETE CASCADE;


--
-- Name: producer producer_id_address_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.producer
    ADD CONSTRAINT producer_id_address_fkey FOREIGN KEY (id_address) REFERENCES public.address(id) ON DELETE CASCADE;


--
-- Name: product product_id_producer_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_id_producer_fkey FOREIGN KEY (id_producer) REFERENCES public.producer(id) ON DELETE CASCADE;


--
-- Name: product product_id_product_category_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_id_product_category_fkey FOREIGN KEY (id_product_category) REFERENCES public.product_category(id) ON DELETE CASCADE;


--
-- Name: sys_user sys_user_id_employee_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_id_employee_fkey FOREIGN KEY (id_employee) REFERENCES public.employee(id) ON DELETE CASCADE;


--
-- Name: sys_user sys_user_id_role_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sys_user
    ADD CONSTRAINT sys_user_id_role_fkey FOREIGN KEY (id_role) REFERENCES public.role(id) ON DELETE CASCADE;


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

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.audit_log TO admin;
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
-- Name: TABLE batches_m; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.batches_m TO admin;


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
GRANT SELECT,UPDATE ON TABLE public."position" TO moderator;
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
GRANT SELECT,UPDATE ON TABLE public.producer TO moderator;
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
GRANT SELECT,UPDATE ON TABLE public.product_category TO moderator;
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

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.refresh_tokens TO admin;
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
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_batches TO admin;
GRANT SELECT ON TABLE public.report_batches TO manager;


--
-- Name: TABLE report_documents_by_employee; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_documents_by_employee TO admin;
GRANT SELECT ON TABLE public.report_documents_by_employee TO moderator;


--
-- Name: TABLE report_employees; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_employees TO admin;
GRANT SELECT ON TABLE public.report_employees TO moderator;


--
-- Name: TABLE report_expired_batches; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_expired_batches TO admin;
GRANT SELECT ON TABLE public.report_expired_batches TO manager;
GRANT SELECT ON TABLE public.report_expired_batches TO moderator;


--
-- Name: TABLE report_grants; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_grants TO admin;


--
-- Name: TABLE report_interface_grants; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_interface_grants TO admin;
GRANT SELECT ON TABLE public.report_interface_grants TO manager;
GRANT SELECT ON TABLE public.report_interface_grants TO moderator;


--
-- Name: TABLE report_no_products; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_no_products TO admin;
GRANT SELECT ON TABLE public.report_no_products TO manager;
GRANT SELECT ON TABLE public.report_no_products TO moderator;


--
-- Name: TABLE report_non_fixed_batches; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_non_fixed_batches TO admin;
GRANT SELECT ON TABLE public.report_non_fixed_batches TO moderator;
GRANT SELECT ON TABLE public.report_non_fixed_batches TO manager;


--
-- Name: TABLE report_producer_subject_statistics; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_producer_subject_statistics TO admin;
GRANT SELECT ON TABLE public.report_producer_subject_statistics TO moderator;


--
-- Name: TABLE report_products_left; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_products_left TO admin;
GRANT SELECT ON TABLE public.report_products_left TO manager;
GRANT SELECT ON TABLE public.report_products_left TO moderator;


--
-- Name: TABLE report_products_left_by_batch; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_products_left_by_batch TO admin;
GRANT SELECT ON TABLE public.report_products_left_by_batch TO manager;
GRANT SELECT ON TABLE public.report_products_left_by_batch TO moderator;


--
-- Name: TABLE report_products_total_cost; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.report_products_total_cost TO admin;
GRANT SELECT ON TABLE public.report_products_total_cost TO manager;
GRANT SELECT ON TABLE public.report_products_total_cost TO moderator;


--
-- Name: TABLE role; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role TO admin;
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

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_system_users TO admin;


--
-- Name: TABLE report_tables_activity; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_tables_activity TO admin;


--
-- Name: TABLE report_tables_activity_per_hour; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.report_tables_activity_per_hour TO admin;


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

\unrestrict FmJYTKcX9oQhycIA65rRx32fJ0f7HSiCbriuhnYAN7r91lGii0C6oPgcTRmSAZa

