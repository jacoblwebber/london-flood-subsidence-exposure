-- Combine borough flood and shrink-swell results

DROP TABLE IF EXISTS analytics.borough_hazard_summary;

CREATE TABLE analytics.borough_hazard_summary AS
SELECT
    f.borough_id,
    f.gss_code,
    f.borough_name,
    f.borough_area_km2,

    f.fz2_area_km2,
    f.fz3_area_km2,
    f.fz2_percent,
    f.fz3_percent,

    s.low_area_km2 AS shrink_low_area_km2,
    s.moderate_area_km2 AS shrink_moderate_area_km2,
    s.significant_area_km2 AS shrink_significant_area_km2,

    s.low_percent AS shrink_low_percent,
    s.moderate_percent AS shrink_moderate_percent,
    s.significant_percent AS shrink_significant_percent,
    s.bgs_coverage_percent,
    s.dominant_susceptibility,

    f.geom

FROM analytics.borough_flood_exposure AS f
JOIN analytics.borough_shrink_swell_exposure AS s
  ON f.borough_id = s.borough_id;


ALTER TABLE analytics.borough_hazard_summary
    ADD PRIMARY KEY (borough_id);

CREATE INDEX borough_hazard_summary_geom_idx
    ON analytics.borough_hazard_summary
    USING GIST (geom);

COMMENT ON TABLE analytics.borough_hazard_summary IS
    'Combined borough-level flood-zone and shrink-swell susceptibility metrics';


-- Check the combined results

SELECT
    borough_name,
    fz2_percent,
    fz3_percent,
    shrink_moderate_percent,
    shrink_significant_percent,
    dominant_susceptibility
FROM analytics.borough_hazard_summary
ORDER BY fz3_percent DESC
LIMIT 10;