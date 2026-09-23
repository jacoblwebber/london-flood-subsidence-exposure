-- 11_create_london_property_sales.sql
-- Creates an analysis-ready table of 2025 London property transactions.
-- Locations represent postcode centroids, not exact property coordinates.

BEGIN;

DROP TABLE IF EXISTS core.property_sales_london_2025;

CREATE TABLE core.property_sales_london_2025 AS
SELECT
    ROW_NUMBER() OVER (
        ORDER BY h.transaction_id
    )::bigint AS sale_id,

    h.transaction_id,
    h.price,
    h.transfer_date,
    h.postcode,
    h.postcode_key,
    h.property_type,
    h.old_new,
    h.duration AS tenure_code,

    b.borough_id,
    b.gss_code AS borough_gss_code,
    b.borough_name,

    p.lsoa21cd,
    p.msoa21cd,
    p.latitude,
    p.longitude,

    p.geom::geometry(Point, 27700) AS geom

FROM staging.hmlr_price_paid_2025 h

JOIN staging.ons_postcodes_london p
    ON h.postcode_key = p.postcode_key

JOIN core.london_boroughs b
    ON p.borough_gss_code = b.gss_code

WHERE h.record_status = 'A';


ALTER TABLE core.property_sales_london_2025
    ADD CONSTRAINT property_sales_london_2025_pkey
    PRIMARY KEY (sale_id);


CREATE INDEX idx_property_sales_transaction
    ON core.property_sales_london_2025 (transaction_id);

CREATE INDEX idx_property_sales_postcode
    ON core.property_sales_london_2025 (postcode_key);

CREATE INDEX idx_property_sales_borough
    ON core.property_sales_london_2025 (borough_gss_code);

CREATE INDEX idx_property_sales_date
    ON core.property_sales_london_2025 (transfer_date);

CREATE INDEX idx_property_sales_geom
    ON core.property_sales_london_2025
    USING GIST (geom);


COMMENT ON TABLE core.property_sales_london_2025 IS
    'HM Land Registry 2025 London property transactions matched to ONS postcode centroids and London boroughs.';

COMMENT ON COLUMN core.property_sales_london_2025.geom IS
    'ONS postcode centroid in British National Grid (EPSG:27700); not an exact property location.';

ANALYZE core.property_sales_london_2025;

COMMIT;