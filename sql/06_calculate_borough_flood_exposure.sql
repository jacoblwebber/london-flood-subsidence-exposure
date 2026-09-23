-- Calculate flood-zone exposure for each London borough

DROP TABLE IF EXISTS analytics.borough_flood_exposure;

CREATE TABLE analytics.borough_flood_exposure AS
WITH flood_dissolved AS (
    -- Merge neighbouring polygons to prevent double-counting
    SELECT
        flood_zone,
        ST_UnaryUnion(ST_Collect(geom)) AS geom
    FROM core.flood_zones_london
    GROUP BY flood_zone
),

borough_zone_areas AS (
    -- Cut each flood zone by each borough boundary
    SELECT
        b.borough_id,
        f.flood_zone,
        ST_Area(ST_Intersection(b.geom, f.geom))
            / 1000000.0 AS area_km2
    FROM core.london_boroughs AS b
    JOIN flood_dissolved AS f
      ON ST_Intersects(b.geom, f.geom)
),

flood_totals AS (
    -- Turn the two flood-zone categories into separate columns
    SELECT
        borough_id,
        SUM(area_km2) FILTER (
            WHERE flood_zone = 'FZ2'
        ) AS fz2_area_km2,
        SUM(area_km2) FILTER (
            WHERE flood_zone = 'FZ3'
        ) AS fz3_area_km2
    FROM borough_zone_areas
    GROUP BY borough_id
)

SELECT
    b.borough_id,
    b.gss_code,
    b.borough_name,

    ROUND(
        (ST_Area(b.geom) / 1000000.0)::numeric,
        2
    ) AS borough_area_km2,

    ROUND(
        COALESCE(f.fz2_area_km2, 0)::numeric,
        2
    ) AS fz2_area_km2,

    ROUND(
        COALESCE(f.fz3_area_km2, 0)::numeric,
        2
    ) AS fz3_area_km2,

    ROUND((
        100.0 * COALESCE(f.fz2_area_km2, 0)
        / NULLIF(ST_Area(b.geom) / 1000000.0, 0)
    )::numeric, 2) AS fz2_percent,

    ROUND((
        100.0 * COALESCE(f.fz3_area_km2, 0)
        / NULLIF(ST_Area(b.geom) / 1000000.0, 0)
    )::numeric, 2) AS fz3_percent,

    b.geom

FROM core.london_boroughs AS b
LEFT JOIN flood_totals AS f
  ON b.borough_id = f.borough_id;


ALTER TABLE analytics.borough_flood_exposure
    ADD PRIMARY KEY (borough_id);

CREATE INDEX borough_flood_exposure_geom_idx
    ON analytics.borough_flood_exposure
    USING GIST (geom);


-- Display the ten boroughs with the greatest Flood Zone 3 percentage

SELECT
    borough_name,
    borough_area_km2,
    fz2_area_km2,
    fz3_area_km2,
    fz2_percent,
    fz3_percent
FROM analytics.borough_flood_exposure
ORDER BY fz3_percent DESC
LIMIT 10;