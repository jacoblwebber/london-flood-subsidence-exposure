-- Calculate shrink-swell susceptibility for each London borough

DROP TABLE IF EXISTS analytics.borough_shrink_swell_exposure;

CREATE TABLE analytics.borough_shrink_swell_exposure AS
WITH susceptibility_dissolved AS (
    -- Combine the hexagons into three susceptibility classes
    SELECT
        susceptibility_class,
        susceptibility_label,
        ST_UnaryUnion(ST_Collect(geom)) AS geom
    FROM core.shrink_swell_london
    GROUP BY susceptibility_class, susceptibility_label
),

borough_class_areas AS (
    -- Cut each susceptibility class by each borough boundary
    SELECT
        b.borough_id,
        s.susceptibility_class,
        ST_Area(ST_Intersection(b.geom, s.geom))
            / 1000000.0 AS area_km2
    FROM core.london_boroughs AS b
    JOIN susceptibility_dissolved AS s
      ON ST_Intersects(b.geom, s.geom)
),

risk_totals AS (
    -- Turn the three classes into separate columns
    SELECT
        borough_id,
        SUM(area_km2) FILTER (
            WHERE susceptibility_class = 1
        ) AS low_area_km2,
        SUM(area_km2) FILTER (
            WHERE susceptibility_class = 2
        ) AS moderate_area_km2,
        SUM(area_km2) FILTER (
            WHERE susceptibility_class = 3
        ) AS significant_area_km2
    FROM borough_class_areas
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

    ROUND(COALESCE(r.low_area_km2, 0)::numeric, 2)
        AS low_area_km2,

    ROUND(COALESCE(r.moderate_area_km2, 0)::numeric, 2)
        AS moderate_area_km2,

    ROUND(COALESCE(r.significant_area_km2, 0)::numeric, 2)
        AS significant_area_km2,

    ROUND((
        100.0 * COALESCE(r.low_area_km2, 0)
        / NULLIF(ST_Area(b.geom) / 1000000.0, 0)
    )::numeric, 2) AS low_percent,

    ROUND((
        100.0 * COALESCE(r.moderate_area_km2, 0)
        / NULLIF(ST_Area(b.geom) / 1000000.0, 0)
    )::numeric, 2) AS moderate_percent,

    ROUND((
        100.0 * COALESCE(r.significant_area_km2, 0)
        / NULLIF(ST_Area(b.geom) / 1000000.0, 0)
    )::numeric, 2) AS significant_percent,

    ROUND((
        100.0 * (
            COALESCE(r.low_area_km2, 0)
            + COALESCE(r.moderate_area_km2, 0)
            + COALESCE(r.significant_area_km2, 0)
        )
        / NULLIF(ST_Area(b.geom) / 1000000.0, 0)
    )::numeric, 2) AS bgs_coverage_percent,

    CASE
        WHEN COALESCE(r.low_area_km2, 0)
           + COALESCE(r.moderate_area_km2, 0)
           + COALESCE(r.significant_area_km2, 0) = 0
            THEN 'No data'
        WHEN COALESCE(r.significant_area_km2, 0) >= GREATEST(
            COALESCE(r.moderate_area_km2, 0),
            COALESCE(r.low_area_km2, 0)
        )
            THEN 'Significant'
        WHEN COALESCE(r.moderate_area_km2, 0)
             >= COALESCE(r.low_area_km2, 0)
            THEN 'Moderate'
        ELSE 'Low'
    END AS dominant_susceptibility,

    b.geom

FROM core.london_boroughs AS b
LEFT JOIN risk_totals AS r
  ON b.borough_id = r.borough_id;


ALTER TABLE analytics.borough_shrink_swell_exposure
    ADD PRIMARY KEY (borough_id);

CREATE INDEX borough_shrink_swell_exposure_geom_idx
    ON analytics.borough_shrink_swell_exposure
    USING GIST (geom);


-- Display boroughs with the greatest significant susceptibility

SELECT
    borough_name,
    low_percent,
    moderate_percent,
    significant_percent,
    bgs_coverage_percent,
    dominant_susceptibility
FROM analytics.borough_shrink_swell_exposure
ORDER BY significant_percent DESC
LIMIT 10;