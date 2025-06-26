CREATE TABLE IF NOT EXISTS addresses (
    id SERIAL PRIMARY KEY,
    address VARCHAR(500),
    postcode VARCHAR(10),
    place_id INTEGER REFERENCES places(id),
    country_id INTEGER REFERENCES countries(id)
);

COMMENT ON TABLE addresses IS 'Stores address information for voters and potentially other entities.';
COMMENT ON COLUMN addresses.id IS 'Unique identifier for the address.';
COMMENT ON COLUMN addresses.address IS 'The full address as a single string.';
COMMENT ON COLUMN addresses.postcode IS 'The postcode for this address, linked to a constituency postcode.';
COMMENT ON COLUMN addresses.place_id IS 'Reference to the city/town/village from the places table.';
COMMENT ON COLUMN addresses.country_id IS 'Reference to the country from the countries table.';

ALTER TABLE addresses ADD CONSTRAINT uq_address_full UNIQUE (address, place_id, postcode); 