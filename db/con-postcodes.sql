DROP TABLE IF EXISTS con_postcodes CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS con_postcodes (
    con_code VARCHAR(10),
    postcode VARCHAR(10)
);

CREATE INDEX idx_con_postcodes_con_code ON con_postcodes(con_code);

COMMENT ON TABLE con_postcodes IS 'Maps postcodes to constituency codes.';
COMMENT ON COLUMN con_postcodes.con_code IS 'Constituency code.';
COMMENT ON COLUMN con_postcodes.postcode IS 'Postcode.'; 