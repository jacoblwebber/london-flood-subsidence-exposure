-- 13_create_borough_property_exposure_summary.sql
-- Creates a map-ready summary of property and hazard exposure
-- across all 33 London boroughs.

BEGIN;

DROP TABLE IF EXISTS analytics.borough_property_exposure_2025;

CREATE TABLE analytics.borough_property_exposure_2025 AS
WITH borough_metrics AS (
    SELECT
        borough_gss_code,

        COUNT(*)::bigint AS total_sales,
        SUM(price)::bigint AS total_sales_value,

        (
            PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY price)
        )::bigint AS median_sale_price,

        COUNT(*) FILTER (
            WHERE in_flood_zone
        )::bigint AS flood_zone_sales,

        SUM(price) FILTER (
            WHERE in_flood_zone
        )::bigint AS flood_zone_sales_value,

        ROUND(
            100.0 * COUNT(*) FILTER (WHERE in_flood_zone)
            / NULLIF(COUNT(*), 0),
            2
        ) AS flood_zone_pct,

        COUNT(*) FILTER (
            WHERE in_flood_zone_3
        )::bigint AS flood_zone_3_sales,

        SUM(price) FILTER (
            WHERE in_flood_zone_3
        )::bigint AS flood_zone_3_sales_value,

        ROUND(
            100.0 * COUNT(*) FILTER (WHERE in_flood_zone_3)
            / NULLIF(COUNT(*), 0),
            2
        ) AS flood_zone_3_pct,

        COUNT(*) FILTER (
            WHERE significant_shrink_swell
        )::bigint AS significant_shrink_swell_sales,

        SUM(price) FILTER (
            WHERE significant_shrink_swell
        )::bigint AS significant_shrink_swell_value,

        ROUND(
            100.0 * COUNT(*) FILTER (WHERE significant_shrink_swell)
            / NULLIF(COUNT(*), 0),
            2
        ) AS significant_shrink_swell_pct,

        COUNT(*) FILTER (
            WHERE dual_hazard_flag
        )::bigint AS dual_hazard_sales,

        SUM(price) FILTER (
            WHERE dual_hazard_flag
        )::bigint AS dual_hazard_sales_value,

        ROUND(
            100.0 * COUNT(*) FILTER (WHERE dual_hazard_flag)
            / NULLIF(COUNT(*), 0),
            2
        ) AS dual_hazard_pct

    FROM analytics.property_hazard_exposure_2025
    GROUP BY borough_gss_code
)

SELECT
    b.borough_id,
    b.gss_code AS borough_gss_code,
    b.borough_name,

    COALESCE(m.total_sales, 0)::bigint AS total_sales,
    COALESCE(m.total_sales_value, 0)::bigint AS total_sales_value,
    m.median_sale_price,

    COALESCE(m.flood_zone_sales, 0)::bigint AS flood_zone_sales,
    COALESCE(m.flood_zone_sales_value, 0)::bigint AS flood_zone_sales_value,
    COALESCE(m.flood_zone_pct, 0.00) AS flood_zone_pct,

    COALESCE(m.flood_zone_3_sales, 0)::bigint AS flood_zone_3_sales,
    COALESCE(m.flood_zone_3_sales_value, 0)::bigint AS flood_zone_3_sales_value,
    COALESCE(m.flood_zone_3_pct, 0.00) AS flood_zone_3_pct,

    COALESCE(m.significant_shrink_swell_sales, 0)::bigint
        AS significant_shrink_swell_sales,

    COALESCE(m.significant_shrink_swell_value, 0)::bigint
        AS significant_shrink_swell_value,

    COALESCE(m.significant_shrink_swell_pct, 0.00)
        AS significant_shrink_swell_pct,

    COALESCE(m.dual_hazard_sales, 0)::bigint AS dual_hazard_sales,
    COALESCE(m.dual_hazard_sales_value, 0)::bigint
        AS dual_hazard_sales_value,
    COALESCE(m.dual_hazard_pct, 0.00) AS dual_hazard_pct,

    b.geom

FROM core.london_boroughs b

LEFT JOIN borough_metrics m
    ON b.gss_code = m.borough_gss_code

ORDER BY b.borough_name;

ALTER TABLE analytics.borough_property_exposure_2025
    ADD CONSTRAINT borough_property_exposure_2025_pkey
    PRIMARY KEY (borough_id);

CREATE UNIQUE INDEX idx_borough_property_exposure_gss
    ON analytics.borough_property_exposure_2025 (borough_gss_code);

CREATE INDEX idx_borough_property_exposure_geom
    ON analytics.borough_property_exposure_2025
    USING GIST (geom);

COMMENT ON TABLE analytics.borough_property_exposure_2025 IS
    'Borough-level summary of 2025 London property transactions and screening-level hazard exposure using postcode centroids.';

ANALYZE analytics.borough_property_exposure_2025;

COMMIT;