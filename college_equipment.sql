--
-- PostgreSQL database dump
--

\restrict KFbcte2KmtQ1jDiJiwbbYQ2XL1gFsJAW0OniAjmw70WJemk0710hfaF0NLqhbEi

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'WIN1251';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: get_fault_stats(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_fault_stats(p_date_from date, p_date_to date) RETURNS TABLE(inventory_number character varying, equipment_name character varying, fault_count bigint, fixed_count bigint, open_count bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        e.inventory_number,
        e.name,
        COUNT(r.id) AS fault_count,
        COUNT(r.id) FILTER (WHERE r.is_fixed) AS fixed_count,
        COUNT(r.id) FILTER (WHERE NOT r.is_fixed) AS open_count
    FROM repair_log r
    JOIN equipment e ON e.id = r.equipment_id
    WHERE r.fault_date BETWEEN p_date_from AND p_date_to
    GROUP BY e.inventory_number, e.name
    ORDER BY fault_count DESC;
END;
$$;


ALTER FUNCTION public.get_fault_stats(p_date_from date, p_date_to date) OWNER TO postgres;

--
-- Name: trg_check_repair_date(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_check_repair_date() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.is_fixed = TRUE AND NEW.repair_date IS NULL THEN
        RAISE EXCEPTION 'Нельзя закрыть ремонт без указания даты ремонта (repair_date)';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trg_check_repair_date() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: equipment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment (
    id integer NOT NULL,
    inventory_number character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    model character varying(100),
    type_id integer,
    room_id integer,
    status_id integer,
    purchase_date date,
    price numeric(10,2),
    CONSTRAINT equipment_price_check CHECK ((price >= (0)::numeric))
);


ALTER TABLE public.equipment OWNER TO postgres;

--
-- Name: equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_id_seq OWNER TO postgres;

--
-- Name: equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipment_id_seq OWNED BY public.equipment.id;


--
-- Name: equipment_status; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_status (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.equipment_status OWNER TO postgres;

--
-- Name: equipment_status_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipment_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_status_id_seq OWNER TO postgres;

--
-- Name: equipment_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipment_status_id_seq OWNED BY public.equipment_status.id;


--
-- Name: equipment_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.equipment_types (
    id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.equipment_types OWNER TO postgres;

--
-- Name: equipment_types_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.equipment_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_types_id_seq OWNER TO postgres;

--
-- Name: equipment_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.equipment_types_id_seq OWNED BY public.equipment_types.id;


--
-- Name: repair_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.repair_log (
    id integer NOT NULL,
    equipment_id integer NOT NULL,
    fault_date date NOT NULL,
    description text,
    repair_date date,
    is_fixed boolean DEFAULT false,
    CONSTRAINT repair_log_check CHECK (((repair_date IS NULL) OR (repair_date >= fault_date)))
);


ALTER TABLE public.repair_log OWNER TO postgres;

--
-- Name: repair_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.repair_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.repair_log_id_seq OWNER TO postgres;

--
-- Name: repair_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.repair_log_id_seq OWNED BY public.repair_log.id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rooms (
    id integer NOT NULL,
    number character varying(20) NOT NULL,
    building character varying(50),
    responsible_person character varying(100)
);


ALTER TABLE public.rooms OWNER TO postgres;

--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rooms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rooms_id_seq OWNER TO postgres;

--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rooms_id_seq OWNED BY public.rooms.id;


--
-- Name: v_equipment_full; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_equipment_full AS
 SELECT e.id,
    e.inventory_number,
    e.name AS equipment_name,
    e.model,
    t.name AS type_name,
    r.number AS room_number,
    r.building,
    s.name AS status_name,
    e.purchase_date,
    e.price
   FROM (((public.equipment e
     LEFT JOIN public.equipment_types t ON ((t.id = e.type_id)))
     LEFT JOIN public.rooms r ON ((r.id = e.room_id)))
     LEFT JOIN public.equipment_status s ON ((s.id = e.status_id)));


ALTER VIEW public.v_equipment_full OWNER TO postgres;

--
-- Name: v_public_rooms; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_public_rooms AS
 SELECT id,
    number,
    building
   FROM public.rooms;


ALTER VIEW public.v_public_rooms OWNER TO postgres;

--
-- Name: equipment id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment ALTER COLUMN id SET DEFAULT nextval('public.equipment_id_seq'::regclass);


--
-- Name: equipment_status id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_status ALTER COLUMN id SET DEFAULT nextval('public.equipment_status_id_seq'::regclass);


--
-- Name: equipment_types id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_types ALTER COLUMN id SET DEFAULT nextval('public.equipment_types_id_seq'::regclass);


--
-- Name: repair_log id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repair_log ALTER COLUMN id SET DEFAULT nextval('public.repair_log_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rooms ALTER COLUMN id SET DEFAULT nextval('public.rooms_id_seq'::regclass);


--
-- Data for Name: equipment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment (id, inventory_number, name, model, type_id, room_id, status_id, purchase_date, price) FROM stdin;
1	INV-011	Телевизор	LG 43UM7450	5	1	1	2023-05-10	35000.00
2	INV-012	Компьютер	HP EliteDesk 800	1	2	2	2020-08-22	61000.00
3	INV-013	Принтер	Kyocera ECOSYS P2040	3	3	1	2022-11-15	24000.00
4	INV-014	МФУ	Xerox WorkCentre 3025	4	4	3	2021-06-30	29000.00
5	INV-015	Проектор	ViewSonic PA503S	2	5	1	2023-09-01	42000.00
11	INV-001	Компьютер	Dell OptiPlex 7090	1	1	1	2022-09-01	65000.00
12	INV-002	Компьютер	HP ProDesk 400	1	1	2	2021-03-15	52000.00
13	INV-003	Проектор	Epson EB-X51	2	1	1	2023-01-20	48000.00
14	INV-004	Принтер	HP LaserJet 1102	3	2	3	2020-11-10	18500.00
15	INV-005	МФУ	Canon i-SENSYS MF3010	4	2	1	2022-06-05	27000.00
16	INV-006	Телевизор	Samsung UE55	5	3	1	2023-08-12	120000.00
17	INV-007	Компьютер	Lenovo ThinkCentre M70q	1	3	4	2018-04-25	43000.00
18	INV-008	Принтер	Brother HL-L2300DR	3	3	2	2021-09-30	21000.00
19	INV-009	Проектор	BenQ MS527	2	2	1	2022-12-01	39000.00
20	INV-010	Компьютер	Acer Veriton X2660G	1	1	1	2023-02-14	57000.00
\.


--
-- Data for Name: equipment_status; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment_status (id, name) FROM stdin;
1	Работает
2	Неисправно
3	В ремонте
4	Списано
\.


--
-- Data for Name: equipment_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.equipment_types (id, name) FROM stdin;
1	ПК
2	Проектор
3	Принтер
4	МФУ
5	Телевизор
\.


--
-- Data for Name: repair_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.repair_log (id, equipment_id, fault_date, description, repair_date, is_fixed) FROM stdin;
1	2	2025-09-25	Сбой ОС, переустановка	2025-09-27	t
2	11	2025-01-15	Не работает мышь, замена	2025-01-16	t
3	12	2025-09-10	Шум вентилятора, перегрев	\N	f
4	12	2025-02-10	Не включается, проблема с блоком питания	2025-02-14	t
5	13	2025-04-20	Перегорела лампа проектора	\N	f
6	14	2025-03-05	Замятие бумаги, износ ролика подачи	\N	f
7	15	2025-05-12	Замятие бумаги	2025-05-13	t
8	16	2025-06-01	Нет изображения на экране	\N	f
9	17	2024-12-18	Не запускается ОС, требуется замена диска	2024-12-22	t
10	18	2025-04-01	Не печатает, ошибка тонера	\N	f
11	19	2025-07-08	Шум при работе вентилятора	2025-07-10	t
12	20	2025-08-19	Не включается	\N	f
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.rooms (id, number, building, responsible_person) FROM stdin;
4	213	ГК	Гегин Александр Сергеевич
5	101	ГК	\N
6	102	ГК	\N
7	201	ГК	\N
8	202	Общага	\N
9	305	ГК	\N
10	306	ГК	\N
11	310	Общага	\N
12	311	Общага	\N
1	109	ГК	Гегин Александр Сергеевич
2	316	ГК	Горбунов Александр Григорьевич
3	308	Общага	Гегин Александр Сергеевич
15	307	Общага	Горбунов Александр Григорьевич
\.


--
-- Name: equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_id_seq', 20, true);


--
-- Name: equipment_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_status_id_seq', 5, true);


--
-- Name: equipment_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.equipment_types_id_seq', 5, true);


--
-- Name: repair_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.repair_log_id_seq', 14, true);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.rooms_id_seq', 24, true);


--
-- Name: equipment equipment_inventory_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_inventory_number_key UNIQUE (inventory_number);


--
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (id);


--
-- Name: equipment_status equipment_status_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_status
    ADD CONSTRAINT equipment_status_name_key UNIQUE (name);


--
-- Name: equipment_status equipment_status_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_status
    ADD CONSTRAINT equipment_status_pkey PRIMARY KEY (id);


--
-- Name: equipment_types equipment_types_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_types
    ADD CONSTRAINT equipment_types_name_key UNIQUE (name);


--
-- Name: equipment_types equipment_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment_types
    ADD CONSTRAINT equipment_types_pkey PRIMARY KEY (id);


--
-- Name: repair_log repair_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repair_log
    ADD CONSTRAINT repair_log_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_number_building_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_number_building_key UNIQUE (number, building);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: idx_equipment_room; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_equipment_room ON public.equipment USING btree (room_id);


--
-- Name: idx_equipment_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_equipment_status ON public.equipment USING btree (status_id);


--
-- Name: idx_repair_equipment_fixed; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_repair_equipment_fixed ON public.repair_log USING btree (equipment_id, is_fixed);


--
-- Name: idx_repair_fault_date; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_repair_fault_date ON public.repair_log USING btree (fault_date);


--
-- Name: repair_log trg_repair_log_check; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_repair_log_check BEFORE INSERT OR UPDATE ON public.repair_log FOR EACH ROW EXECUTE FUNCTION public.trg_check_repair_date();


--
-- Name: equipment equipment_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: equipment equipment_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.equipment_status(id);


--
-- Name: equipment equipment_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.equipment_types(id);


--
-- Name: repair_log repair_log_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.repair_log
    ADD CONSTRAINT repair_log_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id);


--
-- Name: TABLE equipment; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.equipment TO admin_db;
GRANT SELECT,INSERT,UPDATE ON TABLE public.equipment TO manager_db;


--
-- Name: SEQUENCE equipment_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.equipment_id_seq TO admin_db;
GRANT SELECT,USAGE ON SEQUENCE public.equipment_id_seq TO manager_db;


--
-- Name: TABLE equipment_status; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.equipment_status TO admin_db;
GRANT SELECT ON TABLE public.equipment_status TO manager_db;


--
-- Name: SEQUENCE equipment_status_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.equipment_status_id_seq TO admin_db;
GRANT SELECT,USAGE ON SEQUENCE public.equipment_status_id_seq TO manager_db;


--
-- Name: TABLE equipment_types; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.equipment_types TO admin_db;
GRANT SELECT ON TABLE public.equipment_types TO manager_db;


--
-- Name: SEQUENCE equipment_types_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.equipment_types_id_seq TO admin_db;
GRANT SELECT,USAGE ON SEQUENCE public.equipment_types_id_seq TO manager_db;


--
-- Name: TABLE repair_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.repair_log TO admin_db;
GRANT SELECT,INSERT,UPDATE ON TABLE public.repair_log TO manager_db;


--
-- Name: SEQUENCE repair_log_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.repair_log_id_seq TO admin_db;
GRANT SELECT,USAGE ON SEQUENCE public.repair_log_id_seq TO manager_db;


--
-- Name: TABLE rooms; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.rooms TO admin_db;
GRANT SELECT,INSERT,UPDATE ON TABLE public.rooms TO manager_db;


--
-- Name: SEQUENCE rooms_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.rooms_id_seq TO admin_db;
GRANT SELECT,USAGE ON SEQUENCE public.rooms_id_seq TO manager_db;


--
-- Name: TABLE v_equipment_full; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_equipment_full TO admin_db;
GRANT SELECT ON TABLE public.v_equipment_full TO viewer_db;


--
-- Name: TABLE v_public_rooms; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.v_public_rooms TO admin_db;
GRANT SELECT ON TABLE public.v_public_rooms TO viewer_db;


--
-- PostgreSQL database dump complete
--

\unrestrict KFbcte2KmtQ1jDiJiwbbYQ2XL1gFsJAW0OniAjmw70WJemk0710hfaF0NLqhbEi

