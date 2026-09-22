SELECT
    COUNT(*) AS feature_count,
    COUNT(*) FILTER (WHERE geom IS NULL) AS missing_geometry,
    COUNT(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalid_geometry,
    MIN(ST_SRID(geom)) AS minimum_srid,
    MAX(ST_SRID(geom)) AS maximum_srid
FROM staging.ea_flood_zones_london;

SELECT
    flood_zone,
    COUNT(*) AS feature_count
FROM staging.ea_flood_zones_london
GROUP BY flood_zone
ORDER BY flood_zone;