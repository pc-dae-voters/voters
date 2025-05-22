CREATE TABLE con_postcodes (
    con_code CHAR(15),
    postcode VARCHAR(10),
    PRIMARY KEY (postcode),
    FOREIGN KEY (con_code) REFERENCES constituencies(code)
);

CREATE INDEX idx_con_postcodes_con_code ON con_postcodes(con_code); 