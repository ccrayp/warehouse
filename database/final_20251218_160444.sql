--
-- PostgreSQL database cluster dump
--

\restrict dukR56YOsOxxXy3u29b96NvTpqAXB6WuO9ACMokYhAdp66yqEo56yq5elRck8VN

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE admin;
ALTER ROLE admin WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:vfwDD6gEqeQvsyM++XcRsg==$pM1xJTGJTJsHl6ynXcVoI+N1O6vy9p+8lBmM5vzy58Y=:HRv8StvZOCBIWmpxHqJjaNUWX/mzZL+7M0hq5GWps+8=';
CREATE ROLE manager;
ALTER ROLE manager WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:wkvTpsEfrFDe3uNVJFLvmg==$5Jn2OA+lrWPKb3gPzZsZ6Qf5wxBDqQZOXlZ4xDLD0IE=:GbBXc0IZ1qV0TTxd1qPk8uNfVyRAs51QNs4VIJcuQ+c=';
CREATE ROLE moderator;
ALTER ROLE moderator WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:tRiKqjAkTfwmgvR5YiPaFQ==$Gr7xrC9DNMUmifZ31e24pnLhGBGvtjbEXyLMafTmQf4=:B8Y73Q12zP2g+Yk/l/tVakqf0NBeES8hibHyXICYSF4=';
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:Lasxw30CxcO8KYWU0WRUPg==$9Wb4RVDiRah6gUm/sCODnWGxw/cR6raEjsxR3rHv2oI=:Aq8oSnGLQXTOISRQ/LqL0sTNONkzHWtD5pZp4Wry1Nw=';

--
-- User Configurations
--








\unrestrict dukR56YOsOxxXy3u29b96NvTpqAXB6WuO9ACMokYhAdp66yqEo56yq5elRck8VN

--
-- PostgreSQL database cluster dump complete
--

--
-- PostgreSQL database dump
--

\restrict 73PNpKlNZ9wEJvGh3PwHWGRq7fvnmIGv7lDG7DBSbguer83bScxDfzHOFQ7FheM

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
 SELECT table_privileges.table_name,
    COALESCE(string_agg((table_privileges.privilege_type)::text, ', '::text ORDER BY (table_privileges.privilege_type)::text) FILTER (WHERE ((table_privileges.grantee)::name = 'admin'::name)), '-'::text) AS admin,
    COALESCE(string_agg((table_privileges.privilege_type)::text, ', '::text ORDER BY (table_privileges.privilege_type)::text) FILTER (WHERE ((table_privileges.grantee)::name = 'manager'::name)), '-'::text) AS manager,
    COALESCE(string_agg((table_privileges.privilege_type)::text, ', '::text ORDER BY (table_privileges.privilege_type)::text) FILTER (WHERE ((table_privileges.grantee)::name = 'moderator'::name)), '-'::text) AS moderator
   FROM information_schema.table_privileges
  WHERE (((table_privileges.grantee)::name = ANY (ARRAY['admin'::name, 'manager'::name, 'moderator'::name])) AND ((table_privileges.privilege_type)::text = ANY ((ARRAY['SELECT'::character varying, 'INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
  GROUP BY table_privileges.table_name
  ORDER BY table_privileges.table_name;


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
    COALESCE((b.id)::text, 'ВСЕ'::text) AS id_batch,
    COALESCE(pt.name, 'ВСЕ'::character varying) AS product_name,
    sum(b.cost) AS cost,
    sum(r.left_quantity) AS left_quantity,
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
27	Новгородская область	Старорусский	Старая Русса	Красных Командиров	103
\.


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (id, table_name, action, old_data, new_data, changed_by, changed_at) FROM stdin;
1192	refresh_tokens	DELETE	{"id": 291, "role": "admin", "token": "7eed6ac88f19552f91f848632cab3eb6161dc315a7e42a7a0903802ba0e2399a", "username": "roman", "created_at": "2025-12-17T09:26:07.116055"}	\N	admin	2025-12-17 10:06:49.195476
1193	refresh_tokens	INSERT	\N	{"id": 292, "role": "manager", "token": "d94142d7c246851fdbb800ed87806b5da7c2ff898c99b67cc04fc3ff31c8d278", "username": "anna_sokolova", "created_at": "2025-12-17T10:06:56.531383"}	admin	2025-12-17 10:06:56.531383
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
1323	refresh_tokens	DELETE	{"id": 311, "role": "admin", "token": "6a44bcf71b471d39c9991269246ef74522afc48b234155fcab9b6cb5d05d2b6f", "username": "roman", "created_at": "2025-12-17T14:22:32.411505"}	\N	admin	2025-12-17 14:22:46.800459
1194	product	INSERT	\N	{"id": 67, "name": "Утюг \\"Ceramic Heat\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 3}	manager	2025-12-17 10:07:32.817532
1195	product	UPDATE	{"id": 67, "name": "Утюг \\"Ceramic Heat\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 3}	{"id": 67, "name": "Утюг \\"Ceramic Heat\\"", "image_url": "/static/products/1765955252842400588_6.jpeg", "id_producer": 25, "id_product_category": 3}	manager	2025-12-17 10:07:32.843685
1324	refresh_tokens	INSERT	\N	{"id": 312, "role": "admin", "token": "ae383d10173d10ecfce4ab883200c9a4a2772469d2ffd880bc15f9da81f46f15", "username": "roman", "created_at": "2025-12-17T14:26:52.151806"}	admin	2025-12-17 14:26:52.151806
1331	refresh_tokens	INSERT	\N	{"id": 318, "role": "admin", "token": "010be9a2336420cb1b95a67b3f803953bc6f567331abddc2b4bd9b7aaac25768", "username": "roman", "created_at": "2025-12-17T16:21:59.827534"}	admin	2025-12-17 16:21:59.827534
1333	sys_user	INSERT	\N	{"id": 11, "login": "test", "id_role": 1, "id_employee": 3, "password_hash": "$2a$10$NSThg/ovlf5fqE0WNhfEEu38UtXoVgy.ZNHh1hyLEg0dM9lJR7iU6"}	admin	2025-12-17 16:26:10.901139
1334	refresh_tokens	INSERT	\N	{"id": 319, "role": "moderator", "token": "ef901f70f8e4428bf2e19c5bf5bef4628dc4d523e0cdbeb55e0c426d9b042072", "username": "test", "created_at": "2025-12-17T16:26:19.405285"}	admin	2025-12-17 16:26:19.405285
1348	refresh_tokens	INSERT	\N	{"id": 327, "role": "manager", "token": "d80cc6b149f248d049d58ae3b076de2d82723bc3fcb6b8ebaac651c34a9cc7d9", "username": "anna_sokolova", "created_at": "2025-12-17T19:09:05.835201"}	admin	2025-12-17 19:09:05.835201
1349	refresh_tokens	INSERT	\N	{"id": 328, "role": "moderator", "token": "80f9ae9cba6e8843e6f082f090f19814b151a304d54dac12c50a05414c22959a", "username": "artem_volkov", "created_at": "2025-12-17T19:11:03.047322"}	admin	2025-12-17 19:11:03.047322
1350	refresh_tokens	INSERT	\N	{"id": 329, "role": "manager", "token": "5655dc24a82080cb21b335ee356630c0c2bb7a306dba5437c880e67cb211a38c", "username": "anna_sokolova", "created_at": "2025-12-17T19:12:43.774039"}	admin	2025-12-17 19:12:43.774039
1358	product	UPDATE	{"id": 70, "name": "Тетрадь", "image_url": "/static/products/1765989317015642669_70.jpg", "id_producer": 28, "id_product_category": 13}	{"id": 70, "name": "Тетрадь в клетку", "image_url": "/static/products/1765989317015642669_70.jpg", "id_producer": 28, "id_product_category": 13}	manager	2025-12-17 19:48:37.828811
1379	refresh_tokens	INSERT	\N	{"id": 336, "role": "manager", "token": "089ee28b14dbee52f31f722c086b4f9ea69c5fddff6abc55e7aa91c2f72dabf5", "username": "anna_sokolova", "created_at": "2025-12-18T11:56:20.588464"}	admin	2025-12-18 11:56:20.588464
1389	product	INSERT	\N	{"id": 72, "name": "тест", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 3}	admin	2025-12-18 13:48:54.075695
1196	refresh_tokens	DELETE	{"id": 292, "role": "manager", "token": "d94142d7c246851fdbb800ed87806b5da7c2ff898c99b67cc04fc3ff31c8d278", "username": "anna_sokolova", "created_at": "2025-12-17T10:06:56.531383"}	\N	admin	2025-12-17 10:07:40.042221
1197	refresh_tokens	INSERT	\N	{"id": 293, "role": "admin", "token": "cab0cbe39cebdf3cfacc30f191565b671512f19d541495c51e2acd59bc6b178c", "username": "roman", "created_at": "2025-12-17T10:07:43.968462"}	admin	2025-12-17 10:07:43.968462
1325	refresh_tokens	INSERT	\N	{"id": 313, "role": "admin", "token": "fd6b15a551b1714519b9afaca22e47acc810045307a2b672a64fb6ec998f01c8", "username": "roman", "created_at": "2025-12-17T15:34:43.388973"}	admin	2025-12-17 15:34:43.388973
1332	product	UPDATE	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "/static/products/1765952717072174470_2.jpeg", "id_producer": 2, "id_product_category": 2}	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "/static/products/1765952717072174470_2.jpeg", "id_producer": 2, "id_product_category": 3}	admin	2025-12-17 16:22:46.688236
1335	refresh_tokens	INSERT	\N	{"id": 320, "role": "manager", "token": "6663ea65dfc816f809e2bf72cde8101277259979c11f01cc660787af7cd1346a", "username": "anna_sokolova", "created_at": "2025-12-17T16:26:49.504421"}	admin	2025-12-17 16:26:49.504421
1351	producer	INSERT	\N	{"id": 28, "inn": "6456387568", "name": "тест", "surname": "Иванов", "firstname": "Петр", "id_address": 9, "patronymic": "Сидорович"}	manager	2025-12-17 19:25:33.792229
1352	product_category	INSERT	\N	{"id": 13, "name": "Канцелярские принадлежности"}	manager	2025-12-17 19:30:14.732279
1359	batch	INSERT	\N	{"id": 12, "cost": 45, "created_at": "2025-12-17T19:53:27.255671", "id_product": 70, "expiration_date": "2035-12-17", "production_date": "2025-12-17"}	manager	2025-12-17 19:53:27.255671
1380	refresh_tokens	INSERT	\N	{"id": 337, "role": "moderator", "token": "c1cfb326b2dd510bd2bd0fade9ab922d52febd8967f6165e1e7c8fe31fcca69f", "username": "artem_volkov", "created_at": "2025-12-18T12:43:13.448528"}	admin	2025-12-18 12:43:13.448528
1381	refresh_tokens	INSERT	\N	{"id": 338, "role": "moderator", "token": "095981009a74eb724c335cdbb0aedb7a55a9732d02430c2fa7da3c9df20fff78", "username": "artem_volkov", "created_at": "2025-12-18T12:46:54.095311"}	admin	2025-12-18 12:46:54.095311
1382	refresh_tokens	DELETE	{"id": 338, "role": "moderator", "token": "095981009a74eb724c335cdbb0aedb7a55a9732d02430c2fa7da3c9df20fff78", "username": "artem_volkov", "created_at": "2025-12-18T12:46:54.095311"}	\N	admin	2025-12-18 12:54:36.236921
1383	refresh_tokens	INSERT	\N	{"id": 339, "role": "moderator", "token": "80147c40e86e60963dd7cb8af0760a61c4f7516c7e9494d49b9a3dc5ad98fc10", "username": "artem_volkov", "created_at": "2025-12-18T12:54:36.238138"}	admin	2025-12-18 12:54:36.238138
1390	product	DELETE	{"id": 72, "name": "тест", "image_url": "/static/products/placeholder.png", "id_producer": 19, "id_product_category": 3}	\N	admin	2025-12-18 13:49:45.334201
1198	refresh_tokens	DELETE	{"id": 293, "role": "admin", "token": "cab0cbe39cebdf3cfacc30f191565b671512f19d541495c51e2acd59bc6b178c", "username": "roman", "created_at": "2025-12-17T10:07:43.968462"}	\N	admin	2025-12-17 10:34:39.422817
1327	refresh_tokens	INSERT	\N	{"id": 314, "role": "admin", "token": "75a0792e162f4b741e384d45e20290cf68d77ac8128a72f3f408d6de09e108d0", "username": "roman", "created_at": "2025-12-17T15:39:23.392631"}	admin	2025-12-17 15:39:23.392631
1328	refresh_tokens	INSERT	\N	{"id": 315, "role": "admin", "token": "70b481b63070d94342fd7a7f4f0e1f180ceffe4d8b047e9ae99f1e46301cb486", "username": "roman", "created_at": "2025-12-17T15:40:35.762648"}	admin	2025-12-17 15:40:35.762648
1336	product	INSERT	\N	{"id": 68, "name": "Тестовый товар", "image_url": "/static/products/placeholder.png", "id_producer": 4, "id_product_category": 1}	manager	2025-12-17 16:27:15.120236
1337	product	UPDATE	{"id": 68, "name": "Тестовый товар", "image_url": "/static/products/placeholder.png", "id_producer": 4, "id_product_category": 1}	{"id": 68, "name": "Тестовый товар", "image_url": "", "id_producer": 4, "id_product_category": 1}	manager	2025-12-17 16:28:06.886055
1338	product	UPDATE	{"id": 68, "name": "Тестовый товар", "image_url": "", "id_producer": 4, "id_product_category": 1}	{"id": 68, "name": "Тестовый товар", "image_url": "/static/products/1765978086932498588_placeholder.png", "id_producer": 4, "id_product_category": 1}	manager	2025-12-17 16:28:06.934406
1353	producer	UPDATE	{"id": 28, "inn": "6456387568", "name": "тест", "surname": "Иванов", "firstname": "Петр", "id_address": 9, "patronymic": "Сидорович"}	{"id": 28, "inn": "6456387568", "name": "ООО \\"Первый класс\\"", "surname": "Иванов", "firstname": "Петр", "id_address": 9, "patronymic": "Сидорович"}	manager	2025-12-17 19:33:29.660815
1354	product	INSERT	\N	{"id": 70, "name": "Тетрадь", "image_url": "/static/products/placeholder.png", "id_producer": 28, "id_product_category": 13}	manager	2025-12-17 19:34:08.981539
1355	product	UPDATE	{"id": 70, "name": "Тетрадь", "image_url": "/static/products/placeholder.png", "id_producer": 28, "id_product_category": 13}	{"id": 70, "name": "Тетрадь", "image_url": "/static/products/1765989248998332346_58.jpg", "id_producer": 28, "id_product_category": 13}	manager	2025-12-17 19:34:08.999841
1360	refresh_tokens	INSERT	\N	{"id": 330, "role": "admin", "token": "d3708f6357e5a0e80f2cb0c4c723fa015a9506409a5807d729a48e4bfcbd499f", "username": "roman", "created_at": "2025-12-17T19:57:02.656177"}	admin	2025-12-17 19:57:02.656177
1384	refresh_tokens	INSERT	\N	{"id": 340, "role": "admin", "token": "442f66368cb47cf445190b787eb9a4c4e4fe297f3c4ec0404a780a08471d7ecd", "username": "roman", "created_at": "2025-12-18T12:58:20.912379"}	admin	2025-12-18 12:58:20.912379
1391	product	INSERT	\N	{"id": 73, "name": "test", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 2}	admin	2025-12-18 13:49:53.13803
1392	product	DELETE	{"id": 73, "name": "test", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 2}	\N	admin	2025-12-18 13:50:08.088504
1199	refresh_tokens	INSERT	\N	{"id": 294, "role": "manager", "token": "7d958e353ba2d58f47642ccce180af4350fef8015af291ffcf2295e101e9c270", "username": "anna_sokolova", "created_at": "2025-12-17T10:34:57.970164"}	admin	2025-12-17 10:34:57.970164
1329	refresh_tokens	INSERT	\N	{"id": 316, "role": "admin", "token": "7f67c832795a36f1caa4ede536ee9196cb98af87d9d1dfe071ba8ab672697b98", "username": "roman", "created_at": "2025-12-17T15:41:41.499096"}	admin	2025-12-17 15:41:41.499096
1339	refresh_tokens	INSERT	\N	{"id": 321, "role": "admin", "token": "f594e892406be435a604e34e28db4c2f635c543a3e2d66bcdd87928999fe461c", "username": "roman", "created_at": "2025-12-17T16:28:58.804567"}	admin	2025-12-17 16:28:58.804567
1356	product	UPDATE	{"id": 70, "name": "Тетрадь", "image_url": "/static/products/1765989248998332346_58.jpg", "id_producer": 28, "id_product_category": 13}	{"id": 70, "name": "Тетрадь", "image_url": "", "id_producer": 28, "id_product_category": 13}	manager	2025-12-17 19:35:16.996451
1357	product	UPDATE	{"id": 70, "name": "Тетрадь", "image_url": "", "id_producer": 28, "id_product_category": 13}	{"id": 70, "name": "Тетрадь", "image_url": "/static/products/1765989317015642669_70.jpg", "id_producer": 28, "id_product_category": 13}	manager	2025-12-17 19:35:17.01624
1361	refresh_tokens	INSERT	\N	{"id": 331, "role": "manager", "token": "e2f90a931eeaf3784b5ae2f998bf308b83dc49341b1f233d9ae05400cc145d4c", "username": "anna_sokolova", "created_at": "2025-12-17T19:59:23.802914"}	admin	2025-12-17 19:59:23.802914
1385	sys_user	INSERT	\N	{"id": 12, "login": "denis_orlov", "id_role": 4, "id_employee": 4, "password_hash": "$2a$10$ZKe3pjOAPtB5CIMWcvT0q.B8/gldZefclTGV9ruv60CvI/RHKtWeO"}	admin	2025-12-18 12:58:49.929693
1388	product	DELETE	{"id": 71, "name": "576345643786534657468754376573648756436543657346785436875643756436584365687346534668543654353257", "image_url": "/static/products/placeholder.png", "id_producer": 2, "id_product_category": 1}	\N	admin	2025-12-18 13:25:55.854979
1200	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765902884396074001_14.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:38:37.095554
1201	product	UPDATE	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 14, "name": "Дрель \\"PowerTool 300\\"", "image_url": "/static/products/1765957117118564756_14.jpeg", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:38:37.120084
1204	product	UPDATE	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "/static/products/1765902893007872922_16.jpg", "id_producer": 25, "id_product_category": 2}	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:38:43.593395
1205	product	UPDATE	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 16, "name": "Газонокосилка \\"GreenCut\\"", "image_url": "/static/products/1765957123605219718_16.jpg", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:38:43.605751
1208	product	UPDATE	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "/static/products/1765902901690138259_18.jpeg", "id_producer": 19, "id_product_category": 1}	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:38:51.986084
1209	product	UPDATE	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 18, "name": "Тумба под ТВ \\"Classic\\"", "image_url": "/static/products/1765957131997504097_18.jpeg", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:38:51.998054
1214	product	UPDATE	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "/static/products/1765902914378054293_21.jpeg", "id_producer": 20, "id_product_category": 2}	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:39:01.701851
1215	product	UPDATE	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	{"id": 21, "name": "Телевизор \\"SmartVision\\"", "image_url": "/static/products/1765957141710564754_21.jpeg", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:39:01.711011
1220	product	UPDATE	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "/static/products/1765902943202935500_24.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:39:14.182594
1221	product	UPDATE	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 24, "name": "Шуруповерт \\"DrillMax\\"", "image_url": "/static/products/1765957154192326426_24.jpeg", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:39:14.192704
1232	product	UPDATE	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "/static/products/1765902979319774753_30.png", "id_producer": 20, "id_product_category": 3}	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	manager	2025-12-17 10:39:40.675458
1233	product	UPDATE	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	{"id": 30, "name": "Стиральная машина \\"UltraWash\\"", "image_url": "/static/products/1765957180690130300_30.png", "id_producer": 20, "id_product_category": 3}	manager	2025-12-17 10:39:40.690801
1234	product	UPDATE	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/1765902983964183755_31.jpg", "id_producer": 20, "id_product_category": 2}	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:39:44.706895
1235	product	UPDATE	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	{"id": 31, "name": "Материнская плата \\"ProBoard\\"", "image_url": "/static/products/1765957184719296760_31.jpg", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:39:44.720133
1330	refresh_tokens	INSERT	\N	{"id": 317, "role": "admin", "token": "2ed9311c9f5e64b0bdc0f82db18960f431067a3010ed8b51dc3431d5cabf32d0", "username": "roman", "created_at": "2025-12-17T15:42:59.676015"}	admin	2025-12-17 15:42:59.676015
1340	product	DELETE	{"id": 68, "name": "Тестовый товар", "image_url": "/static/products/1765978086932498588_placeholder.png", "id_producer": 4, "id_product_category": 1}	\N	admin	2025-12-17 16:29:08.395169
1362	document	INSERT	\N	{"id": 18, "date": "2025-12-17", "id_employee": 2, "id_document_category": 1}	manager	2025-12-17 20:04:33.553938
1386	refresh_tokens	INSERT	\N	{"id": 341, "role": "admin", "token": "3ed44c11de507638488207485956ccb91a91076e1f3c3f2a4a80ac5cb7d32e14", "username": "roman", "created_at": "2025-12-18T13:22:00.92475"}	admin	2025-12-18 13:22:00.92475
1202	product	UPDATE	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "/static/products/1765902889238710628_15.jpeg", "id_producer": 24, "id_product_category": 1}	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:38:40.809084
1203	product	UPDATE	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 15, "name": "Постельное белье \\"Luxury\\"", "image_url": "/static/products/1765957120820601966_15.jpeg", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:38:40.822685
1207	product	UPDATE	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "/static/products/1765957127035473261_17.jpeg", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:38:47.036118
1210	product	UPDATE	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "/static/products/1765902905078576511_19.avif", "id_producer": 26, "id_product_category": 3}	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:38:55.047584
1211	product	UPDATE	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	{"id": 19, "name": "Плита \\"HeatMaster\\"", "image_url": "/static/products/1765957135057974126_19.avif", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:38:55.058242
1212	product	UPDATE	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "/static/products/1765902909008158846_20.jpeg", "id_producer": 26, "id_product_category": 3}	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:38:58.515544
1213	product	UPDATE	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	{"id": 20, "name": "Холодильник \\"FreezePlus\\"", "image_url": "/static/products/1765957138526011169_20.jpeg", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:38:58.52638
1218	product	UPDATE	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "/static/products/1765902924337540214_23.jpeg", "id_producer": 24, "id_product_category": 2}	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	manager	2025-12-17 10:39:10.140367
1219	product	UPDATE	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	{"id": 23, "name": "Лампа \\"BrightHome\\"", "image_url": "/static/products/1765957150151930841_23.jpeg", "id_producer": 24, "id_product_category": 2}	manager	2025-12-17 10:39:10.152417
1224	product	UPDATE	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "/static/products/1765902949354806378_26.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:39:23.369147
1225	product	UPDATE	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 26, "name": "Газонокосилка \\"EcoCut\\"", "image_url": "/static/products/1765957163376438333_26.jpeg", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:39:23.376772
1228	product	UPDATE	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "/static/products/1765902966870945595_28.webp", "id_producer": 19, "id_product_category": 1}	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:39:32.103917
1229	product	UPDATE	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 28, "name": "Кухонный стол \\"Classic\\"", "image_url": "/static/products/1765957172116750046_28.webp", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:39:32.117209
1230	product	UPDATE	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "/static/products/1765902971176220014_29.jpeg", "id_producer": 26, "id_product_category": 3}	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:39:37.091469
1231	product	UPDATE	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	{"id": 29, "name": "Микроволновка \\"QuickHeat\\"", "image_url": "/static/products/1765957177103111631_29.jpeg", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:39:37.104237
1341	refresh_tokens	INSERT	\N	{"id": 322, "role": "manager", "token": "e9d189671e08e2ad52a146812d3fc28e802e6969bc668f4bfad16ccf8a3dd4d0", "username": "anna_sokolova", "created_at": "2025-12-17T16:30:34.28805"}	admin	2025-12-17 16:30:34.28805
1344	refresh_tokens	INSERT	\N	{"id": 323, "role": "admin", "token": "7cc6ca11a4749409ab53415bd26ad8b1ebb543a389e9e6c4c60b6c1f23a7e9d3", "username": "roman", "created_at": "2025-12-17T16:31:07.814227"}	admin	2025-12-17 16:31:07.814227
1363	refresh_tokens	INSERT	\N	{"id": 332, "role": "admin", "token": "f3255461bbe89584e7bd063ced5a36f07008212985714469fc433882f30fc7b3", "username": "roman", "created_at": "2025-12-17T20:06:06.971254"}	admin	2025-12-17 20:06:06.971254
1387	product	INSERT	\N	{"id": 71, "name": "576345643786534657468754376573648756436543657346785436875643756436584365687346534668543654353257", "image_url": "/static/products/placeholder.png", "id_producer": 2, "id_product_category": 1}	admin	2025-12-18 13:25:39.763342
1206	product	UPDATE	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "/static/products/1765902896208012382_17.jpeg", "id_producer": 24, "id_product_category": 1}	{"id": 17, "name": "Стул \\"WoodChair\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:38:47.023721
1216	product	UPDATE	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "/static/products/1765902918947207586_22.jpeg", "id_producer": 21, "id_product_category": 8}	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:39:06.250546
1217	product	UPDATE	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 22, "name": "Сковорода \\"PanExpert\\"", "image_url": "/static/products/1765957146260570714_22.jpeg", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:39:06.261357
1222	product	UPDATE	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "/static/products/1765902938592861846_25.webp", "id_producer": 24, "id_product_category": 8}	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "", "id_producer": 24, "id_product_category": 8}	manager	2025-12-17 10:39:18.245395
1223	product	UPDATE	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "", "id_producer": 24, "id_product_category": 8}	{"id": 25, "name": "Полотенца \\"SoftLine\\"", "image_url": "/static/products/1765957158257484678_25.webp", "id_producer": 24, "id_product_category": 8}	manager	2025-12-17 10:39:18.258046
1226	product	UPDATE	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "/static/products/1765902955871612256_27.webp", "id_producer": 24, "id_product_category": 1}	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:39:27.022213
1227	product	UPDATE	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 27, "name": "Диван \\"Relax\\"", "image_url": "/static/products/1765957167032808710_27.webp", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:39:27.033264
1342	product	INSERT	\N	{"id": 69, "name": "Ноутбук", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 16:30:56.074143
1343	product	UPDATE	{"id": 69, "name": "Ноутбук", "image_url": "/static/products/placeholder.png", "id_producer": 20, "id_product_category": 2}	{"id": 69, "name": "Ноутбук", "image_url": "/static/products/1765978256093059347_1.jpeg", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 16:30:56.09446
1364	document	DELETE	{"id": 18, "date": "2025-12-17", "id_employee": 2, "id_document_category": 1}	\N	admin	2025-12-17 20:06:13.017553
1236	product	UPDATE	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "/static/products/1765902990957545800_32.webp", "id_producer": 24, "id_product_category": 1}	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:39:49.846433
1237	product	UPDATE	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 32, "name": "Стул \\"Office\\"", "image_url": "/static/products/1765957189862935304_32.webp", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:39:49.863141
1240	product	UPDATE	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "/static/products/1765903002725423000_34.jpeg", "id_producer": 24, "id_product_category": 2}	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	manager	2025-12-17 10:39:58.465612
1241	product	UPDATE	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	{"id": 34, "name": "Лампа потолочная \\"SkyLight\\"", "image_url": "/static/products/1765957198478194169_34.jpeg", "id_producer": 24, "id_product_category": 2}	manager	2025-12-17 10:39:58.478794
1246	product	UPDATE	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/1765903016922236132_37.webp", "id_producer": 21, "id_product_category": 8}	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:40:11.463704
1247	product	UPDATE	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 37, "name": "Сковорода \\"Chef Pro 30\\"", "image_url": "/static/products/1765957211474830383_37.webp", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:40:11.47526
1254	product	UPDATE	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "/static/products/1765903130437245420_41.jpeg", "id_producer": 20, "id_product_category": 2}	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:40:30.856976
1255	product	UPDATE	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	{"id": 41, "name": "Телевизор \\"UltraHD 55\\"", "image_url": "/static/products/1765957230863736670_41.jpeg", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:40:30.864349
1258	product	UPDATE	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "/static/products/1765903140958636092_43.jpeg", "id_producer": 24, "id_product_category": 2}	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	manager	2025-12-17 10:40:40.930573
1259	product	UPDATE	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	{"id": 43, "name": "Лампа \\"DeskLight\\"", "image_url": "/static/products/1765957240945953466_43.jpeg", "id_producer": 24, "id_product_category": 2}	manager	2025-12-17 10:40:40.94651
1266	product	UPDATE	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/1765903176524594261_47.jpeg", "id_producer": 19, "id_product_category": 1}	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:41:01.172435
1267	product	UPDATE	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/1765957261185824504_46.jpg", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:41:01.186362
1268	product	UPDATE	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/1765957261185824504_46.jpg", "id_producer": 19, "id_product_category": 1}	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:41:08.653265
1269	product	UPDATE	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 47, "name": "Шкаф для одежды \\"Classic Wardrobe\\"", "image_url": "/static/products/1765957268661142799_47.jpeg", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:41:08.661462
1345	refresh_tokens	INSERT	\N	{"id": 324, "role": "admin", "token": "f34ece8a737481660d0fe055d834d36416cb807ffd1117e8fa8385c885411f75", "username": "roman", "created_at": "2025-12-17T17:15:58.961162"}	admin	2025-12-17 17:15:58.961162
1365	refresh_tokens	INSERT	\N	{"id": 333, "role": "manager", "token": "d1b24a2fe9fa9992ed480f0b28a74c1e448d9fb19617d5636373f83eb660905e", "username": "anna_sokolova", "created_at": "2025-12-17T20:06:20.544899"}	admin	2025-12-17 20:06:20.544899
1238	product	UPDATE	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "/static/products/1765902996829507053_33.jpeg", "id_producer": 21, "id_product_category": 8}	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:39:53.716778
1239	product	UPDATE	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 33, "name": "Кастрюля \\"CookMaster\\"", "image_url": "/static/products/1765957193732642500_33.jpeg", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:39:53.732919
1242	product	UPDATE	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "/static/products/1765903007913705919_35.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:40:03.277329
1243	product	UPDATE	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 35, "name": "Дрель \\"MaxDrill\\"", "image_url": "/static/products/1765957203287260630_35.jpeg", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:40:03.287622
1250	product	UPDATE	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "/static/products/1765903119722697138_39.jpg", "id_producer": 19, "id_product_category": 1}	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:40:23.050073
1251	product	UPDATE	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 39, "name": "Кухонный гарнитур \\"Элегант\\"", "image_url": "/static/products/1765957223068063458_39.jpg", "id_producer": 19, "id_product_category": 1}	manager	2025-12-17 10:40:23.069358
1260	product	UPDATE	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "/static/products/1765903147824702137_44.jpeg", "id_producer": 24, "id_product_category": 1}	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:46.845152
1261	product	UPDATE	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 44, "name": "Диван \\"SoftRelax\\"", "image_url": "/static/products/1765957246858076386_44.jpeg", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:46.85826
1262	product	UPDATE	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "/static/products/1765903153843628542_45.jpg", "id_producer": 24, "id_product_category": 1}	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:51.411064
1263	product	UPDATE	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 45, "name": "Постельное белье \\"Premium\\"", "image_url": "/static/products/1765957251431221846_45.jpg", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:51.431921
1272	product	UPDATE	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/1765903187145978752_49.jpg", "id_producer": 20, "id_product_category": 2}	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:41:17.677511
1273	product	UPDATE	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/1765957277688558595_49.jpg", "id_producer": 20, "id_product_category": 2}	manager	2025-12-17 10:41:17.68895
1346	refresh_tokens	INSERT	\N	{"id": 325, "role": "admin", "token": "97f3ee44bc606e32645dfa792ce539a85bbeaa340eee8e4ef7574aee4915676d", "username": "roman", "created_at": "2025-12-17T17:35:38.623463"}	admin	2025-12-17 17:35:38.623463
1347	refresh_tokens	INSERT	\N	{"id": 326, "role": "manager", "token": "16ad8077cb7e7c2b34a0a2c7b403420c8ffe10d238066af6bcc30790d304b27c", "username": "anna_sokolova", "created_at": "2025-12-17T17:35:53.899284"}	admin	2025-12-17 17:35:53.899284
1366	document	INSERT	\N	{"id": 19, "date": "2025-12-17", "id_employee": 2, "id_document_category": 1}	manager	2025-12-17 20:06:26.286402
1244	product	UPDATE	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "/static/products/1765903011995595088_36.jpg", "id_producer": 24, "id_product_category": 1}	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:07.089681
1245	product	UPDATE	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 36, "name": "Постельное белье \\"Comfort\\"", "image_url": "/static/products/1765957207099011173_36.jpg", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:07.099307
1248	product	UPDATE	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "/static/products/1765903114376768427_38.jpg", "id_producer": 24, "id_product_category": 1}	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:18.933311
1249	product	UPDATE	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 38, "name": "Стул \\"Comfort Plus\\"", "image_url": "/static/products/1765957218945988429_38.jpg", "id_producer": 24, "id_product_category": 1}	manager	2025-12-17 10:40:18.946504
1252	product	UPDATE	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "/static/products/1765903125172666585_40.jpeg", "id_producer": 26, "id_product_category": 3}	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:40:26.633769
1253	product	UPDATE	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	{"id": 40, "name": "Холодильник \\"Arctic 500\\"", "image_url": "/static/products/1765957226645823668_40.jpeg", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:40:26.646263
1256	product	UPDATE	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "/static/products/1765903136001616381_42.webp", "id_producer": 25, "id_product_category": 2}	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:40:36.85103
1257	product	UPDATE	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 42, "name": "Дрель \\"HandyDrill\\"", "image_url": "/static/products/1765957236865497715_42.webp", "id_producer": 25, "id_product_category": 2}	manager	2025-12-17 10:40:36.86608
1264	product	UPDATE	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "/static/products/1765903159611992045_46.jpeg", "id_producer": 21, "id_product_category": 8}	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:40:56.3078
1265	product	UPDATE	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 46, "name": "Кастрюля \\"ProCook\\"", "image_url": "/static/products/1765957256316873918_46.jpeg", "id_producer": 21, "id_product_category": 8}	manager	2025-12-17 10:40:56.317375
1270	product	UPDATE	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "/static/products/1765903181767449666_48.jpeg", "id_producer": 26, "id_product_category": 3}	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:41:13.200091
1271	product	UPDATE	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	{"id": 48, "name": "Микроволновка \\"SpeedHeat\\"", "image_url": "/static/products/1765957273217070551_48.jpeg", "id_producer": 26, "id_product_category": 3}	manager	2025-12-17 10:41:13.217832
1367	document_content	INSERT	\N	{"id": 29, "id_batch": 12, "quantity": 100, "id_document": 19}	manager	2025-12-17 20:08:12.062653
859	document_content	DELETE	{"id": 16, "id_batch": 1, "quantity": 10, "id_document": 12}	\N	postgres	2025-12-14 09:43:53.443618
1274	refresh_tokens	DELETE	{"id": 294, "role": "manager", "token": "7d958e353ba2d58f47642ccce180af4350fef8015af291ffcf2295e101e9c270", "username": "anna_sokolova", "created_at": "2025-12-17T10:34:57.970164"}	\N	admin	2025-12-17 10:42:02.724612
1275	refresh_tokens	INSERT	\N	{"id": 295, "role": "admin", "token": "1c04ee3c44d98930a16c00752b81a2b6ece3222569b7850fce16031a25b150ce", "username": "roman", "created_at": "2025-12-17T10:42:07.338403"}	admin	2025-12-17 10:42:07.338403
1368	document	INSERT	\N	{"id": 20, "date": "2025-12-17", "id_employee": 2, "id_document_category": 3}	manager	2025-12-17 20:20:06.953566
1369	document_content	INSERT	\N	{"id": 30, "id_batch": 12, "quantity": 100, "id_document": 20}	manager	2025-12-17 20:21:58.991941
1370	batch	UPDATE	{"id": 12, "cost": 45, "created_at": "2025-12-17T19:53:27.255671", "id_product": 70, "expiration_date": "2035-12-17", "production_date": "2025-12-17"}	{"id": 12, "cost": 50, "created_at": "2025-12-17T19:53:27.255671", "id_product": 70, "expiration_date": "2035-12-17", "production_date": "2025-12-17"}	manager	2025-12-17 20:21:59.004898
1372	document_content	INSERT	\N	{"id": 31, "id_batch": 12, "quantity": 32467, "id_document": 21}	manager	2025-12-17 20:24:05.902839
1371	document	INSERT	\N	{"id": 21, "date": "2025-12-17", "id_employee": 2, "id_document_category": 2}	manager	2025-12-17 20:23:57.847855
1290	refresh_tokens	INSERT	\N	{"id": 296, "role": "admin", "token": "f34bb06c9b51a5151a7e9dcf23998387addf4e6e92330f49c8a726ee3cbba202", "username": "roman", "created_at": "2025-12-17T11:46:08.955238"}	admin	2025-12-17 11:46:08.955238
1373	refresh_tokens	INSERT	\N	{"id": 334, "role": "admin", "token": "2be0dde2f2cbba21224a38d67da91dd794d5cd0db45e10924078fe436953c551", "username": "roman", "created_at": "2025-12-17T20:39:59.84224"}	admin	2025-12-17 20:39:59.84224
1291	refresh_tokens	DELETE	{"id": 296, "role": "admin", "token": "f34bb06c9b51a5151a7e9dcf23998387addf4e6e92330f49c8a726ee3cbba202", "username": "roman", "created_at": "2025-12-17T11:46:08.955238"}	\N	admin	2025-12-17 12:46:11.56546
1292	refresh_tokens	INSERT	\N	{"id": 297, "role": "admin", "token": "62ddf251a2ce16fb97e865d1059d3f8d38f9636868a921eb8f3e55567c0aceee", "username": "roman", "created_at": "2025-12-17T12:46:11.574242"}	admin	2025-12-17 12:46:11.574242
1293	refresh_tokens	DELETE	{"id": 297, "role": "admin", "token": "62ddf251a2ce16fb97e865d1059d3f8d38f9636868a921eb8f3e55567c0aceee", "username": "roman", "created_at": "2025-12-17T12:46:11.574242"}	\N	admin	2025-12-17 12:46:26.55477
1374	document	DELETE	{"id": 21, "date": "2025-12-17", "id_employee": 2, "id_document_category": 2}	\N	admin	2025-12-17 20:40:09.666368
1375	document_content	DELETE	{"id": 31, "id_batch": 12, "quantity": 32467, "id_document": 21}	\N	admin	2025-12-17 20:40:09.666368
1294	refresh_tokens	DELETE	{"id": 286, "role": "admin", "token": "d3c9eed8183bf405befae63100d63c4deb5208600c4506c9d6d3392f2494e1ad", "username": "roman", "created_at": "2025-12-16T20:41:12.763096"}	\N	postgres	2025-12-17 12:59:07.470316
1295	refresh_tokens	DELETE	{"id": 295, "role": "admin", "token": "1c04ee3c44d98930a16c00752b81a2b6ece3222569b7850fce16031a25b150ce", "username": "roman", "created_at": "2025-12-17T10:42:07.338403"}	\N	postgres	2025-12-17 12:59:09.696843
1317	refresh_tokens	DELETE	{"id": 299, "role": "admin", "token": "6973563795ce417706763791ed766d38b30453071058faecd175ecdfef4cb268", "username": "roman", "created_at": "2025-12-17T13:03:22.144967"}	\N	postgres	2025-12-17 13:19:55.840765
1318	refresh_tokens	DELETE	{"id": 300, "role": "admin", "token": "5f28641de8625f00b12aecd58083722779a897bd955d58eac998c347e501eb63", "username": "roman", "created_at": "2025-12-17T13:03:53.787962"}	\N	postgres	2025-12-17 13:19:55.840765
1319	refresh_tokens	DELETE	{"id": 309, "role": "admin", "token": "ee0705e11653695b7f3d4794f079e8b683590207942ceaee1c966b76594e4035", "username": "roman", "created_at": "2025-12-17T13:18:35.900639"}	\N	postgres	2025-12-17 13:19:55.840765
1326	refresh_tokens	DELETE	{"id": 312, "role": "admin", "token": "ae383d10173d10ecfce4ab883200c9a4a2772469d2ffd880bc15f9da81f46f15", "username": "roman", "created_at": "2025-12-17T14:26:52.151806"}	\N	postgres	2025-12-17 15:35:04.017121
1376	refresh_tokens	INSERT	\N	{"id": 335, "role": "manager", "token": "eb67f4830d5ed751262a1c073dca1916ae198867a22a77d81630c038a84d21c8", "username": "anna_sokolova", "created_at": "2025-12-17T20:40:18.435497"}	admin	2025-12-17 20:40:18.435497
597	refresh_tokens	INSERT	\N	{"id": 161, "role": "admin", "token": "43c31d509e0359bce2f9d52e7a17fdac43a29464181809727dc69b02567808e8", "username": "roman", "created_at": "2025-12-09T17:28:55.341515"}	admin	2025-12-09 20:28:55.341515
860	document_content	DELETE	{"id": 17, "id_batch": 1, "quantity": 10, "id_document": 12}	\N	postgres	2025-12-14 09:43:53.443618
1296	refresh_tokens	INSERT	\N	{"id": 298, "role": "admin", "token": "4dfc38ed135d1558bc9f3e4eabdac4af436afdcf9cf56a497db827ca3a222569", "username": "roman", "created_at": "2025-12-17T13:03:11.645138"}	admin	2025-12-17 13:03:11.645138
1297	refresh_tokens	DELETE	{"id": 298, "role": "admin", "token": "4dfc38ed135d1558bc9f3e4eabdac4af436afdcf9cf56a497db827ca3a222569", "username": "roman", "created_at": "2025-12-17T13:03:11.645138"}	\N	admin	2025-12-17 13:03:22.143324
1298	refresh_tokens	INSERT	\N	{"id": 299, "role": "admin", "token": "6973563795ce417706763791ed766d38b30453071058faecd175ecdfef4cb268", "username": "roman", "created_at": "2025-12-17T13:03:22.144967"}	admin	2025-12-17 13:03:22.144967
1299	refresh_tokens	INSERT	\N	{"id": 300, "role": "admin", "token": "5f28641de8625f00b12aecd58083722779a897bd955d58eac998c347e501eb63", "username": "roman", "created_at": "2025-12-17T13:03:53.787962"}	admin	2025-12-17 13:03:53.787962
1377	document	INSERT	\N	{"id": 22, "date": "2025-12-17", "id_employee": 2, "id_document_category": 2}	manager	2025-12-17 20:41:44.601251
1300	refresh_tokens	INSERT	\N	{"id": 301, "role": "admin", "token": "b7b16b2feed019eee53e43b203d6876d2eab800d9542734bf4d8226c0a4db54e", "username": "roman", "created_at": "2025-12-17T13:09:18.085891"}	admin	2025-12-17 13:09:18.085891
1301	refresh_tokens	DELETE	{"id": 301, "role": "admin", "token": "b7b16b2feed019eee53e43b203d6876d2eab800d9542734bf4d8226c0a4db54e", "username": "roman", "created_at": "2025-12-17T13:09:18.085891"}	\N	admin	2025-12-17 13:09:18.120887
1378	document_content	INSERT	\N	{"id": 32, "id_batch": 12, "quantity": 29, "id_document": 22}	manager	2025-12-17 20:47:26.16844
1302	refresh_tokens	INSERT	\N	{"id": 302, "role": "admin", "token": "3300892c0f7e6a501803b7377f7c91fa810e0ace3867b77f6736b6454632026b", "username": "roman", "created_at": "2025-12-17T13:10:49.785765"}	admin	2025-12-17 13:10:49.785765
1303	refresh_tokens	DELETE	{"id": 302, "role": "admin", "token": "3300892c0f7e6a501803b7377f7c91fa810e0ace3867b77f6736b6454632026b", "username": "roman", "created_at": "2025-12-17T13:10:49.785765"}	\N	admin	2025-12-17 13:10:49.834797
1304	refresh_tokens	INSERT	\N	{"id": 303, "role": "admin", "token": "44e8a024cba028b192282e2ee6904743bfc9f9714a4617cff4cf954834f0c40d", "username": "roman", "created_at": "2025-12-17T13:12:20.5392"}	admin	2025-12-17 13:12:20.5392
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
1305	refresh_tokens	DELETE	{"id": 303, "role": "admin", "token": "44e8a024cba028b192282e2ee6904743bfc9f9714a4617cff4cf954834f0c40d", "username": "roman", "created_at": "2025-12-17T13:12:20.5392"}	\N	admin	2025-12-17 13:12:20.608132
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
1306	refresh_tokens	INSERT	\N	{"id": 304, "role": "admin", "token": "5a9ff1fc3872f8049fdac57102339d1aa02a0ab9e5cd5db0c0020f774b6b9d66", "username": "roman", "created_at": "2025-12-17T13:13:47.791427"}	admin	2025-12-17 13:13:47.791427
1309	refresh_tokens	DELETE	{"id": 305, "role": "admin", "token": "99ddc0c6beda7d90aaa05fbae0359bb1c0737eba291141541d6622979f61711a", "username": "roman", "created_at": "2025-12-17T13:14:04.432"}	\N	admin	2025-12-17 13:14:47.726096
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
1307	refresh_tokens	DELETE	{"id": 304, "role": "admin", "token": "5a9ff1fc3872f8049fdac57102339d1aa02a0ab9e5cd5db0c0020f774b6b9d66", "username": "roman", "created_at": "2025-12-17T13:13:47.791427"}	\N	admin	2025-12-17 13:14:04.406544
1308	refresh_tokens	INSERT	\N	{"id": 305, "role": "admin", "token": "99ddc0c6beda7d90aaa05fbae0359bb1c0737eba291141541d6622979f61711a", "username": "roman", "created_at": "2025-12-17T13:14:04.432"}	admin	2025-12-17 13:14:04.432
797	refresh_tokens	INSERT	\N	{"id": 214, "role": "moderator", "token": "5fcf6d8687bef4a39aa9a45600f67b217aa242d8d4b48dcc3491edb08df78a6b", "username": "moderator_login", "created_at": "2025-12-10T19:54:30.673316"}	admin	2025-12-10 19:54:30.673316
1310	refresh_tokens	INSERT	\N	{"id": 306, "role": "admin", "token": "e7b49c23b1613fab8a5454da2d49c6256004012f245fe09f487b038f18e0bce0", "username": "roman", "created_at": "2025-12-17T13:15:01.550886"}	admin	2025-12-17 13:15:01.550886
738	refresh_tokens	DELETE	{"id": 200, "role": "admin", "token": "f586dcf7f2e3e55923bf03c439e84982bbe607509a27ef666df1cce238592bfc", "username": "roman", "created_at": "2025-12-10T12:54:30.047903"}	\N	admin	2025-12-10 16:22:16.959593
739	refresh_tokens	INSERT	\N	{"id": 201, "role": "manager", "token": "4a57c27bea5495e62cb3be3f8dda576706c5db9c0c668fd50d4fa7d3ddb8e0fe", "username": "anna_sokolova", "created_at": "2025-12-10T13:22:23.466726"}	admin	2025-12-10 16:22:23.466726
740	refresh_tokens	DELETE	{"id": 201, "role": "manager", "token": "4a57c27bea5495e62cb3be3f8dda576706c5db9c0c668fd50d4fa7d3ddb8e0fe", "username": "anna_sokolova", "created_at": "2025-12-10T13:22:23.466726"}	\N	admin	2025-12-10 16:23:12.551108
741	refresh_tokens	INSERT	\N	{"id": 202, "role": "moderator", "token": "ad0c8ce65da7299d59769e98dec9daa5e1b91d04aea060ba368f8f686d0cc4c4", "username": "moderator_login", "created_at": "2025-12-10T13:23:29.447706"}	admin	2025-12-10 16:23:29.447706
742	refresh_tokens	DELETE	{"id": 202, "role": "moderator", "token": "ad0c8ce65da7299d59769e98dec9daa5e1b91d04aea060ba368f8f686d0cc4c4", "username": "moderator_login", "created_at": "2025-12-10T13:23:29.447706"}	\N	admin	2025-12-10 16:24:04.344023
743	refresh_tokens	INSERT	\N	{"id": 203, "role": "admin", "token": "598e6a2f016fffe4094993aad1207027e87bdede47d2f79e0dafb4859f57b21e", "username": "roman", "created_at": "2025-12-10T13:24:08.564651"}	admin	2025-12-10 16:24:08.564651
748	refresh_tokens	DELETE	{"id": 199, "role": "admin", "token": "0e9bae1bacdd4c705a529e7c202c56e2f072f4dd5c768d6743ba3f8e1ddc6108", "username": "artem_volkov", "created_at": "2025-12-10T12:04:50.5637"}	\N	admin	2025-12-10 16:44:46.782929
749	refresh_tokens	INSERT	\N	{"id": 204, "role": "admin", "token": "85516cd64f8aa03b58757e5278c437d23604ccb86b06031a66152a9e53fee6d6", "username": "artem_volkov", "created_at": "2025-12-10T16:44:46.78871"}	admin	2025-12-10 16:44:46.78871
750	product_category	INSERT	\N	{"id": 10, "name": "тест"}	admin	2025-12-10 16:52:44.523289
751	product_category	UPDATE	{"id": 10, "name": "тест"}	{"id": 10, "name": "тес"}	admin	2025-12-10 16:53:53.871093
752	product_category	DELETE	{"id": 10, "name": "тес"}	\N	admin	2025-12-10 16:53:57.537549
753	product_category	INSERT	\N	{"id": 11, "name": "test"}	admin	2025-12-10 16:54:07.809085
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
1311	refresh_tokens	DELETE	{"id": 306, "role": "admin", "token": "e7b49c23b1613fab8a5454da2d49c6256004012f245fe09f487b038f18e0bce0", "username": "roman", "created_at": "2025-12-17T13:15:01.550886"}	\N	admin	2025-12-17 13:15:17.039856
828	role	DELETE	{"id": 6, "name": "тест", "sys_role": "тест", "description": "тест"}	\N	postgres	2025-12-11 15:15:18.679369
829	refresh_tokens	INSERT	\N	{"id": 230, "role": "admin", "token": "718fc4aba671be934b3de1d05ead93c6736e12b1b4b47b839c93e77f28bc29d8", "username": "roman", "created_at": "2025-12-11T16:17:36.189206"}	admin	2025-12-11 16:17:36.189206
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
912	refresh_tokens	INSERT	\N	{"id": 251, "role": "admin", "token": "d2fa534d8714af1bdb48011fb65b3ccaa42706393205090f238ec5bc7644a5a0", "username": "roman", "created_at": "2025-12-14T12:43:15.269569"}	admin	2025-12-14 12:43:15.269569
928	refresh_tokens	DELETE	{"id": 244, "role": "admin", "token": "de27e16cb2b0ea85655cd06241391b37a204beb075c38e3de23fcef24c9f06bc", "username": "roman", "created_at": "2025-12-14T10:13:08.886217"}	\N	admin	2025-12-14 13:09:17.111267
929	refresh_tokens	INSERT	\N	{"id": 252, "role": "admin", "token": "1f6b676dc0eb86aa501c8412318b3456c6b5c7193055908cb730377870403249", "username": "roman", "created_at": "2025-12-14T13:09:17.124127"}	admin	2025-12-14 13:09:17.124127
930	employee	DELETE	{"id": 17, "inn": "111112213111", "surname": "test", "firstname": "test", "id_gender": 3, "birth_date": "2001-06-16", "id_address": 24, "patronymic": "test", "id_position": 3, "phone_number": "+7 900 000-00-00"}	\N	admin	2025-12-14 14:00:44.989801
931	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 693-19-54"}	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 694-19-53"}	admin	2025-12-14 14:00:54.406815
932	refresh_tokens	INSERT	\N	{"id": 253, "role": "admin", "token": "9dda30ac9afbaa1c73a3bdf6e12787ddbd3a61565cab38518aba5e448817a716", "username": "roman", "created_at": "2025-12-14T17:18:48.665093"}	admin	2025-12-14 17:18:48.665093
933	refresh_tokens	INSERT	\N	{"id": 254, "role": "admin", "token": "feba0543bed24fa1dcb649c82e0d9217de2b1ea6b93b1ad4e972e986ccfff036", "username": "roman", "created_at": "2025-12-14T17:42:17.245781"}	admin	2025-12-14 17:42:17.245781
934	refresh_tokens	INSERT	\N	{"id": 255, "role": "admin", "token": "5605611774d878506e68b781cdfde5183b117597d3325a505431724fa35d3449", "username": "roman", "created_at": "2025-12-14T17:42:22.913871"}	admin	2025-12-14 17:42:22.913871
935	employee	INSERT	\N	{"id": 20, "inn": "152636744636", "surname": "Михайлова", "firstname": "Арина", "id_gender": 2, "birth_date": "2009-12-25", "id_address": 25, "patronymic": "Александровна", "id_position": 4, "phone_number": "+7 921 696-60-46"}	admin	2025-12-14 17:44:50.862312
936	address	INSERT	\N	{"id": 27, "city": "Старая Русса", "region": "Старорусский", "street": "Красных Командиров", "subject": "Новгородская область", "building": 103}	admin	2025-12-14 17:45:25.384556
937	position	INSERT	\N	{"id": 16, "name": "Хозяин Майки", "description": "Чешет пузо и крутит хвост"}	admin	2025-12-14 17:45:52.47923
938	employee	UPDATE	{"id": 20, "inn": "152636744636", "surname": "Михайлова", "firstname": "Арина", "id_gender": 2, "birth_date": "2009-12-25", "id_address": 25, "patronymic": "Александровна", "id_position": 4, "phone_number": "+7 921 696-60-46"}	{"id": 20, "inn": "152636744636", "surname": "Михайлова", "firstname": "Арина", "id_gender": 2, "birth_date": "2009-12-25", "id_address": 27, "patronymic": "Александровна", "id_position": 16, "phone_number": "+7 921 696-60-46"}	admin	2025-12-14 17:46:07.726958
939	sys_user	INSERT	\N	{"id": 10, "login": "bebra", "id_role": 1, "id_employee": 20, "password_hash": "$2a$10$t4dibnBtLdDkJ1Bf2BeaDu.5FTY5rj09MYP2wea5y.usd6J2sFxMK"}	admin	2025-12-14 17:46:50.972403
940	sys_user	UPDATE	{"id": 10, "login": "bebra", "id_role": 1, "id_employee": 20, "password_hash": "$2a$10$t4dibnBtLdDkJ1Bf2BeaDu.5FTY5rj09MYP2wea5y.usd6J2sFxMK"}	{"id": 10, "login": "bebra", "id_role": 1, "id_employee": 20, "password_hash": "$2a$10$HABaoStxCb.nDKdkL98Oze/zaKRj5xzGl2OpV6bnsGE0yWx8t46sS"}	admin	2025-12-14 17:47:45.100048
941	refresh_tokens	DELETE	{"id": 255, "role": "admin", "token": "5605611774d878506e68b781cdfde5183b117597d3325a505431724fa35d3449", "username": "roman", "created_at": "2025-12-14T17:42:22.913871"}	\N	admin	2025-12-14 17:47:47.762332
942	refresh_tokens	INSERT	\N	{"id": 256, "role": "moderator", "token": "c29de8e244b22228d8e9a454f43ce656a0647a498be1d83536a26e17b4b6749f", "username": "bebra", "created_at": "2025-12-14T17:48:00.843655"}	admin	2025-12-14 17:48:00.843655
943	refresh_tokens	DELETE	{"id": 256, "role": "moderator", "token": "c29de8e244b22228d8e9a454f43ce656a0647a498be1d83536a26e17b4b6749f", "username": "bebra", "created_at": "2025-12-14T17:48:00.843655"}	\N	admin	2025-12-14 17:48:02.915883
944	refresh_tokens	INSERT	\N	{"id": 257, "role": "moderator", "token": "75ae086b4fb42a94a33562619a7040ba680b7b70d06b22b4e08d562e7e8d2a83", "username": "bebra", "created_at": "2025-12-14T17:48:09.983441"}	admin	2025-12-14 17:48:09.983441
945	refresh_tokens	INSERT	\N	{"id": 258, "role": "admin", "token": "57fb862747ff830565374e3476909225404386b9c952125d385db9394ed438fb", "username": "roman", "created_at": "2025-12-14T17:48:37.741212"}	admin	2025-12-14 17:48:37.741212
946	position	UPDATE	{"id": 16, "name": "Хозяин Майки", "description": "Чешет пузо и крутит хвост"}	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит хвост"}	admin	2025-12-14 17:49:08.00094
951	position	UPDATE	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит хвост"}	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище"}	admin	2025-12-14 17:50:38.772391
952	refresh_tokens	INSERT	\N	{"id": 259, "role": "moderator", "token": "c7455b1d3f004249b9850570e3331d7c92b24bf78c81e74d9c1cb295fa452355", "username": "bebra", "created_at": "2025-12-14T17:52:32.897248"}	admin	2025-12-14 17:52:32.897248
960	position	UPDATE	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище"}	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостищ"}	postgres	2025-12-14 17:58:18.441063
961	position	UPDATE	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостищ"}	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище"}	postgres	2025-12-14 17:59:00.038382
962	refresh_tokens	DELETE	{"id": 259, "role": "moderator", "token": "c7455b1d3f004249b9850570e3331d7c92b24bf78c81e74d9c1cb295fa452355", "username": "bebra", "created_at": "2025-12-14T17:52:32.897248"}	\N	postgres	2025-12-14 17:59:48.4856
963	position	UPDATE	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище"}	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище."}	postgres	2025-12-14 18:00:16.734172
964	position	UPDATE	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище."}	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище🥰"}	postgres	2025-12-14 18:00:24.925236
965	employee	UPDATE	{"id": 20, "inn": "152636744636", "surname": "Михайлова", "firstname": "Арина", "id_gender": 2, "birth_date": "2009-12-25", "id_address": 27, "patronymic": "Александровна", "id_position": 16, "phone_number": "+7 921 696-60-46"}	{"id": 20, "inn": "152636744636", "surname": "Михайлова", "firstname": "Арина", "id_gender": 2, "birth_date": "2009-12-25", "id_address": 27, "patronymic": "Александровна", "id_position": 16, "phone_number": "+7 921 696-60-46"}	postgres	2025-12-14 18:02:21.563747
966	employee	UPDATE	{"id": 14, "inn": "111111111112", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 694-19-53"}	{"id": 14, "inn": "222222222222", "surname": "Михайлов", "firstname": "Роман", "id_gender": 1, "birth_date": "2005-07-22", "id_address": 1, "patronymic": "Александрович", "id_position": 9, "phone_number": "+7 921 694-19-53"}	postgres	2025-12-14 18:02:40.198995
967	refresh_tokens	INSERT	\N	{"id": 260, "role": "admin", "token": "a4cc269c5d5d5a37c64c5b7b098d17b25a6c2fd0b232012d9b56d73354c7011e", "username": "roman", "created_at": "2025-12-14T18:04:46.219735"}	postgres	2025-12-14 18:04:46.219735
968	sys_user	UPDATE	{"id": 10, "login": "bebra", "id_role": 1, "id_employee": 20, "password_hash": "$2a$10$HABaoStxCb.nDKdkL98Oze/zaKRj5xzGl2OpV6bnsGE0yWx8t46sS"}	{"id": 10, "login": "bebra", "id_role": 4, "id_employee": 20, "password_hash": "$2a$10$wPoaA65sj3T8ThWz6QCg5epwcrU65QJTGrt07gGr4/mSGCMObdwpS"}	postgres	2025-12-14 18:09:13.487486
969	refresh_tokens	DELETE	{"id": 260, "role": "admin", "token": "a4cc269c5d5d5a37c64c5b7b098d17b25a6c2fd0b232012d9b56d73354c7011e", "username": "roman", "created_at": "2025-12-14T18:04:46.219735"}	\N	postgres	2025-12-14 18:09:28.13507
970	refresh_tokens	INSERT	\N	{"id": 261, "role": "admin", "token": "4cf370e89a32c1c70ee039cdc5f2cec68152f87f95a846360d42f1aa221f8b93", "username": "roman", "created_at": "2025-12-15T11:08:25.697423"}	postgres	2025-12-15 11:08:25.697423
971	refresh_tokens	INSERT	\N	{"id": 262, "role": "admin", "token": "43d42cc0c37f00d710314e69ad88716928ffde2c61faa54ffd577d1f8c8caef7", "username": "roman", "created_at": "2025-12-15T11:12:51.337366"}	postgres	2025-12-15 11:12:51.337366
972	employee	DELETE	{"id": 20, "inn": "152636744636", "surname": "Михайлова", "firstname": "Арина", "id_gender": 2, "birth_date": "2009-12-25", "id_address": 27, "patronymic": "Александровна", "id_position": 16, "phone_number": "+7 921 696-60-46"}	\N	postgres	2025-12-15 11:13:30.006061
973	sys_user	DELETE	{"id": 10, "login": "bebra", "id_role": 4, "id_employee": 20, "password_hash": "$2a$10$wPoaA65sj3T8ThWz6QCg5epwcrU65QJTGrt07gGr4/mSGCMObdwpS"}	\N	postgres	2025-12-15 11:13:30.006061
974	position	DELETE	{"id": 16, "name": "Хозяйка Майки", "description": "Чешет пузо и крутит пушнявый хвостище🥰"}	\N	postgres	2025-12-15 11:15:28.063416
975	refresh_tokens	DELETE	{"id": 262, "role": "admin", "token": "43d42cc0c37f00d710314e69ad88716928ffde2c61faa54ffd577d1f8c8caef7", "username": "roman", "created_at": "2025-12-15T11:12:51.337366"}	\N	postgres	2025-12-15 13:16:32.108629
976	refresh_tokens	INSERT	\N	{"id": 263, "role": "admin", "token": "2c0b2bdfb98f0cb0378c9e73364f4c2547d5319584ca1c659cbb51f68d0dea96", "username": "roman", "created_at": "2025-12-15T13:16:32.111741"}	postgres	2025-12-15 13:16:32.111741
977	refresh_tokens	INSERT	\N	{"id": 265, "role": "admin", "token": "a59304da22e80d4b7afeda6937744b9509f549123d198e5c8d55af092c31bc80", "username": "roman", "created_at": "2025-12-15T13:16:32.111895"}	postgres	2025-12-15 13:16:32.111895
978	refresh_tokens	INSERT	\N	{"id": 264, "role": "admin", "token": "08a639e4b6d30bd7b3b21c7b7845928f4249699b1933831b3db4604cbc363814", "username": "roman", "created_at": "2025-12-15T13:16:32.111785"}	postgres	2025-12-15 13:16:32.111785
979	refresh_tokens	INSERT	\N	{"id": 266, "role": "admin", "token": "6d7a4035f1e9db22538610b3bc5357fd3ba109bf5322c00beb47a17ce604375c", "username": "roman", "created_at": "2025-12-15T13:16:32.111845"}	postgres	2025-12-15 13:16:32.111845
980	refresh_tokens	INSERT	\N	{"id": 267, "role": "admin", "token": "e79ffddefef3550c58773877fb0d4b12651a3ee13789df8ccf77ff02e5833679", "username": "roman", "created_at": "2025-12-15T16:30:24.265205"}	postgres	2025-12-15 16:30:24.265205
981	refresh_tokens	DELETE	{"id": 267, "role": "admin", "token": "e79ffddefef3550c58773877fb0d4b12651a3ee13789df8ccf77ff02e5833679", "username": "roman", "created_at": "2025-12-15T16:30:24.265205"}	\N	postgres	2025-12-15 16:46:33.08308
982	refresh_tokens	INSERT	\N	{"id": 268, "role": "admin", "token": "413486ef71ff63e014d271f50e96a0c7eefdffd3816f5e280446dbb7a27e6ff1", "username": "roman", "created_at": "2025-12-15T16:50:59.745796"}	postgres	2025-12-15 16:50:59.745796
983	refresh_tokens	DELETE	{"id": 240, "role": "admin", "token": "8dae547f3d7dd9320135e600894fd355f3c76174431ec8e6cd14ceb8d3214caa", "username": "roman", "created_at": "2025-12-14T09:42:34.036465"}	\N	postgres	2025-12-15 17:26:38.394659
984	refresh_tokens	DELETE	{"id": 241, "role": "admin", "token": "6e3e1bbd9bba3337baea306d4f9e8d8693275fea7eea7f6f99835fbe9e041395", "username": "roman", "created_at": "2025-12-14T09:42:34.036505"}	\N	postgres	2025-12-15 17:26:38.394659
985	refresh_tokens	DELETE	{"id": 242, "role": "admin", "token": "42c2f9d8d09b1a3b0eebbd98e1919fb88f3b47e213c315de75aa599f0740ec53", "username": "roman", "created_at": "2025-12-14T09:42:34.036532"}	\N	postgres	2025-12-15 17:26:38.394659
986	refresh_tokens	DELETE	{"id": 243, "role": "admin", "token": "5fa9cc3a65800f84bcf7d7303b126179fa864f8967a7dd804e18dc8e16d36f55", "username": "roman", "created_at": "2025-12-14T09:42:34.036614"}	\N	postgres	2025-12-15 17:26:38.394659
987	refresh_tokens	DELETE	{"id": 250, "role": "admin", "token": "70d7ec97abb7dc12d1be9a39bd849555a25551061021b1443cb9fbede5c30026", "username": "roman", "created_at": "2025-12-14T11:21:16.805759"}	\N	postgres	2025-12-15 17:26:38.394659
988	refresh_tokens	DELETE	{"id": 251, "role": "admin", "token": "d2fa534d8714af1bdb48011fb65b3ccaa42706393205090f238ec5bc7644a5a0", "username": "roman", "created_at": "2025-12-14T12:43:15.269569"}	\N	postgres	2025-12-15 17:26:38.394659
989	refresh_tokens	DELETE	{"id": 252, "role": "admin", "token": "1f6b676dc0eb86aa501c8412318b3456c6b5c7193055908cb730377870403249", "username": "roman", "created_at": "2025-12-14T13:09:17.124127"}	\N	postgres	2025-12-15 17:26:38.394659
990	refresh_tokens	DELETE	{"id": 253, "role": "admin", "token": "9dda30ac9afbaa1c73a3bdf6e12787ddbd3a61565cab38518aba5e448817a716", "username": "roman", "created_at": "2025-12-14T17:18:48.665093"}	\N	postgres	2025-12-15 17:26:38.394659
991	refresh_tokens	DELETE	{"id": 254, "role": "admin", "token": "feba0543bed24fa1dcb649c82e0d9217de2b1ea6b93b1ad4e972e986ccfff036", "username": "roman", "created_at": "2025-12-14T17:42:17.245781"}	\N	postgres	2025-12-15 17:26:38.394659
992	refresh_tokens	DELETE	{"id": 257, "role": "moderator", "token": "75ae086b4fb42a94a33562619a7040ba680b7b70d06b22b4e08d562e7e8d2a83", "username": "bebra", "created_at": "2025-12-14T17:48:09.983441"}	\N	postgres	2025-12-15 17:26:38.394659
993	refresh_tokens	DELETE	{"id": 258, "role": "admin", "token": "57fb862747ff830565374e3476909225404386b9c952125d385db9394ed438fb", "username": "roman", "created_at": "2025-12-14T17:48:37.741212"}	\N	postgres	2025-12-15 17:26:38.394659
994	position	INSERT	\N	{"id": 17, "name": "", "description": ""}	postgres	2025-12-15 17:43:28.524031
995	position	DELETE	{"id": 17, "name": "", "description": ""}	\N	postgres	2025-12-15 17:43:32.257734
996	position	INSERT	\N	{"id": 18, "name": "", "description": ""}	postgres	2025-12-15 17:43:37.918652
997	position	DELETE	{"id": 18, "name": "", "description": ""}	\N	postgres	2025-12-15 17:43:45.084664
998	refresh_tokens	DELETE	{"id": 268, "role": "admin", "token": "413486ef71ff63e014d271f50e96a0c7eefdffd3816f5e280446dbb7a27e6ff1", "username": "roman", "created_at": "2025-12-15T16:50:59.745796"}	\N	postgres	2025-12-15 17:51:43.650647
999	refresh_tokens	INSERT	\N	{"id": 269, "role": "admin", "token": "e448da05058dae29102d7eb8752ab9987c704c2a4a5f3873e910abf41874eb8a", "username": "roman", "created_at": "2025-12-15T17:51:43.65451"}	postgres	2025-12-15 17:51:43.65451
1000	refresh_tokens	DELETE	{"id": 269, "role": "admin", "token": "e448da05058dae29102d7eb8752ab9987c704c2a4a5f3873e910abf41874eb8a", "username": "roman", "created_at": "2025-12-15T17:51:43.65451"}	\N	postgres	2025-12-15 17:54:19.330639
1001	refresh_tokens	INSERT	\N	{"id": 270, "role": "admin", "token": "da4c79156a3e65c9b5bd9118c8e7736a351602306fc1c2e7e04ebef07441a0e3", "username": "roman", "created_at": "2025-12-16T12:22:18.97324"}	postgres	2025-12-16 12:22:18.97324
1002	refresh_tokens	INSERT	\N	{"id": 271, "role": "admin", "token": "8156ddb6f681902c4b1e6fa89b26ffe74c395fde733281eaf4c7ca7be8a23783", "username": "roman", "created_at": "2025-12-16T12:40:02.775044"}	postgres	2025-12-16 12:40:02.775044
1003	refresh_tokens	DELETE	{"id": 271, "role": "admin", "token": "8156ddb6f681902c4b1e6fa89b26ffe74c395fde733281eaf4c7ca7be8a23783", "username": "roman", "created_at": "2025-12-16T12:40:02.775044"}	\N	postgres	2025-12-16 12:57:34.62517
1004	refresh_tokens	INSERT	\N	{"id": 272, "role": "admin", "token": "0b08cc60dec19580c5ea107d38d6e6949902a1a31f654c6ae09c7684bb66fa81", "username": "roman", "created_at": "2025-12-16T12:57:34.62747"}	postgres	2025-12-16 12:57:34.62747
1005	refresh_tokens	INSERT	\N	{"id": 273, "role": "admin", "token": "856f94cef487c4492267ad7f2a8dde428dc0bab71d307991b79b2df363f5a8e5", "username": "roman", "created_at": "2025-12-16T13:04:10.887"}	postgres	2025-12-16 13:04:10.887
1006	refresh_tokens	DELETE	{"id": 273, "role": "admin", "token": "856f94cef487c4492267ad7f2a8dde428dc0bab71d307991b79b2df363f5a8e5", "username": "roman", "created_at": "2025-12-16T13:04:10.887"}	\N	postgres	2025-12-16 13:23:30.73044
1007	refresh_tokens	INSERT	\N	{"id": 274, "role": "manager", "token": "ef45f2d88d4be12dc91e9fba26c8ab6a99265d1142d36299bf66904f418d5805", "username": "anna_sokolova", "created_at": "2025-12-16T13:23:38.38249"}	postgres	2025-12-16 13:23:38.38249
1008	refresh_tokens	DELETE	{"id": 274, "role": "manager", "token": "ef45f2d88d4be12dc91e9fba26c8ab6a99265d1142d36299bf66904f418d5805", "username": "anna_sokolova", "created_at": "2025-12-16T13:23:38.38249"}	\N	postgres	2025-12-16 13:24:53.461908
1009	refresh_tokens	INSERT	\N	{"id": 275, "role": "admin", "token": "2d92eee4e14626b33bd59a26f8c49babc8103285e7ab3e230d19f78ea374d9b8", "username": "roman", "created_at": "2025-12-16T13:24:58.61031"}	postgres	2025-12-16 13:24:58.61031
1010	refresh_tokens	DELETE	{"id": 275, "role": "admin", "token": "2d92eee4e14626b33bd59a26f8c49babc8103285e7ab3e230d19f78ea374d9b8", "username": "roman", "created_at": "2025-12-16T13:24:58.61031"}	\N	postgres	2025-12-16 13:25:11.865731
1011	refresh_tokens	INSERT	\N	{"id": 276, "role": "manager", "token": "bd6615564cae3eb619f4ff807c8d6f519512da12b8fc1a20a0df3903ddb54776", "username": "anna_sokolova", "created_at": "2025-12-16T13:25:17.108335"}	postgres	2025-12-16 13:25:17.108335
1012	refresh_tokens	DELETE	{"id": 276, "role": "manager", "token": "bd6615564cae3eb619f4ff807c8d6f519512da12b8fc1a20a0df3903ddb54776", "username": "anna_sokolova", "created_at": "2025-12-16T13:25:17.108335"}	\N	postgres	2025-12-16 13:27:18.516042
1013	refresh_tokens	INSERT	\N	{"id": 277, "role": "admin", "token": "01a39145828a77ae117d5914bd0897779cc657f25538f591c262da693df96e2a", "username": "roman", "created_at": "2025-12-16T13:27:22.335054"}	postgres	2025-12-16 13:27:22.335054
1014	refresh_tokens	DELETE	{"id": 277, "role": "admin", "token": "01a39145828a77ae117d5914bd0897779cc657f25538f591c262da693df96e2a", "username": "roman", "created_at": "2025-12-16T13:27:22.335054"}	\N	postgres	2025-12-16 13:44:21.955311
1015	refresh_tokens	INSERT	\N	{"id": 278, "role": "admin", "token": "50ea2218cd844e7df71cb7ce26e83ebf9c916eaea971c594a0ba38c42f577d08", "username": "roman", "created_at": "2025-12-16T13:47:38.852583"}	postgres	2025-12-16 13:47:38.852583
1016	product_category	INSERT	\N	{"id": 12, "name": "tst"}	postgres	2025-12-16 14:29:07.780904
1017	product_category	DELETE	{"id": 12, "name": "tst"}	\N	postgres	2025-12-16 14:29:26.153208
1018	refresh_tokens	INSERT	\N	{"id": 279, "role": "admin", "token": "2b87855c99a910401e8b76a148736635a6f0f100523c08ae41e2aac698e2a562", "username": "roman", "created_at": "2025-12-16T16:25:31.148669"}	admin	2025-12-16 16:25:31.148669
1019	refresh_tokens	DELETE	{"id": 279, "role": "admin", "token": "2b87855c99a910401e8b76a148736635a6f0f100523c08ae41e2aac698e2a562", "username": "roman", "created_at": "2025-12-16T16:25:31.148669"}	\N	admin	2025-12-16 16:28:47.580901
1020	refresh_tokens	INSERT	\N	{"id": 280, "role": "admin", "token": "768e3431afbbd650f057963af27a4259d0638f63a43b41b9ac842b789ec0391f", "username": "roman", "created_at": "2025-12-16T16:28:50.699704"}	admin	2025-12-16 16:28:50.699704
1021	refresh_tokens	DELETE	{"id": 280, "role": "admin", "token": "768e3431afbbd650f057963af27a4259d0638f63a43b41b9ac842b789ec0391f", "username": "roman", "created_at": "2025-12-16T16:28:50.699704"}	\N	admin	2025-12-16 19:31:43.182876
1022	refresh_tokens	INSERT	\N	{"id": 281, "role": "admin", "token": "73d82c395bf907611cdd0534d56218451e66cbab713e5ffa2fbad50e2a36983c", "username": "roman", "created_at": "2025-12-16T19:31:46.587314"}	admin	2025-12-16 19:31:46.587314
1312	refresh_tokens	INSERT	\N	{"id": 307, "role": "admin", "token": "ac86d72900c7df2616c3f412181ca7fefa6d962ff6016adfd03e774e8e896cfa", "username": "roman", "created_at": "2025-12-17T13:15:17.105626"}	admin	2025-12-17 13:15:17.105626
1313	refresh_tokens	DELETE	{"id": 307, "role": "admin", "token": "ac86d72900c7df2616c3f412181ca7fefa6d962ff6016adfd03e774e8e896cfa", "username": "roman", "created_at": "2025-12-17T13:15:17.105626"}	\N	admin	2025-12-17 13:15:17.16562
1142	refresh_tokens	DELETE	{"id": 288, "role": "moderator", "token": "d733773086db9a71b77756b8b2f6c084e2fc5bc52d8ac4401e5b70685676495f", "username": "artem_volkov", "created_at": "2025-12-17T09:06:11.396519"}	\N	admin	2025-12-17 09:10:57.344868
1109	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765205992498019007_54.jpeg", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	admin	2025-12-16 19:40:27.596085
1110	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765903227626256966_placeholder.png", "id_producer": 19, "id_product_category": 1}	admin	2025-12-16 19:40:27.626852
1314	refresh_tokens	INSERT	\N	{"id": 308, "role": "admin", "token": "e07c9f6a0df0437e144b8768930cbe02924f98805cc9683782f5a134efd2dd89", "username": "roman", "created_at": "2025-12-17T13:15:53.20631"}	admin	2025-12-17 13:15:53.20631
1100	product	UPDATE	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	{"id": 49, "name": "Материнская плата \\"Extreme Gamer\\"", "image_url": "/static/products/1765903187145978752_49.jpg", "id_producer": 20, "id_product_category": 2}	admin	2025-12-16 19:39:47.146283
1101	product	UPDATE	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/1765205949295874542_50.jpeg", "id_producer": 24, "id_product_category": 1}	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	admin	2025-12-16 19:39:52.945716
1102	product	UPDATE	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/1765903192956568255_50.jpeg", "id_producer": 24, "id_product_category": 1}	admin	2025-12-16 19:39:52.957003
1103	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765205959722191006_51.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	admin	2025-12-16 19:39:58.09183
1104	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765903198101334341_51.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-16 19:39:58.102152
1105	product	UPDATE	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/1765205970189001719_52.jpeg", "id_producer": 24, "id_product_category": 2}	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	admin	2025-12-16 19:40:02.255542
1106	product	UPDATE	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/1765903202264020468_52.jpeg", "id_producer": 24, "id_product_category": 2}	admin	2025-12-16 19:40:02.264311
1111	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765903227626256966_placeholder.png", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	admin	2025-12-16 19:41:32.300433
1107	product	UPDATE	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/1765205980936305918_53.jpeg", "id_producer": 20, "id_product_category": 3}	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	admin	2025-12-16 19:40:06.855448
1108	product	UPDATE	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/1765903206868323303_53.jpeg", "id_producer": 20, "id_product_category": 3}	admin	2025-12-16 19:40:06.869029
1115	product	UPDATE	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "/static/products/placeholder.png", "id_producer": 25, "id_product_category": 2}	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	admin	2025-12-16 19:42:50.060423
1116	product	UPDATE	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "/static/products/1765903370070236504_56.jpeg", "id_producer": 25, "id_product_category": 2}	admin	2025-12-16 19:42:50.070681
1315	refresh_tokens	DELETE	{"id": 308, "role": "admin", "token": "e07c9f6a0df0437e144b8768930cbe02924f98805cc9683782f5a134efd2dd89", "username": "roman", "created_at": "2025-12-17T13:15:53.20631"}	\N	admin	2025-12-17 13:18:35.887868
1316	refresh_tokens	INSERT	\N	{"id": 309, "role": "admin", "token": "ee0705e11653695b7f3d4794f079e8b683590207942ceaee1c966b76594e4035", "username": "roman", "created_at": "2025-12-17T13:18:35.900639"}	admin	2025-12-17 13:18:35.900639
1112	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765903292312522884_54.jpeg", "id_producer": 19, "id_product_category": 1}	admin	2025-12-16 19:41:32.313133
1113	product	UPDATE	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "/static/products/placeholder.png", "id_producer": 21, "id_product_category": 8}	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	admin	2025-12-16 19:42:46.013048
1114	product	UPDATE	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "/static/products/1765903366034484502_55.webp", "id_producer": 21, "id_product_category": 8}	admin	2025-12-16 19:42:46.03533
1117	refresh_tokens	DELETE	{"id": 281, "role": "admin", "token": "73d82c395bf907611cdd0534d56218451e66cbab713e5ffa2fbad50e2a36983c", "username": "roman", "created_at": "2025-12-16T19:31:46.587314"}	\N	admin	2025-12-16 19:54:39.437058
1118	refresh_tokens	INSERT	\N	{"id": 282, "role": "manager", "token": "7f7057eedf05c4b03bd4a0aa483fdf51d5274c740902f0cb1e894c181c4f0ccc", "username": "anna_sokolova", "created_at": "2025-12-16T19:54:45.205381"}	admin	2025-12-16 19:54:45.205381
1119	refresh_tokens	DELETE	{"id": 282, "role": "manager", "token": "7f7057eedf05c4b03bd4a0aa483fdf51d5274c740902f0cb1e894c181c4f0ccc", "username": "anna_sokolova", "created_at": "2025-12-16T19:54:45.205381"}	\N	admin	2025-12-16 19:57:09.87535
1120	refresh_tokens	INSERT	\N	{"id": 283, "role": "moderator", "token": "7b92ebad5404cc254ed9a056fb9fb0be4a71bff4007f9de6a392a2aef1295364", "username": "artem_volkov", "created_at": "2025-12-16T19:57:15.595655"}	admin	2025-12-16 19:57:15.595655
1121	refresh_tokens	DELETE	{"id": 283, "role": "moderator", "token": "7b92ebad5404cc254ed9a056fb9fb0be4a71bff4007f9de6a392a2aef1295364", "username": "artem_volkov", "created_at": "2025-12-16T19:57:15.595655"}	\N	admin	2025-12-16 19:57:56.281953
1122	refresh_tokens	INSERT	\N	{"id": 284, "role": "admin", "token": "7743f81a0b6543d4db8059ad41cb760da8452564d2491f3d223924a91f496c93", "username": "roman", "created_at": "2025-12-16T19:58:01.787256"}	admin	2025-12-16 19:58:01.787256
1123	refresh_tokens	DELETE	{"id": 261, "role": "admin", "token": "4cf370e89a32c1c70ee039cdc5f2cec68152f87f95a846360d42f1aa221f8b93", "username": "roman", "created_at": "2025-12-15T11:08:25.697423"}	\N	postgres	2025-12-16 19:58:54.928101
1124	refresh_tokens	DELETE	{"id": 264, "role": "admin", "token": "08a639e4b6d30bd7b3b21c7b7845928f4249699b1933831b3db4604cbc363814", "username": "roman", "created_at": "2025-12-15T13:16:32.111785"}	\N	postgres	2025-12-16 19:58:54.928101
1125	refresh_tokens	DELETE	{"id": 265, "role": "admin", "token": "a59304da22e80d4b7afeda6937744b9509f549123d198e5c8d55af092c31bc80", "username": "roman", "created_at": "2025-12-15T13:16:32.111895"}	\N	postgres	2025-12-16 19:58:54.928101
1126	refresh_tokens	DELETE	{"id": 266, "role": "admin", "token": "6d7a4035f1e9db22538610b3bc5357fd3ba109bf5322c00beb47a17ce604375c", "username": "roman", "created_at": "2025-12-15T13:16:32.111845"}	\N	postgres	2025-12-16 19:58:54.928101
1127	refresh_tokens	DELETE	{"id": 270, "role": "admin", "token": "da4c79156a3e65c9b5bd9118c8e7736a351602306fc1c2e7e04ebef07441a0e3", "username": "roman", "created_at": "2025-12-16T12:22:18.97324"}	\N	postgres	2025-12-16 19:58:54.928101
1128	refresh_tokens	DELETE	{"id": 272, "role": "admin", "token": "0b08cc60dec19580c5ea107d38d6e6949902a1a31f654c6ae09c7684bb66fa81", "username": "roman", "created_at": "2025-12-16T12:57:34.62747"}	\N	postgres	2025-12-16 19:58:54.928101
1129	refresh_tokens	DELETE	{"id": 278, "role": "admin", "token": "50ea2218cd844e7df71cb7ce26e83ebf9c916eaea971c594a0ba38c42f577d08", "username": "roman", "created_at": "2025-12-16T13:47:38.852583"}	\N	postgres	2025-12-16 19:58:54.928101
1130	refresh_tokens	DELETE	{"id": 263, "role": "admin", "token": "2c0b2bdfb98f0cb0378c9e73364f4c2547d5319584ca1c659cbb51f68d0dea96", "username": "roman", "created_at": "2025-12-15T13:16:32.111741"}	\N	postgres	2025-12-16 19:59:00.95927
1131	sys_user	UPDATE	{"id": 1, "login": "artem_volkov", "id_role": 1, "id_employee": 1, "password_hash": "$2a$10$z9I2uGqAHHc5paoMn9T5yOXLEEDnWMj/Pmwegsv/vdagYct7RKN1O"}	{"id": 1, "login": "artem_volkov", "id_role": 1, "id_employee": 1, "password_hash": "$2a$10$5UxxvAoCY9Duk7C5SakPaOQUArxR3AdVoR.a7/JbXJmVn2KjvanXO"}	admin	2025-12-16 19:59:38.223296
1132	sys_user	UPDATE	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$ONDNHqgfrEHpioEyaVSDxOG3icMHs3nEsqP1TpzC9jYgB142ezb26"}	{"id": 2, "login": "anna_sokolova", "id_role": 2, "id_employee": 2, "password_hash": "$2a$10$n95Lbm6e056TuzpxKSpAxeaATN8.zIHrhpCBVDXBBWsl4afz11J4m"}	admin	2025-12-16 19:59:43.67271
1133	refresh_tokens	DELETE	{"id": 284, "role": "admin", "token": "7743f81a0b6543d4db8059ad41cb760da8452564d2491f3d223924a91f496c93", "username": "roman", "created_at": "2025-12-16T19:58:01.787256"}	\N	admin	2025-12-16 19:59:50.317659
1134	refresh_tokens	INSERT	\N	{"id": 285, "role": "admin", "token": "046c94b38f41d2e249153f40abaaf43016583f20bc4170f441e692e1b4b6c519", "username": "roman", "created_at": "2025-12-16T19:59:57.126094"}	admin	2025-12-16 19:59:57.126094
1135	sys_user	DELETE	{"id": 5, "login": "moderator_login", "id_role": 1, "id_employee": 5, "password_hash": "$2a$10$Pw6ZaIDf.CT.lKiRy8RYWOuV5SB14tmuCmwBYCwQ7KnOaCgJCclOK"}	\N	admin	2025-12-16 20:00:08.196864
1136	refresh_tokens	DELETE	{"id": 285, "role": "admin", "token": "046c94b38f41d2e249153f40abaaf43016583f20bc4170f441e692e1b4b6c519", "username": "roman", "created_at": "2025-12-16T19:59:57.126094"}	\N	admin	2025-12-16 20:00:20.481519
1137	refresh_tokens	INSERT	\N	{"id": 286, "role": "admin", "token": "d3c9eed8183bf405befae63100d63c4deb5208600c4506c9d6d3392f2494e1ad", "username": "roman", "created_at": "2025-12-16T20:41:12.763096"}	admin	2025-12-16 20:41:12.763096
1138	refresh_tokens	INSERT	\N	{"id": 287, "role": "admin", "token": "50da8766aae56e3b685885ed5445fab6e0f0304ecf0eb56f17157c51b210c2f4", "username": "roman", "created_at": "2025-12-17T08:38:41.014909"}	admin	2025-12-17 08:38:41.014909
1139	refresh_tokens	DELETE	{"id": 287, "role": "admin", "token": "50da8766aae56e3b685885ed5445fab6e0f0304ecf0eb56f17157c51b210c2f4", "username": "roman", "created_at": "2025-12-17T08:38:41.014909"}	\N	admin	2025-12-17 08:39:03.336651
1140	refresh_tokens	INSERT	\N	{"id": 288, "role": "moderator", "token": "d733773086db9a71b77756b8b2f6c084e2fc5bc52d8ac4401e5b70685676495f", "username": "artem_volkov", "created_at": "2025-12-17T09:06:11.396519"}	admin	2025-12-17 09:06:11.396519
1143	refresh_tokens	INSERT	\N	{"id": 289, "role": "admin", "token": "54c4c9a6a5a42c44f15b4a4dc6d1481d0f1d0afd76538cc42eab36acf37fe28b", "username": "roman", "created_at": "2025-12-17T09:11:00.813721"}	admin	2025-12-17 09:11:00.813721
1144	refresh_tokens	DELETE	{"id": 289, "role": "admin", "token": "54c4c9a6a5a42c44f15b4a4dc6d1481d0f1d0afd76538cc42eab36acf37fe28b", "username": "roman", "created_at": "2025-12-17T09:11:00.813721"}	\N	admin	2025-12-17 09:12:52.147709
1145	refresh_tokens	INSERT	\N	{"id": 290, "role": "moderator", "token": "2ac10167cd31fce685a662cba074eb25ccbaf2d9e7c2b7e134d5fa8f44e9a891", "username": "artem_volkov", "created_at": "2025-12-17T09:13:01.261524"}	admin	2025-12-17 09:13:01.261524
1150	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765205440110440418_11.jpg", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	moderator	2025-12-17 09:14:58.842624
1151	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765952098865444795_11.jpg", "id_producer": 24, "id_product_category": 1}	moderator	2025-12-17 09:14:58.8674
1152	product	UPDATE	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "/static/products/1765354277653639797_7-.webp", "id_producer": 19, "id_product_category": 1}	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	moderator	2025-12-17 09:17:41.622992
1153	product	UPDATE	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 7, "name": "Кухонный гарнитур \\"Модерн\\"", "image_url": "/static/products/1765952261638764217_7.webp", "id_producer": 19, "id_product_category": 1}	moderator	2025-12-17 09:17:41.641359
1154	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765373224025730926_8.jpeg", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	moderator	2025-12-17 09:17:45.551919
1155	product	UPDATE	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	{"id": 8, "name": "Стиральная машина \\"EcoWash 3000\\"", "image_url": "/static/products/1765952265565825719_8.jpeg", "id_producer": 20, "id_product_category": 3}	moderator	2025-12-17 09:17:45.566557
1156	product	UPDATE	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "/static/products/1765205408580666042_9.avif", "id_producer": 26, "id_product_category": 3}	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	moderator	2025-12-17 09:17:49.027523
1157	product	UPDATE	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "", "id_producer": 26, "id_product_category": 3}	{"id": 9, "name": "Холодильник \\"CoolFridge X\\"", "image_url": "/static/products/1765952269041604596_9.avif", "id_producer": 26, "id_product_category": 3}	moderator	2025-12-17 09:17:49.041991
1158	product	UPDATE	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "/static/products/1765205423056717632_10.webp", "id_producer": 20, "id_product_category": 2}	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	moderator	2025-12-17 09:17:53.738164
1159	product	UPDATE	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "", "id_producer": 20, "id_product_category": 2}	{"id": 10, "name": "Материнская плата \\"Gamer Pro\\"", "image_url": "/static/products/1765952273760593959_10.webp", "id_producer": 20, "id_product_category": 2}	moderator	2025-12-17 09:17:53.761217
1160	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765952098865444795_11.jpg", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	moderator	2025-12-17 09:17:58.321154
1161	product	UPDATE	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 11, "name": "Офисное кресло \\"Comfort\\"", "image_url": "/static/products/1765952278342195878_11.jpg", "id_producer": 24, "id_product_category": 1}	moderator	2025-12-17 09:17:58.343186
1162	product	UPDATE	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "/static/products/1765205452018769299_12.jpeg", "id_producer": 21, "id_product_category": 8}	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	moderator	2025-12-17 09:18:01.518978
1163	product	UPDATE	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 12, "name": "Сковорода \\"Chef 28\\"", "image_url": "/static/products/1765952281530386879_12.jpeg", "id_producer": 21, "id_product_category": 8}	moderator	2025-12-17 09:18:01.5306
1164	product	UPDATE	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "/static/products/1765205465161011013_13.jpg", "id_producer": 24, "id_product_category": 2}	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	moderator	2025-12-17 09:18:05.031315
1165	product	UPDATE	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	{"id": 13, "name": "Лампа настольная \\"LightUp\\"", "image_url": "/static/products/1765952285042678923_13.jpg", "id_producer": 24, "id_product_category": 2}	moderator	2025-12-17 09:18:05.04308
1166	product	UPDATE	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/1765903192956568255_50.jpeg", "id_producer": 24, "id_product_category": 1}	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	moderator	2025-12-17 09:18:27.412158
1167	product	UPDATE	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "", "id_producer": 24, "id_product_category": 1}	{"id": 50, "name": "Стул \\"ErgoChair\\"", "image_url": "/static/products/1765952307421766044_50.jpeg", "id_producer": 24, "id_product_category": 1}	moderator	2025-12-17 09:18:27.42193
1172	product	UPDATE	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/1765903206868323303_53.jpeg", "id_producer": 20, "id_product_category": 3}	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	moderator	2025-12-17 09:18:39.055534
1173	product	UPDATE	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "", "id_producer": 20, "id_product_category": 3}	{"id": 53, "name": "Стиральная машина \\"WashMaster 4000\\"", "image_url": "/static/products/1765952319066905883_53.jpeg", "id_producer": 20, "id_product_category": 3}	moderator	2025-12-17 09:18:39.068044
1176	product	UPDATE	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "/static/products/1765903366034484502_55.webp", "id_producer": 21, "id_product_category": 8}	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	moderator	2025-12-17 09:18:50.560863
1177	product	UPDATE	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "", "id_producer": 21, "id_product_category": 8}	{"id": 55, "name": "Сковорода \\"Chef Classic\\"", "image_url": "/static/products/1765952330576268638_55.webp", "id_producer": 21, "id_product_category": 8}	moderator	2025-12-17 09:18:50.576662
1178	product	UPDATE	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "/static/products/1765903370070236504_56.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	moderator	2025-12-17 09:18:55.362814
1179	product	UPDATE	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 56, "name": "Дрель \\"ProDrill 500\\"", "image_url": "/static/products/1765952335376777793_56.jpeg", "id_producer": 25, "id_product_category": 2}	moderator	2025-12-17 09:18:55.377289
1320	refresh_tokens	INSERT	\N	{"id": 310, "role": "admin", "token": "67719c17fff288e97d1341a8ae98907f958bc05a8fbecb3b877a2fc4b5c5acaf", "username": "roman", "created_at": "2025-12-17T13:22:19.328692"}	admin	2025-12-17 13:22:19.328692
1168	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765903198101334341_51.jpeg", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	moderator	2025-12-17 09:18:32.015669
1169	product	UPDATE	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "", "id_producer": 25, "id_product_category": 2}	{"id": 51, "name": "Газонокосилка \\"PowerCut\\"", "image_url": "/static/products/1765952312028675296_51.jpeg", "id_producer": 25, "id_product_category": 2}	moderator	2025-12-17 09:18:32.029227
1170	product	UPDATE	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/1765903202264020468_52.jpeg", "id_producer": 24, "id_product_category": 2}	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	moderator	2025-12-17 09:18:35.429257
1171	product	UPDATE	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "", "id_producer": 24, "id_product_category": 2}	{"id": 52, "name": "Лампа потолочная \\"BrightSky\\"", "image_url": "/static/products/1765952315441670964_52.jpeg", "id_producer": 24, "id_product_category": 2}	moderator	2025-12-17 09:18:35.442119
1174	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765903292312522884_54.jpeg", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	moderator	2025-12-17 09:18:47.003064
1175	product	UPDATE	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "", "id_producer": 19, "id_product_category": 1}	{"id": 54, "name": "Кухонный стол \\"Modern\\"", "image_url": "/static/products/1765952327015113345_54.jpeg", "id_producer": 19, "id_product_category": 1}	moderator	2025-12-17 09:18:47.015573
1180	product	UPDATE	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "/static/products/1765011046095675919_a4c7c78c78a454e231f7718718ae6195.jpg", "id_producer": 1, "id_product_category": 1}	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "", "id_producer": 1, "id_product_category": 1}	moderator	2025-12-17 09:25:13.699417
1181	product	UPDATE	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "", "id_producer": 1, "id_product_category": 1}	{"id": 1, "name": "Кухонный гарнитур \\"Уют\\"", "image_url": "/static/products/1765952713714676218_1.jpg", "id_producer": 1, "id_product_category": 1}	moderator	2025-12-17 09:25:13.715903
1182	product	UPDATE	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "/static/products/1765011070099983639_images (3).jpeg", "id_producer": 2, "id_product_category": 2}	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "", "id_producer": 2, "id_product_category": 2}	moderator	2025-12-17 09:25:17.06117
1183	product	UPDATE	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "", "id_producer": 2, "id_product_category": 2}	{"id": 2, "name": "Стиральная машина \\"SM-5000\\"", "image_url": "/static/products/1765952717072174470_2.jpeg", "id_producer": 2, "id_product_category": 2}	moderator	2025-12-17 09:25:17.07247
1184	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765008872100895552_7179111216.jpg", "id_producer": 3, "id_product_category": 2}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "", "id_producer": 3, "id_product_category": 2}	moderator	2025-12-17 09:25:20.355397
1185	product	UPDATE	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "", "id_producer": 3, "id_product_category": 2}	{"id": 3, "name": "Материнская плата \\"Gamer XTREME\\"", "image_url": "/static/products/1765952720374941263_3.jpg", "id_producer": 3, "id_product_category": 2}	moderator	2025-12-17 09:25:20.376696
1186	product	UPDATE	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "/static/products/1765011089390225675_images (2).jpeg", "id_producer": 1, "id_product_category": 1}	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "", "id_producer": 1, "id_product_category": 1}	moderator	2025-12-17 09:25:24.751859
1187	product	UPDATE	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "", "id_producer": 1, "id_product_category": 1}	{"id": 4, "name": "Офисное кресло \\"Director\\"", "image_url": "/static/products/1765952724762478626_4.jpeg", "id_producer": 1, "id_product_category": 1}	moderator	2025-12-17 09:25:24.762718
1188	product	UPDATE	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "/static/products/1765011109815931171_images.jpeg", "id_producer": 2, "id_product_category": 2}	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "", "id_producer": 2, "id_product_category": 2}	moderator	2025-12-17 09:25:28.175456
1189	product	UPDATE	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "", "id_producer": 2, "id_product_category": 2}	{"id": 5, "name": "Холодильник \\"Frost+ 300\\"", "image_url": "/static/products/1765952728186622503_5.jpeg", "id_producer": 2, "id_product_category": 2}	moderator	2025-12-17 09:25:28.186725
1190	refresh_tokens	DELETE	{"id": 290, "role": "moderator", "token": "2ac10167cd31fce685a662cba074eb25ccbaf2d9e7c2b7e134d5fa8f44e9a891", "username": "artem_volkov", "created_at": "2025-12-17T09:13:01.261524"}	\N	admin	2025-12-17 09:26:03.008851
1191	refresh_tokens	INSERT	\N	{"id": 291, "role": "admin", "token": "7eed6ac88f19552f91f848632cab3eb6161dc315a7e42a7a0903802ba0e2399a", "username": "roman", "created_at": "2025-12-17T09:26:07.116055"}	admin	2025-12-17 09:26:07.116055
1321	refresh_tokens	DELETE	{"id": 310, "role": "admin", "token": "67719c17fff288e97d1341a8ae98907f958bc05a8fbecb3b877a2fc4b5c5acaf", "username": "roman", "created_at": "2025-12-17T13:22:19.328692"}	\N	admin	2025-12-17 14:22:32.40487
1322	refresh_tokens	INSERT	\N	{"id": 311, "role": "admin", "token": "6a44bcf71b471d39c9991269246ef74522afc48b234155fcab9b6cb5d05d2b6f", "username": "roman", "created_at": "2025-12-17T14:22:32.411505"}	admin	2025-12-17 14:22:32.411505
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
12	50	2025-12-17	2035-12-17	70	2025-12-17 19:53:27.255671
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
19	2025-12-17	2	1
20	2025-12-17	2	3
22	2025-12-17	2	2
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
29	19	12	100
30	20	12	100
32	22	12	29
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
14	Михайлов	Роман	Александрович	1	222222222222	+7 921 694-19-53	1	2005-07-22	9
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
28	ООО "Первый класс"	9	6456387568	Иванов	Петр	Сидорович
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product (id, name, id_product_category, id_producer, image_url) FROM stdin;
31	Материнская плата "ProBoard"	2	20	/static/products/1765957184719296760_31.jpg
14	Дрель "PowerTool 300"	2	25	/static/products/1765957117118564756_14.jpeg
16	Газонокосилка "GreenCut"	2	25	/static/products/1765957123605219718_16.jpg
15	Постельное белье "Luxury"	1	24	/static/products/1765957120820601966_15.jpeg
18	Тумба под ТВ "Classic"	1	19	/static/products/1765957131997504097_18.jpeg
17	Стул "WoodChair"	1	24	/static/products/1765957127035473261_17.jpeg
20	Холодильник "FreezePlus"	3	26	/static/products/1765957138526011169_20.jpeg
19	Плита "HeatMaster"	3	26	/static/products/1765957135057974126_19.avif
22	Сковорода "PanExpert"	8	21	/static/products/1765957146260570714_22.jpeg
21	Телевизор "SmartVision"	2	20	/static/products/1765957141710564754_21.jpeg
27	Диван "Relax"	1	24	/static/products/1765957167032808710_27.webp
23	Лампа "BrightHome"	2	24	/static/products/1765957150151930841_23.jpeg
24	Шуруповерт "DrillMax"	2	25	/static/products/1765957154192326426_24.jpeg
25	Полотенца "SoftLine"	8	24	/static/products/1765957158257484678_25.webp
28	Кухонный стол "Classic"	1	19	/static/products/1765957172116750046_28.webp
26	Газонокосилка "EcoCut"	2	25	/static/products/1765957163376438333_26.jpeg
30	Стиральная машина "UltraWash"	3	20	/static/products/1765957180690130300_30.png
33	Кастрюля "CookMaster"	8	21	/static/products/1765957193732642500_33.jpeg
29	Микроволновка "QuickHeat"	3	26	/static/products/1765957177103111631_29.jpeg
2	Стиральная машина "SM-5000"	3	2	/static/products/1765952717072174470_2.jpeg
32	Стул "Office"	1	24	/static/products/1765957189862935304_32.webp
35	Дрель "MaxDrill"	2	25	/static/products/1765957203287260630_35.jpeg
34	Лампа потолочная "SkyLight"	2	24	/static/products/1765957198478194169_34.jpeg
37	Сковорода "Chef Pro 30"	8	21	/static/products/1765957211474830383_37.webp
36	Постельное белье "Comfort"	1	24	/static/products/1765957207099011173_36.jpg
39	Кухонный гарнитур "Элегант"	1	19	/static/products/1765957223068063458_39.jpg
38	Стул "Comfort Plus"	1	24	/static/products/1765957218945988429_38.jpg
46	Кастрюля "ProCook"	8	21	/static/products/1765957256316873918_46.jpeg
43	Лампа "DeskLight"	2	24	/static/products/1765957240945953466_43.jpeg
42	Дрель "HandyDrill"	2	25	/static/products/1765957236865497715_42.webp
45	Постельное белье "Premium"	1	24	/static/products/1765957251431221846_45.jpg
44	Диван "SoftRelax"	1	24	/static/products/1765957246858076386_44.jpeg
47	Шкаф для одежды "Classic Wardrobe"	1	19	/static/products/1765957268661142799_47.jpeg
48	Микроволновка "SpeedHeat"	3	26	/static/products/1765957273217070551_48.jpeg
49	Материнская плата "Extreme Gamer"	2	20	/static/products/1765957277688558595_49.jpg
52	Лампа потолочная "BrightSky"	2	24	/static/products/1765952315441670964_52.jpeg
1	Кухонный гарнитур "Уют"	1	1	/static/products/1765952713714676218_1.jpg
54	Кухонный стол "Modern"	1	19	/static/products/1765952327015113345_54.jpeg
53	Стиральная машина "WashMaster 4000"	3	20	/static/products/1765952319066905883_53.jpeg
56	Дрель "ProDrill 500"	2	25	/static/products/1765952335376777793_56.jpeg
55	Сковорода "Chef Classic"	8	21	/static/products/1765952330576268638_55.webp
11	Офисное кресло "Comfort"	1	24	/static/products/1765952278342195878_11.jpg
8	Стиральная машина "EcoWash 3000"	3	20	/static/products/1765952265565825719_8.jpeg
7	Кухонный гарнитур "Модерн"	1	19	/static/products/1765952261638764217_7.webp
9	Холодильник "CoolFridge X"	3	26	/static/products/1765952269041604596_9.avif
10	Материнская плата "Gamer Pro"	2	20	/static/products/1765952273760593959_10.webp
51	Газонокосилка "PowerCut"	2	25	/static/products/1765952312028675296_51.jpeg
13	Лампа настольная "LightUp"	2	24	/static/products/1765952285042678923_13.jpg
12	Сковорода "Chef 28"	8	21	/static/products/1765952281530386879_12.jpeg
50	Стул "ErgoChair"	1	24	/static/products/1765952307421766044_50.jpeg
3	Материнская плата "Gamer XTREME"	2	3	/static/products/1765952720374941263_3.jpg
4	Офисное кресло "Director"	1	1	/static/products/1765952724762478626_4.jpeg
5	Холодильник "Frost+ 300"	2	2	/static/products/1765952728186622503_5.jpeg
67	Утюг "Ceramic Heat"	3	25	/static/products/1765955252842400588_6.jpeg
41	Телевизор "UltraHD 55"	2	20	/static/products/1765957230863736670_41.jpeg
40	Холодильник "Arctic 500"	3	26	/static/products/1765957226645823668_40.jpeg
69	Ноутбук	2	20	/static/products/1765978256093059347_1.jpeg
70	Тетрадь в клетку	13	28	/static/products/1765989317015642669_70.jpg
\.


--
-- Data for Name: product_category; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.product_category (id, name) FROM stdin;
1	Мебель
2	Электроника
3	Бытовая техника
8	Посуда
13	Канцелярские принадлежности
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refresh_tokens (id, token, username, role, created_at) FROM stdin;
313	fd6b15a551b1714519b9afaca22e47acc810045307a2b672a64fb6ec998f01c8	roman	admin	2025-12-17 15:34:43.388973
314	75a0792e162f4b741e384d45e20290cf68d77ac8128a72f3f408d6de09e108d0	roman	admin	2025-12-17 15:39:23.392631
315	70b481b63070d94342fd7a7f4f0e1f180ceffe4d8b047e9ae99f1e46301cb486	roman	admin	2025-12-17 15:40:35.762648
316	7f67c832795a36f1caa4ede536ee9196cb98af87d9d1dfe071ba8ab672697b98	roman	admin	2025-12-17 15:41:41.499096
317	2ed9311c9f5e64b0bdc0f82db18960f431067a3010ed8b51dc3431d5cabf32d0	roman	admin	2025-12-17 15:42:59.676015
318	010be9a2336420cb1b95a67b3f803953bc6f567331abddc2b4bd9b7aaac25768	roman	admin	2025-12-17 16:21:59.827534
319	ef901f70f8e4428bf2e19c5bf5bef4628dc4d523e0cdbeb55e0c426d9b042072	test	moderator	2025-12-17 16:26:19.405285
320	6663ea65dfc816f809e2bf72cde8101277259979c11f01cc660787af7cd1346a	anna_sokolova	manager	2025-12-17 16:26:49.504421
321	f594e892406be435a604e34e28db4c2f635c543a3e2d66bcdd87928999fe461c	roman	admin	2025-12-17 16:28:58.804567
322	e9d189671e08e2ad52a146812d3fc28e802e6969bc668f4bfad16ccf8a3dd4d0	anna_sokolova	manager	2025-12-17 16:30:34.28805
323	7cc6ca11a4749409ab53415bd26ad8b1ebb543a389e9e6c4c60b6c1f23a7e9d3	roman	admin	2025-12-17 16:31:07.814227
324	f34ece8a737481660d0fe055d834d36416cb807ffd1117e8fa8385c885411f75	roman	admin	2025-12-17 17:15:58.961162
325	97f3ee44bc606e32645dfa792ce539a85bbeaa340eee8e4ef7574aee4915676d	roman	admin	2025-12-17 17:35:38.623463
326	16ad8077cb7e7c2b34a0a2c7b403420c8ffe10d238066af6bcc30790d304b27c	anna_sokolova	manager	2025-12-17 17:35:53.899284
327	d80cc6b149f248d049d58ae3b076de2d82723bc3fcb6b8ebaac651c34a9cc7d9	anna_sokolova	manager	2025-12-17 19:09:05.835201
328	80f9ae9cba6e8843e6f082f090f19814b151a304d54dac12c50a05414c22959a	artem_volkov	moderator	2025-12-17 19:11:03.047322
329	5655dc24a82080cb21b335ee356630c0c2bb7a306dba5437c880e67cb211a38c	anna_sokolova	manager	2025-12-17 19:12:43.774039
330	d3708f6357e5a0e80f2cb0c4c723fa015a9506409a5807d729a48e4bfcbd499f	roman	admin	2025-12-17 19:57:02.656177
331	e2f90a931eeaf3784b5ae2f998bf308b83dc49341b1f233d9ae05400cc145d4c	anna_sokolova	manager	2025-12-17 19:59:23.802914
332	f3255461bbe89584e7bd063ced5a36f07008212985714469fc433882f30fc7b3	roman	admin	2025-12-17 20:06:06.971254
333	d1b24a2fe9fa9992ed480f0b28a74c1e448d9fb19617d5636373f83eb660905e	anna_sokolova	manager	2025-12-17 20:06:20.544899
334	2be0dde2f2cbba21224a38d67da91dd794d5cd0db45e10924078fe436953c551	roman	admin	2025-12-17 20:39:59.84224
335	eb67f4830d5ed751262a1c073dca1916ae198867a22a77d81630c038a84d21c8	anna_sokolova	manager	2025-12-17 20:40:18.435497
336	089ee28b14dbee52f31f722c086b4f9ea69c5fddff6abc55e7aa91c2f72dabf5	anna_sokolova	manager	2025-12-18 11:56:20.588464
337	c1cfb326b2dd510bd2bd0fade9ab922d52febd8967f6165e1e7c8fe31fcca69f	artem_volkov	moderator	2025-12-18 12:43:13.448528
339	80147c40e86e60963dd7cb8af0760a61c4f7516c7e9494d49b9a3dc5ad98fc10	artem_volkov	moderator	2025-12-18 12:54:36.238138
340	442f66368cb47cf445190b787eb9a4c4e4fe297f3c4ec0404a780a08471d7ecd	roman	admin	2025-12-18 12:58:20.912379
341	3ed44c11de507638488207485956ccb91a91076e1f3c3f2a4a80ac5cb7d32e14	roman	admin	2025-12-18 13:22:00.92475
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
7	roman	$2a$10$4MWSzOFhEH9X4P25w7YgCeJkH5FoB8lx4S69iRPsnFunJiPOXWYDa	4	14
1	artem_volkov	$2a$10$5UxxvAoCY9Duk7C5SakPaOQUArxR3AdVoR.a7/JbXJmVn2KjvanXO	1	1
2	anna_sokolova	$2a$10$n95Lbm6e056TuzpxKSpAxeaATN8.zIHrhpCBVDXBBWsl4afz11J4m	2	2
11	test	$2a$10$NSThg/ovlf5fqE0WNhfEEu38UtXoVgy.ZNHh1hyLEg0dM9lJR7iU6	1	3
12	denis_orlov	$2a$10$ZKe3pjOAPtB5CIMWcvT0q.B8/gldZefclTGV9ruv60CvI/RHKtWeO	4	4
\.


--
-- Name: address_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.address_id_seq', 27, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 1392, true);


--
-- Name: batch_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.batch_id_seq', 12, true);


--
-- Name: document_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_category_id_seq', 13, true);


--
-- Name: document_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_content_id_seq', 32, true);


--
-- Name: document_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.document_id_seq', 22, true);


--
-- Name: employee_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employee_id_seq', 20, true);


--
-- Name: gender_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.gender_id_seq', 3, true);


--
-- Name: position_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.position_id_seq', 18, true);


--
-- Name: producer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.producer_id_seq', 28, true);


--
-- Name: product_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_category_id_seq', 13, true);


--
-- Name: product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.product_id_seq', 73, true);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.refresh_tokens_id_seq', 341, true);


--
-- Name: role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.role_id_seq', 6, true);


--
-- Name: sys_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sys_user_id_seq', 12, true);


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
-- Name: idx_audit_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_changed_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_changed_at ON public.audit_log USING btree (changed_at DESC);


--
-- Name: idx_audit_changed_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_changed_by ON public.audit_log USING btree (changed_by);


--
-- Name: idx_audit_table; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_table ON public.audit_log USING btree (table_name);


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
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.audit_log TO moderator;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.audit_log TO manager;


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
GRANT SELECT ON TABLE public.document_category TO manager;


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
-- Name: TABLE product; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.product TO admin;
GRANT SELECT,UPDATE ON TABLE public.product TO moderator;
GRANT SELECT,INSERT,UPDATE ON TABLE public.product TO manager;


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
-- PostgreSQL database dump complete
--

\unrestrict 73PNpKlNZ9wEJvGh3PwHWGRq7fvnmIGv7lDG7DBSbguer83bScxDfzHOFQ7FheM

