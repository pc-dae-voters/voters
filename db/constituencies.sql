CREATE TABLE IF NOT EXISTS constituencies (
    code CHAR(15) PRIMARY KEY,
    name VARCHAR(255),
    tla CHAR(3),
    nation VARCHAR(255),
    region VARCHAR(255),
    ctype VARCHAR(255),
    area REAL
); 