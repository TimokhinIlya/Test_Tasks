
CREATE SCHEMA IF NOT EXISTS dbo;                        -- Создаем схему, если её ещё нет


CREATE TABLE IF NOT EXISTS dbo.countries (              -- Создаем таблицу, если её ещё нет
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,    -- Уникальный идентификатор записи, автоинкрементируемый
    country_name TEXT NOT NULL UNIQUE,                  -- Наименование страны, с ограничением уникальности, не может быть NULL, 
    capital TEXT NOT NULL,                              -- Наименование столицы, не может быть NULL
    population BIGINT CHECK (population > 0),           -- Население страны, должно быть больше 0
    created_at TIMESTAMP DEFAULT NOW()                  -- Дата создания - по умолчанию текущая дата и время
);


-- Функция для добавления новой страны в таблицу "countries"
-- Принимает параметры: country_name - наименование страны, capital - столица, population - население
-- Не возвращает никакого значения (void)
CREATE OR REPLACE FUNCTION dbo.add_country(
    v_country_name TEXT,
    v_capital TEXT,
    v_population BIGINT
) 
RETURNS void AS
$$
BEGIN
    -- Вставка данных в таблицу "countries"
    INSERT INTO dbo.countries (country_name, capital, population, created_at)
    VALUES (v_country_name, v_capital, v_population, NOW());
END;
$$
LANGUAGE plpgsql;


-- Функция для удаления страны из таблицы "countries" по её названию
-- Принимает параметры: country_name - название страны, которую нужно удалить
-- Не возвращает никакого значения (void)
CREATE OR REPLACE FUNCTION dbo.delete_country_name(
    v_country_name TEXT
RETURNS void AS
$$
BEGIN
    -- Удаление записи из таблицы "countries" по указанному идентификатору
    DELETE FROM dbo.countries WHERE country_name = v_country_name;
END;
$$
LANGUAGE plpgsql;


-- Добавление данных в таблицу "countries" с помощью функции add_country
SELECT dbo.add_country('Russia', 'Moscow', 146447424);


-- Удаление данных из таблицы "countries" по идентификатору с помощью функции delete_country_by_id
SELECT dbo.delete_country_by_id('Russia');


-- Функция для приведения текстовых данных в любой таблице к верхнему или нижнему регистру
CREATE OR REPLACE FUNCTION dbo.change_case(
    table_name TEXT,
    column_name TEXT,
    case_type VARCHAR(5) -- Тип регистра: 'upper' или 'lower'
) 
RETURNS void AS
$$
DECLARE
    sql_query TEXT;
BEGIN
    -- Проверяем тип регистра и строим SQL-запрос для обновления данных в столбце column_name таблицы table_name
    IF case_type = 'upper' THEN
        sql_query := 'UPDATE ' || table_name || ' SET ' || column_name || ' = UPPER(' || column_name || ')';
    ELSIF case_type = 'lower' THEN
        sql_query := 'UPDATE ' || table_name || ' SET ' || column_name || ' = LOWER(' || column_name || ')';
    ELSE
        RAISE EXCEPTION 'Invalid case_type. Use ''upper'' or ''lower''.';
    END IF;
    -- Выполняем сформированный SQL-запрос
    EXECUTE sql_query;
END;
$$
LANGUAGE plpgsql;


-- Создаем представление для таблицы dbo.countries
CREATE OR REPLACE VIEW dbo.countries_view_filtered AS
SELECT * 
FROM dbo.countries
WHERE population < 100000000;


-- Создаем материализованное представление для таблицы dbo.countries
CREATE MATERIALIZED VIEW dbo.countries_materialized_avg_pop AS
SELECT capital, AVG(population) AS avg_population
FROM dbo.countries
GROUP BY capital
ORDER BY avg_population DESC



-- Выборка OID, наименования схем и наименования созданных объектов
SELECT n.oid AS schema_oid,
       n.nspname AS schema_name,
       c.oid AS object_oid,
       c.relname AS object_name
FROM pg_catalog.pg_namespace n
JOIN pg_catalog.pg_class c ON n.oid = c.relnamespace
WHERE n.nspname = 'dbo';


-- Выборка OID, наименование схем и наименование созданных функций
SELECT p.oid AS function_oid,
       p.proname AS function_name,
       n.nspname AS schema_name
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'dbo';