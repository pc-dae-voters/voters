CREATE TABLE IF NOT EXISTS places (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country_id INTEGER REFERENCES countries(id)
);

COMMENT ON TABLE places IS 'Stores cities, towns, villages, and other populated places.';
COMMENT ON COLUMN places.id IS 'Unique identifier for the place.';
COMMENT ON COLUMN places.name IS 'Name of the place (city, town, village, etc.).';
COMMENT ON COLUMN places.country_id IS 'Reference to the country from the countries table.';

ALTER TABLE places ADD CONSTRAINT uq_place_country UNIQUE (name, country_id); 