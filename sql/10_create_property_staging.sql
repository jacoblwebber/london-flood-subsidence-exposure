-- 10_create_property_staging.sql
-- Cleans raw postcode and property-price data and assigns correct data types.

BEGIN;

DROP TABLE IF EXISTS staging.ons_postcodes_london;
DROP TABLE IF EXISTS staging.hmlr_price_paid_2025;

-- Clean and spatially enable the London postcode data.
CREATE TABLE staging.ons_postcodes_london AS
SELECT
    TRIM(pcds) AS postcode,

    REGEXP_REPLACE(
        UPPER(TRIM(pcds)),
        '[[:space:]]+',
        '',
        'g'
    ) AS postcode_key,

    NULLIF(TRIM(dointr), '') AS introduced_yyyymm,
    NULLIF(TRIM(doterm), '') AS terminated_yyyymm,
    NULLIF(TRIM(lad26cd), '') AS borough_gss_code,
    NULLIF(TRIM(east1m), '')::integer AS easting,
    NULLIF(TRIM(north1m), '')::integer AS northing,
    NULLIF(TRIM(rgn26cd), '') AS region_code,
    NULLIF(TRIM(latitude), '')::double precision AS latitude,
    NULLIF(TRIM(longitude), '')::double precision AS longitude,
    NULLIF(TRIM(lsoa21cd), '') AS lsoa21cd,
    NULLIF(TRIM(msoa21cd), '') AS msoa21cd,

    CASE
        WHEN NULLIF(TRIM(east1m), '') IS NOT NULL
         AND NULLIF(TRIM(north1m), '') IS NOT NULL
        THEN ST_SetSRID(
            ST_MakePoint(
                NULLIF(TRIM(east1m), '')::double precision,
                NULLIF(TRIM(north1m), '')::double precision
            ),
            27700
        )::geometry(Point, 27700)
    END AS geom

FROM raw.ons_postcodes_london
WHERE NULLIF(TRIM(pcds), '') IS NOT NULL;


-- Clean the 2025 property-price transactions.
CREATE TABLE staging.hmlr_price_paid_2025 AS
SELECT
    NULLIF(TRIM(BOTH '{}' FROM TRIM(transaction_id)), '') AS transaction_id,
    NULLIF(TRIM(price), '')::bigint AS price,
    NULLIF(TRIM(transfer_date), '')::timestamp::date AS transfer_date,
    NULLIF(TRIM(postcode), '') AS postcode,

    REGEXP_REPLACE(
        UPPER(TRIM(postcode)),
        '[[:space:]]+',
        '',
        'g'
    ) AS postcode_key,

    NULLIF(TRIM(property_type), '') AS property_type,
    NULLIF(TRIM(old_new), '') AS old_new,
    NULLIF(TRIM(duration), '') AS duration,
    NULLIF(TRIM(paon), '') AS paon,
    NULLIF(TRIM(saon), '') AS saon,
    NULLIF(TRIM(street), '') AS street,
    NULLIF(TRIM(locality), '') AS locality,
    NULLIF(TRIM(town_city), '') AS town_city,
    NULLIF(TRIM(district), '') AS district,
    NULLIF(TRIM(county), '') AS county,
    NULLIF(TRIM(ppd_category), '') AS ppd_category,
    NULLIF(TRIM(record_status), '') AS record_status

FROM raw.hmlr_price_paid_2025
WHERE NULLIF(TRIM(transaction_id), '') IS NOT NULL;


-- Indexes for faster joins and spatial analysis.
CREATE INDEX idx_ons_postcodes_postcode_key
    ON staging.ons_postcodes_london (postcode_key);

CREATE INDEX idx_ons_postcodes_borough
    ON staging.ons_postcodes_london (borough_gss_code);

CREATE INDEX idx_ons_postcodes_geom
    ON staging.ons_postcodes_london
    USING GIST (geom);

CREATE INDEX idx_hmlr_postcode_key
    ON staging.hmlr_price_paid_2025 (postcode_key);

CREATE INDEX idx_hmlr_transfer_date
    ON staging.hmlr_price_paid_2025 (transfer_date);

ANALYZE staging.ons_postcodes_london;
ANALYZE staging.hmlr_price_paid_2025;

COMMIT;