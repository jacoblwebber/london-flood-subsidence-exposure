-- Validate BGS shrink-swell data clipped to London

SELECT
    COUNT(*) AS feature_count,
    COUNT(*) FILTER (WHERE geom IS NULL) AS missing_geometry,
    COUNT(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalid_geometry,
    MIN(ST_SRID(geom)) AS minimum_srid,
    MAX(ST_SRID(geom)) AS maximum_srid
FROM staging.bgs_shrink_swell_london;

SELECT
    class,
    legend,
    COUNT(*) AS hexagon_count
FROM staging.bgs_shrink_swell_london
GROUP BY class, legend
ORDER BY class, legend;