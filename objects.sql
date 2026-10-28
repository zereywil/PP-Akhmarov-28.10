-- ============================================================
-- Приложение Б. Скрипт создания объектов базы данных
-- База: college_equipment, СУБД: PostgreSQL 18
-- Безопасный вариант: можно выполнять повторно
-- ============================================================

-- 1. Представление: полная информация по оборудованию
CREATE OR REPLACE VIEW v_equipment_full AS
SELECT
    e.id,
    e.inventory_number,
    e.name AS equipment_name,
    e.model,
    t.name AS type_name,
    r.number AS room_number,
    r.building,
    s.name AS status_name,
    e.purchase_date,
    e.price
FROM equipment e
LEFT JOIN equipment_types t ON t.id = e.type_id
LEFT JOIN rooms r ON r.id = e.room_id
LEFT JOIN equipment_status s ON s.id = e.status_id;

-- 2. Представление: кабинеты без ФИО ответственных
CREATE OR REPLACE VIEW v_public_rooms AS
SELECT id, number, building FROM rooms;

-- 3. Функция: статистика неисправностей за период
CREATE OR REPLACE FUNCTION get_fault_stats(
    p_date_from DATE,
    p_date_to DATE
)
RETURNS TABLE (
    inventory_number VARCHAR,
    equipment_name VARCHAR,
    fault_count BIGINT,
    fixed_count BIGINT,
    open_count BIGINT
)
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

-- 4. Функция триггера: проверка даты ремонта
CREATE OR REPLACE FUNCTION trg_check_repair_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.is_fixed = TRUE AND NEW.repair_date IS NULL THEN
        RAISE EXCEPTION 'Нельзя закрыть ремонт без указания даты ремонта (repair_date)';
    END IF;
    RETURN NEW;
END;
$$;

-- 5. Триггер: запрет закрытия ремонта без даты
DROP TRIGGER IF EXISTS trg_repair_log_check ON repair_log;
CREATE TRIGGER trg_repair_log_check
BEFORE INSERT OR UPDATE ON repair_log
FOR EACH ROW
EXECUTE FUNCTION trg_check_repair_date();

-- 6. Роли и права доступа
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin_db') THEN
        CREATE ROLE admin_db LOGIN PASSWORD 'admin123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager_db') THEN
        CREATE ROLE manager_db LOGIN PASSWORD 'manager123';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'viewer_db') THEN
        CREATE ROLE viewer_db LOGIN PASSWORD 'viewer123';
    END IF;
END
$$;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_db;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin_db;

GRANT SELECT, INSERT, UPDATE ON equipment, repair_log, rooms TO manager_db;
GRANT SELECT ON equipment_status, equipment_types TO manager_db;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO manager_db;

GRANT SELECT ON v_public_rooms TO viewer_db;
GRANT SELECT ON v_equipment_full TO viewer_db;

GRANT CONNECT ON DATABASE college_equipment TO admin_db, manager_db, viewer_db;