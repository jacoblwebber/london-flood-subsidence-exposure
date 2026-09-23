-- Build clean, analysis-ready spatial layers

DROP TABLE IF EXISTS core.london_boroughs;

CREATE TABLE core.london_boroughs AS
SELECT
    id AS borough_id,
    gss_code,
    name AS borough_name,
    hectares,
    nonld_area,
    ons_inner,
    sub_2011,
    geom
FROM raw.london_boroughs;

ALTER TABLE core.london_boroughs
    ADD PRIMARY KEY (borough_id);

CREATE INDEX london_boroughs_geom_idx
    ON core.london_boroughs USING GIST (geom);


DROP TABLE IF EXISTS core.flood_zones_london;

CREATE TABLE core.flood_zones_london AS
SELECT
    id AS flood_id,
    flood_zone,
    geom
FROM staging.ea_flood_zones_london;

ALTER TABLE core.flood_zones_london
    ADD PRIMARY KEY (flood_id);

CREATE INDEX flood_zones_geom_idx
    ON core.flood_zones_london USING GIST (geom);


DROP TABLE IF EXISTS core.shrink_swell_london;

CREATE TABLE core.shrink_swell_london AS
SELECT
    id AS shrink_swell_id,
    class::smallint AS susceptibility_class,
    legend AS susceptibility_label,
    advisory,
    notice,
    version,
    geom
FROM staging.bgs_shrink_swell_london;

ALTER TABLE core.shrink_swell_london
    ADD PRIMARY KEY (shrink_swell_id);

CREATE INDEX shrink_swell_geom_idx
    ON core.shrink_swell_london USING GIST (geom);


-- Confirm that every record was copied

SELECT 'boroughs' AS dataset, COUNT(*) AS records
FROM core.london_boroughs

UNION ALL

SELECT 'flood_zones', COUNT(*)
FROM core.flood_zones_london

UNION ALL

SELECT 'shrink_swell', COUNT(*)
FROM core.shrink_swell_london;