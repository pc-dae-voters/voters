DROP TABLE IF EXISTS constituencies CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS constituencies (
    id SERIAL PRIMARY KEY,
    code VARCHAR(255) UNIQUE,
    name VARCHAR(255) NOT NULL,
    tla CHAR(3),
    nation VARCHAR(255),
    region VARCHAR(255),
    ctype VARCHAR(255),
    area REAL
); 