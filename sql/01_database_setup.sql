CREATE EXTENSION IF NOT EXISTS postgis;

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS analytics;

COMMENT ON SCHEMA raw IS 'Original source datasets';
COMMENT ON SCHEMA staging IS 'Data being cleaned and transformed';
COMMENT ON SCHEMA core IS 'Clean, analysis-ready spatial data';
COMMENT ON SCHEMA analytics IS 'Exposure results and summary views';