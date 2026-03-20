-- Database: global_development_tracker

-- DROP DATABASE IF EXISTS global_development_tracker;

-- CREATE DATABASE global_development_tracker
--     WITH
--     OWNER = postgres
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'English_United States.1252'
--     LC_CTYPE = 'English_United States.1252'
--     LOCALE_PROVIDER = 'libc'
--     TABLESPACE = pg_default
--     CONNECTION LIMIT = -1
--     IS_TEMPLATE = False;

CREATE SCHEMA staging;
CREATE SCHEMA production;

SELECT schema_name FROM information_schema.schemata;

DROP TABLE IF EXISTS staging.co2;
CREATE TABLE staging.co2(
	country TEXT,
	year TEXT,
	iso_code TEXT,
	population TEXT,
	co2 TEXT,
	co2_per_capita TEXT
);

DROP TABLE IF EXISTS staging.life_expectancy;
CREATE TABLE staging.life_expectancy(
	entity TEXT,
	code TEXT,
	year TEXT,
	life_expectancy TEXT
);

DROP TABLE IF EXISTS staging.gdp_per_capita;
CREATE TABLE staging.gdp_per_capita(
	country_name TEXT,
	country_code TEXT,
	year TEXT,
	value TEXT
);

DROP TABLE IF EXISTS staging.population;
CREATE TABLE staging.population(
	country_name TEXT,
	country_code TEXT,
	year TEXT,
	value TEXT
);

SELECT 'co2' AS tbl, COUNT(*) FROM staging.co2
UNION ALL
SELECT 'life_expectancy', COUNT(*) FROM staging.life_expectancy
UNION ALL
SELECT 'gdp_per_capita', COUNT(*) FROM staging.gdp_per_capita
UNION ALL
SELECT 'population', COUNT(*) FROM staging.population;

-- Check for non country entities
SELECT DISTINCT country
FROM staging.co2
WHERE iso_code IS NULL
ORDER BY country;

-- check year ranges
SELECT 'co2' as tbl, MIN(year), MAX(year) FROM staging.co2
UNION ALL
SELECT 'life_exp' as tbl, MIN(year), MAX(year) FROM staging.life_expectancy
UNION ALL
SELECT 'gdp_per_capita' as tbl, MIN(year), MAX(year) FROM staging.gdp_per_capita
UNION ALL
SELECT 'population' as tbl, MIN(year), MAX(year) FROM staging.population;

-- Check how many different counteries per source
SELECT 'co2' AS tbl, COUNT(DISTINCT country) FROM staging.co2 WHERE iso_code IS NOT NULL
UNION ALL
SELECT 'life_exp', COUNT(DISTINCT entity) FROM staging.life_expectancy WHERE code IS NOT NULL
UNION ALL
SELECT 'gdp', COUNT(DISTINCT country_name) FROM staging.gdp_per_capita
UNION ALL
SELECT 'pop', COUNT(DISTINCT country_name) FROM staging.population;


-- 1. Clean CO2: filter out non-countries, restrict to 1990-2023, cast types
DROP TABLE IF EXISTS staging.co2_cleaned ;
CREATE TABLE staging.co2_cleaned AS
SELECT 
	country,
	year:: INTEGER AS year,
	iso_code,
	population::NUMERIC AS population,
	co2::NUMERIC AS co2,
	co2_per_capita::NUMERIC as co2_per_capita
FROM staging.co2
WHERE iso_code IS NOT NULL
	AND year::INTEGER BETWEEN 1990 AND 2023;

-- 2. Clean Life Expectancy: filter non-countries, restrict years
CREATE TABLE staging.life_expectancy_cleaned AS
SELECT
    entity AS country,
    code AS iso_code,
    year::INTEGER AS year,
    life_expectancy::NUMERIC AS life_expectancy
FROM staging.life_expectancy
WHERE code IS NOT NULL
  AND year::INTEGER BETWEEN 1990 AND 2023;


-- 3. Clean GDP: remove World Bank regional aggregates, restrict years
-- World Bank uses specific codes for aggregates (they don't follow 3-letter ISO country codes)
CREATE TABLE staging.gdp_cleaned AS
SELECT
    country_name AS country,
    country_code AS iso_code,
    year::INTEGER AS year,
    value::NUMERIC AS gdp_per_capita
FROM staging.gdp_per_capita
WHERE year::INTEGER BETWEEN 1990 AND 2023
  AND value IS NOT NULL
  AND country_code NOT IN (
      'AFE','AFW','ARB','CEB','CSS','EAP','EAR','EAS','ECA','ECS',
      'EMU','EUU','FCS','HIC','HPC','IBD','IBT','IDA','IDB','IDX',
      'INX','LAC','LCN','LDC','LIC','LMC','LMY','LTE','MEA','MIC',
      'MNA','NAC','OED','OSS','PRE','PSS','PST','SAS','SSA','SSF',
      'SST','TEA','TEC','TLA','TMN','TSA','TSS','UMC','WLD'
  );

-- 4. Clean Population: same filter logic as GDP
CREATE TABLE staging.population_cleaned AS
SELECT
    country_name AS country,
    country_code AS iso_code,
    year::INTEGER AS year,
    value::NUMERIC AS population
FROM staging.population
WHERE year::INTEGER BETWEEN 1990 AND 2023
  AND value IS NOT NULL
  AND country_code NOT IN (
      'AFE','AFW','ARB','CEB','CSS','EAP','EAR','EAS','ECA','ECS',
      'EMU','EUU','FCS','HIC','HPC','IBD','IBT','IDA','IDB','IDX',
      'INX','LAC','LCN','LDC','LIC','LMC','LMY','LTE','MEA','MIC',
      'MNA','NAC','OED','OSS','PRE','PSS','PST','SAS','SSA','SSF',
      'SST','TEA','TEC','TLA','TMN','TSA','TSS','UMC','WLD'
  );


SELECT 'co2' AS tbl, COUNT(*) AS rows, COUNT(DISTINCT country) AS countries FROM staging.co2_cleaned
UNION ALL
SELECT 'life_exp', COUNT(*), COUNT(DISTINCT country) FROM staging.life_expectancy_cleaned
UNION ALL
SELECT 'gdp', COUNT(*), COUNT(DISTINCT country) FROM staging.gdp_cleaned
UNION ALL
SELECT 'pop', COUNT(*), COUNT(DISTINCT country) FROM staging.population_cleaned;


CREATE TABLE staging.target_countries(
	country_name TEXT,
	iso_code TEXT
);
INSERT INTO staging.target_countries(country_name, iso_code) VALUES
('United States', 'USA'),
('Germany', 'DEU'),
('Japan', 'JPN'),
('United Kingdom', 'GBR'),
('Australia', 'AUS'),
('Canada', 'CAN'),
('South Korea', 'KOR'),
('China', 'CHN'),
('Brazil', 'BRA'),
('Mexico', 'MEX'),
('Turkey', 'TUR'),
('South Africa', 'ZAF'),
('India', 'IND'),
('Indonesia', 'IDN'),
('Nigeria', 'NGA'),
('Egypt', 'EGY'),
('Vietnam', 'VNM'),
('Bangladesh', 'BGD'),
('Ethiopia', 'ETH'),
('Mozambique', 'MOZ'),
('Chad', 'TCD');


SELECT t.iso_code, t.country_name,
	CASE WHEN c.iso_code IS NOT NULL THEN 'YES' ELSE 'MISSING' END AS in_co2,
	CASE WHEN g.iso_code IS NOT NULL THEN 'YES' ELSE 'MISSING' END AS in_gdp,
	CASE WHEN l.iso_code IS NOT NULL THEN 'YES' ELSE 'MISSING' END AS in_life,
	CASE WHEN p.iso_code IS NOT NULL THEN 'YES' ELSE 'MISSING' END AS in_pop
FROM staging.target_countries t
LEFT JOIN (SELECT DISTINCT iso_code FROM staging.co2_cleaned) c ON t.iso_code = c.iso_code
LEFT JOIN (SELECT DISTINCT iso_code FROM staging.gdp_cleaned) g ON t.iso_code = g.iso_code
LEFT JOIN (SELECT DISTINCT iso_code FROM staging.life_expectancy_cleaned) l ON t.iso_code = l.iso_code
LEFT JOIN (SELECT DISTINCT iso_code FROM staging.population_cleaned) p ON t.iso_code = p.iso_code;




-- Creating production ready table

CREATE TABLE production.global_development AS 
SELECT 
	t.country_name,
	t.iso_code,
	c.year,
	g.gdp_per_capita,
	p.population,
	c.co2,
	c.co2_per_capita,
	l.life_expectancy
FROM staging.target_countries t
CROSS JOIN generate_series(1990, 2023) AS year_series(year)
LEFT JOIN staging.co2_cleaned c 
    ON t.iso_code = c.iso_code AND year_series.year = c.year
LEFT JOIN staging.gdp_cleaned g 
    ON t.iso_code = g.iso_code AND year_series.year = g.year
LEFT JOIN staging.life_expectancy_cleaned l 
    ON t.iso_code = l.iso_code AND year_series.year = l.year
LEFT JOIN staging.population_cleaned p 
    ON t.iso_code = p.iso_code AND year_series.year = p.year
ORDER BY t.country_name, year_series.year;

--Verify
SELECT COUNT(DISTINCT country_name) AS countries, COUNT(DISTINCT year) AS years FROM production.global_development;

-- Number of not null columns
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(gdp_per_capita) / COUNT(*), 1) AS gdp_pct,
    ROUND(100.0 * COUNT(population) / COUNT(*), 1) AS pop_pct,
    ROUND(100.0 * COUNT(co2) / COUNT(*), 1) AS co2_pct,
    ROUND(100.0 * COUNT(co2_per_capita) / COUNT(*), 1) AS co2pc_pct,
    ROUND(100.0 * COUNT(life_expectancy) / COUNT(*), 1) AS life_pct
FROM production.global_development;

SELECT * FROM production.global_development
WHERE country_name = 'India'
ORDER BY year;

--Inspecting the missing value in gdp table
SELECT country_name, year from production.global_development where gdp_per_capita is NULL;

--GDP growth over time (top 5 fastest growing):
SELECT country_name,
	ROUND(MIN(CASE WHEN year=1990 THEN gdp_per_capita END)::NUMERIC, 2) AS gdp_1990,
	ROUND(min(CASE WHEN year=2023 THEN gdp_per_capita END)::NUMERIC, 2) AS gdp_2023,
	ROUND(((MIN(CASE WHEN year=2023 THEN gdp_per_capita END)-
		  MIN(CASE WHEN year=1990 THEN gdp_per_capita END)) /
		  NULLIF(MIN(CASE WHEN year=1990 THEN gdp_per_capita END),0) * 100)::NUMERIC, 1) AS growth_pct
FROM production.global_development
GROUP BY country_name
ORDER BY growth_pct DESC
LIMIT 5;


-- co2 Vs GDP relationship
SELECT country_name,
	ROUND(AVG(gdp_per_capita)::NUMERIC, 2) AS avg_gdp,
	ROUND(AVG(co2_per_capita)::NUMERIC, 2) AS avg_co2_per_capita,
	ROUND(AVG(life_expectancy)::NUMERIC, 1) AS avg_life_exp
FROM production.global_development
GROUP BY country_name
order by avg_gdp DESC;

-- Life expectancy improvement
SELECT country_name,
	ROUND(MIN(CASE WHEN year = 1990 THEN life_expectancy END)::NUMERIC, 1) AS life_1990,
	ROUND(MIN(CASE WHEN year = 2023 THEN life_expectancy END)::NUMERIC, 1) AS life_2023,
	ROUND((
		((MIN(CASE WHEN year = 2023 THEN life_expectancy END)) - 
		(MIN(CASE WHEN year = 1990 THEN life_expectancy END))) /
		NULLIF(MIN(CASE WHEN year = 1990 THEN life_expectancy END), 0) * 100 )::NUMERIC, 1) AS life_expectancy_change
FROM production.global_development
GROUP BY country_name
order by life_2023 DESC;

-- Biggest CO2 emitters over time
SELECT country_name, 
    -- ROUND(co2::NUMERIC, 2) AS co2_total,
	ROUND(MIN(CASE WHEN year=1990 THEN co2 END)::NUMERIC, 2) as co2_1990,
	ROUND(MIN(CASE WHEN year=2000 THEN co2 END)::NUMERIC, 2) as co2_2000,
	ROUND(MIN(CASE WHEN year=2010 THEN co2 END)::NUMERIC, 2) as co2_2010,
	ROUND(MIN(CASE WHEN year=2023 THEN co2 END)::NUMERIC, 2) as co2_2023
FROM production.global_development
GROUP BY country_name
ORDER BY co2_2023 DESC;

COPY production.global_development 
TO 'F:/Indiana University Bloomington/Projects/Project-21 Global Development and Climate Tracker/global_development_final.csv'
WITH (FORMAT CSV, HEADER);

--Create the Data Dictionary:
CREATE TABLE production.data_dictionary(
	column_name TEXT,
	data_type TEXT,
	unit TEXT,
	source TEXT,
	description TEXT
);
INSERT INTO production.data_dictionary VALUES
('country_name', 'TEXT', 'N/A', 'Internal mapping', 'Standardized country name'),
('iso_code', 'TEXT', 'N/A', 'ISO 3166-1 alpha-3', 'Three-letter country code used as primary join key'),
('year', 'INTEGER', 'Year', 'All sources', 'Calendar year (1990-2023)'),
('gdp_per_capita', 'NUMERIC', 'Current US$', 'World Bank', 'GDP per capita in current US dollars'),
('population', 'NUMERIC', 'Persons', 'World Bank', 'Total population count'),
('co2', 'NUMERIC', 'Million tonnes', 'Our World in Data', 'Annual total CO2 emissions'),
('co2_per_capita', 'NUMERIC', 'Tonnes per person', 'Our World in Data', 'Annual CO2 emissions per capita'),
('life_expectancy', 'NUMERIC', 'Years', 'Our World in Data', 'Life expectancy at birth');

--  Create the Methodology Log
CREATE TABLE production.methodology_log (
    step_number INTEGER,
    category TEXT,
    description TEXT
);

INSERT INTO production.methodology_log VALUES
(1, 'Timeline', 'Restricted to 1990-2023. Pre-1990 excluded due to sparse World Bank data and Soviet dissolution entity changes.'),
(2, 'Country Selection', '21 target countries selected across income levels and geographies for policy analysis.'),
(3, 'Join Strategy', 'Used ISO codes as primary join key instead of country names to avoid name mismatch issues.'),
(4, 'Spine Approach', 'CROSS JOIN with generate_series created guaranteed rows for every country-year combination (21 × 34 = 714 rows).'),
(5, 'Join Type', 'LEFT JOIN used for all four datasets to preserve rows even when one metric is missing.'),
(6, 'Non-Country Filtering', 'Removed regional aggregates from OWID (iso_code IS NULL) and World Bank (excluded 49 aggregate codes like WLD, HIC, etc).'),
(7, 'Data Types', 'All staging tables loaded as TEXT, then cast to NUMERIC/INTEGER during cleaning to catch conversion errors.'),
(8, 'Missing Data', 'One NULL identified: Mozambique GDP 1990 (civil war period). Left as NULL, not interpolated.'),
(9, 'No Extrapolation', 'No values were invented or interpolated. All NULLs represent genuinely missing source data.');

SELECT * FROM production.data_dictionary;
SELECT * FROM production.methodology_log ORDER BY step_number;

---------------------------------------------
--------FINAL DELIVERABLE
---------------------------------------------

-- Economic divergence
SELECT country_name,
    ROUND(MIN(CASE WHEN year = 1990 THEN gdp_per_capita END)::NUMERIC, 0) AS gdp_1990,
    ROUND(MIN(CASE WHEN year = 2023 THEN gdp_per_capita END)::NUMERIC, 0) AS gdp_2023,
    ROUND(((MIN(CASE WHEN year = 2023 THEN gdp_per_capita END) - 
            MIN(CASE WHEN year = 1990 THEN gdp_per_capita END)) / 
            NULLIF(MIN(CASE WHEN year = 1990 THEN gdp_per_capita END), 0) * 100)::NUMERIC, 1) AS growth_pct
FROM production.global_development
GROUP BY country_name
ORDER BY growth_pct DESC;


-- CO2 and prosperity correlation
SELECT country_name,
    ROUND(AVG(gdp_per_capita)::NUMERIC, 0) AS avg_gdp,
    ROUND(AVG(co2_per_capita)::NUMERIC, 2) AS avg_co2_pc
FROM production.global_development
GROUP BY country_name
ORDER BY avg_gdp DESC;

-- Life expectancy gains
SELECT country_name,
    ROUND(MIN(CASE WHEN year = 1990 THEN life_expectancy END)::NUMERIC, 1) AS life_1990,
    ROUND(MIN(CASE WHEN year = 2023 THEN life_expectancy END)::NUMERIC, 1) AS life_2023,
    ROUND((MIN(CASE WHEN year = 2023 THEN life_expectancy END) - 
           MIN(CASE WHEN year = 1990 THEN life_expectancy END))::NUMERIC, 1) AS improvement
FROM production.global_development
GROUP BY country_name
ORDER BY improvement DESC;

-- China's emissions overtake
SELECT country_name, year, ROUND(co2::NUMERIC, 2) AS co2
FROM production.global_development
WHERE country_name IN ('China', 'United States')
  AND year IN (1990, 2000, 2010, 2023)
ORDER BY year, co2 DESC;