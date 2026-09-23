-- 09_create_property_raw_tables.sql
-- Raw landing tables for ONS postcode and HM Land Registry data.
-- Columns are stored as text initially so source data imports reliably.

BEGIN;

DROP TABLE IF EXISTS raw.ons_postcodes_london;
DROP TABLE IF EXISTS raw.hmlr_price_paid_2025;

CREATE TABLE raw.ons_postcodes_london (
    pcds            text,
    dointr          text,
    doterm          text,
    lad26cd         text,
    east1m          text,
    north1m         text,
    rgn26cd         text,
    latitude        text,
    longitude       text,
    lsoa21cd        text,
    msoa21cd        text
);

CREATE TABLE raw.hmlr_price_paid_2025 (
    transaction_id      text,
    price               text,
    transfer_date       text,
    postcode            text,
    property_type       text,
    old_new             text,
    duration            text,
    paon                text,
    saon                text,
    street              text,
    locality            text,
    town_city           text,
    district            text,
    county              text,
    ppd_category        text,
    record_status       text
);

COMMENT ON TABLE raw.ons_postcodes_london IS
    'London postcode records extracted from the ONS Postcode Directory, August 2026.';

COMMENT ON TABLE raw.hmlr_price_paid_2025 IS
    'HM Land Registry Price Paid Data transactions for 2025.';

COMMIT;