CREATE TABLE IF NOT EXISTS addresses (
    id SERIAL PRIMARY KEY,
    line1 VARCHAR(255),
    line2 VARCHAR(255),
    line3 VARCHAR(255),
    line4 VARCHAR(255),
    line5 VARCHAR(255),
    postcode VARCHAR(10),
    place_id INTEGER REFERENCES places(id),
    country_code CHAR(2) REFERENCES countries(code)
);

COMMENT ON TABLE addresses IS 'Stores address components for voters and potentially other entities.';
COMMENT ON COLUMN addresses.id IS 'Unique identifier for the address.';
COMMENT ON COLUMN addresses.line1 IS 'First line of the address.';
COMMENT ON COLUMN addresses.line2 IS 'Second line of the address.';
COMMENT ON COLUMN addresses.line3 IS 'Third line of the address.';
COMMENT ON COLUMN addresses.line4 IS 'Fourth line of the address.';
COMMENT ON COLUMN addresses.line5 IS 'Fifth line of the address.';
COMMENT ON COLUMN addresses.postcode IS 'The postcode for this address, linked to a constituency postcode.';
COMMENT ON COLUMN addresses.place_id IS 'Reference to the city/town/village from the places table.';
COMMENT ON COLUMN addresses.country_code IS 'Reference to the country from the countries table.';

ALTER TABLE addresses ADD CONSTRAINT uq_address_full UNIQUE (line1, line2, line3, line4, line5, place_id, postcode); 