DROP TABLE IF EXISTS "con-postcodes" CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS "con-postcodes" (
    postcode VARCHAR(15) PRIMARY KEY,
    con_code VARCHAR(255)
);

CREATE INDEX idx_con_postcodes_con_code ON "con-postcodes"(con_code);

COMMENT ON TABLE "con-postcodes" IS 'Maps postcodes to constituency codes.';
COMMENT ON COLUMN "con-postcodes".con_code IS 'Constituency code.';
COMMENT ON COLUMN "con-postcodes".postcode IS 'Postcode.'; 