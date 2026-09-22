SELECT
    COUNT(*) AS borough_count,
    COUNT(*) FILTER (WHERE geom IS NULL) AS missing_geometry,
    COUNT(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalid_geometry,
    MIN(ST_SRID(geom)) AS srid
FROM raw.london_boroughs;