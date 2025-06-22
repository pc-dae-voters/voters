CREATE TABLE IF NOT EXISTS con-postcodes (
    postcode VARCHAR(10) NOT NULL,
    constituency_code CHAR(15) NOT NULL,
    FOREIGN KEY (constituency_code) REFERENCES constituencies(code)
);

CREATE INDEX idx_con_postcodes_con_code ON con-postcodes(constituency_code); 