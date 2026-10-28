-- public.equipment_status definition

-- Drop table

-- DROP TABLE public.equipment_status;

CREATE TABLE public.equipment_status (
	id serial4 NOT NULL,
	"name" varchar(50) NOT NULL,
	CONSTRAINT equipment_status_id_not_null NOT NULL id,
	CONSTRAINT equipment_status_name_key UNIQUE (name),
	CONSTRAINT equipment_status_name_not_null NOT NULL name,
	CONSTRAINT equipment_status_pkey PRIMARY KEY (id)
);


-- public.equipment_types definition

-- Drop table

-- DROP TABLE public.equipment_types;

CREATE TABLE public.equipment_types (
	id serial4 NOT NULL,
	"name" varchar(50) NOT NULL,
	CONSTRAINT equipment_types_id_not_null NOT NULL id,
	CONSTRAINT equipment_types_name_key UNIQUE (name),
	CONSTRAINT equipment_types_name_not_null NOT NULL name,
	CONSTRAINT equipment_types_pkey PRIMARY KEY (id)
);


-- public.rooms definition

-- Drop table

-- DROP TABLE public.rooms;

CREATE TABLE public.rooms (
	id serial4 NOT NULL,
	"number" varchar(20) NOT NULL,
	building varchar(50) NULL,
	responsible_person varchar(100) NULL,
	CONSTRAINT rooms_id_not_null NOT NULL id,
	CONSTRAINT rooms_number_building_key UNIQUE (number, building),
	CONSTRAINT rooms_number_not_null NOT NULL number,
	CONSTRAINT rooms_pkey PRIMARY KEY (id)
);


-- public.equipment definition

-- Drop table

-- DROP TABLE public.equipment;

CREATE TABLE public.equipment (
	id serial4 NOT NULL,
	inventory_number varchar(50) NOT NULL,
	"name" varchar(100) NOT NULL,
	model varchar(100) NULL,
	type_id int4 NULL,
	room_id int4 NULL,
	status_id int4 NULL,
	purchase_date date NULL,
	price numeric(10, 2) NULL,
	CONSTRAINT equipment_id_not_null NOT NULL id,
	CONSTRAINT equipment_inventory_number_key UNIQUE (inventory_number),
	CONSTRAINT equipment_inventory_number_not_null NOT NULL inventory_number,
	CONSTRAINT equipment_name_not_null NOT NULL name,
	CONSTRAINT equipment_pkey PRIMARY KEY (id),
	CONSTRAINT equipment_price_check CHECK ((price >= (0)::numeric)),
	CONSTRAINT equipment_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id),
	CONSTRAINT equipment_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.equipment_status(id),
	CONSTRAINT equipment_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.equipment_types(id)
);
CREATE INDEX idx_equipment_room ON public.equipment USING btree (room_id);
CREATE INDEX idx_equipment_status ON public.equipment USING btree (status_id);


-- public.repair_log definition

-- Drop table

-- DROP TABLE public.repair_log;

CREATE TABLE public.repair_log (
	id serial4 NOT NULL,
	equipment_id int4 NOT NULL,
	fault_date date NOT NULL,
	description text NULL,
	repair_date date NULL,
	is_fixed bool DEFAULT false NULL,
	CONSTRAINT repair_log_check CHECK (((repair_date IS NULL) OR (repair_date >= fault_date))),
	CONSTRAINT repair_log_equipment_id_not_null NOT NULL equipment_id,
	CONSTRAINT repair_log_fault_date_not_null NOT NULL fault_date,
	CONSTRAINT repair_log_id_not_null NOT NULL id,
	CONSTRAINT repair_log_pkey PRIMARY KEY (id),
	CONSTRAINT repair_log_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(id)
);
CREATE INDEX idx_repair_equipment_fixed ON public.repair_log USING btree (equipment_id, is_fixed);
CREATE INDEX idx_repair_fault_date ON public.repair_log USING btree (fault_date);

-- Table Triggers

create trigger trg_repair_log_check before
insert
    or
update
    on
    public.repair_log for each row execute function trg_check_repair_date();