DROP TABLE IF EXISTS addresses CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS addresses (
    id SERIAL PRIMARY KEY,
    address VARCHAR(255),
    place_id INTEGER,
    postcode VARCHAR(10),
    constituency_id INTEGER REFERENCES constituencies(id),
    country_id INTEGER
);

-- Add comments to the table and columns
COMMENT ON TABLE addresses IS 'Stores address information.';
COMMENT ON COLUMN addresses.id IS 'Unique identifier for the address.';
COMMENT ON COLUMN addresses.address IS 'The full address string.';
COMMENT ON COLUMN addresses.place_id IS 'Reference to the place (town/city).';
COMMENT ON COLUMN addresses.postcode IS 'The postcode.';
COMMENT ON COLUMN addresses.constituency_id IS 'Reference to the parliamentary constituency.';
COMMENT ON COLUMN addresses.country_id IS 'Reference to the country.';

ALTER TABLE addresses ADD CONSTRAINT uq_address_full UNIQUE (address, place_id, postcode, constituency_id, country_id); 