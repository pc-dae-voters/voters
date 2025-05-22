CREATE TABLE places (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country_id INTEGER,
    FOREIGN KEY (country_id) REFERENCES countries(id),
    UNIQUE (name, country_id)
); 