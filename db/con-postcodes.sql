CREATE TABLE IF NOT EXISTS con_postcodes (
    postcode VARCHAR(10) PRIMARY KEY,
    constituency_code CHAR(15) REFERENCES constituencies(code)
);

CREATE INDEX idx_con_postcodes_con_code ON con_postcodes(constituency_code); 