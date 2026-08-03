-- FloodFax storage schema.
--
-- Reports are stored whole as JSONB: the document is the contract with the
-- frontend and the PDF renderer, and splitting it into columns would mean
-- migrating three consumers every time a metric is added. The scalar columns
-- exist only for listing, sorting and neighbourhood lookups.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS analyses (
    id               TEXT PRIMARY KEY,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    label            TEXT NOT NULL,
    lat              DOUBLE PRECISION NOT NULL,
    lng              DOUBLE PRECISION NOT NULL,
    flood_score      DOUBLE PRECISION NOT NULL,
    flood_band       TEXT NOT NULL,
    investment_score DOUBLE PRECISION NOT NULL,
    confidence       DOUBLE PRECISION NOT NULL,
    document         JSONB NOT NULL,
    geom             geography(Point, 4326)
        GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography) STORED
);

CREATE INDEX IF NOT EXISTS analyses_created_at_idx ON analyses (created_at DESC);
CREATE INDEX IF NOT EXISTS analyses_position_idx   ON analyses (lat, lng);
CREATE INDEX IF NOT EXISTS analyses_geom_idx       ON analyses USING GIST (geom);

-- "What else have we scored near here?" — index-backed rather than a scan.
-- SELECT id, label, flood_score
-- FROM analyses
-- WHERE ST_DWithin(geom, ST_MakePoint(80.2707, 13.0827)::geography, 2000)
-- ORDER BY created_at DESC;
