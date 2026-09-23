-- 12_create_property_hazard_exposure.sql
-- Screens London property transactions against flood and shrink-swell hazards.
-- Results use postcode centroids, not exact property locations.

BEGIN;

-- Ensure spatial lookups are fast.
CREATE INDEX IF NOT EXISTS idx_flood_zones_london_geom
    ON core.flood_zones_london
    USING GIST (geom);

CREATE INDEX IF NOT EXISTS idx_shrink_swell_london_geom
    ON core.shrink_swell_london
    USING GIST (geom);


DROP TABLE IF EXISTS analytics.property_hazard_exposure_2025;


CREATE TABLE analytics.property_hazard_exposure_2025 AS
SELECT
    p.sale_id,
    p.transaction_id,
    p.price,
    p.transfer_date,
    p.postcode,
    p.postcode_key,
    p.property_type,
    p.old_new,
    p.tenure_code,

    p.borough_id,
    p.borough_gss_code,
    p.borough_name,
    p.lsoa21cd,
    p.msoa21cd,
    p.latitude,
    p.longitude,

    COALESCE(
        flood.flood_zone,
        'Outside FZ2/FZ3'
    ) AS flood_zone,

    COALESCE(
        flood.flood_zone IN ('FZ2', 'FZ3'),
        FALSE
    ) AS in_flood_zone,

    COALESCE(
        flood.flood_zone = 'FZ3',
        FALSE
    ) AS in_flood_zone_3,

    COALESCE(
        shrink.susceptibility_class,
        0
    )::smallint AS shrink_swell_class,

    COALESCE(
        shrink.susceptibility_label,
        'Not classified'
    ) AS shrink_swell_label,

    COALESCE(
        shrink.susceptibility_class = 3,
        FALSE
    ) AS significant_shrink_swell,

    (
        COALESCE(flood.flood_zone = 'FZ3', FALSE)
        AND
        COALESCE(shrink.susceptibility_class = 3, FALSE)
    ) AS dual_hazard_flag,

    p.geom::geometry(Point, 27700) AS geom

FROM core.property_sales_london_2025 p


-- If flood zones overlap, FZ3 takes priority over FZ2.
LEFT JOIN LATERAL (
    SELECT
        f.flood_zone
    FROM core.flood_zones_london f
    WHERE ST_Covers(f.geom, p.geom)
    ORDER BY
        CASE f.flood_zone
            WHEN 'FZ3' THEN 3
            WHEN 'FZ2' THEN 2
            ELSE 0
        END DESC,
        f.flood_id
    LIMIT 1
) flood ON TRUE


-- If polygons touch or overlap, retain the highest susceptibility class.
LEFT JOIN LATERAL (
    SELECT
        s.susceptibility_class,
        s.susceptibility_label
    FROM core.shrink_swell_london s
    WHERE ST_Covers(s.geom, p.geom)
    ORDER BY
        s.susceptibility_class DESC,
        s.shrink_swell_id
    LIMIT 1
) shrink ON TRUE;


ALTER TABLE analytics.property_hazard_exposure_2025
    ADD CONSTRAINT property_hazard_exposure_2025_pkey
    PRIMARY KEY (sale_id);


CREATE INDEX idx_property_hazard_borough
    ON analytics.property_hazard_exposure_2025 (borough_gss_code);

CREATE INDEX idx_property_hazard_flood
    ON analytics.property_hazard_exposure_2025 (flood_zone);

CREATE INDEX idx_property_hazard_shrink
    ON analytics.property_hazard_exposure_2025 (shrink_swell_class);

CREATE INDEX idx_property_hazard_geom
    ON analytics.property_hazard_exposure_2025
    USING GIST (geom);


COMMENT ON TABLE analytics.property_hazard_exposure_2025 IS
    'Screening-level hazard classification of 2025 London sales using ONS postcode centroids; not individual property-level risk.';

ANALYZE analytics.property_hazard_exposure_2025;

COMMIT;