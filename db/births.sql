CREATE TABLE IF NOT EXISTS births (
    id SERIAL PRIMARY KEY,
    voter_id INTEGER REFERENCES voters(id),
    date_of_birth DATE NOT NULL,
    place_id INTEGER REFERENCES places(id),
    country_code CHAR(2) REFERENCES countries(code)
);

COMMENT ON TABLE births IS 'Records birth events for citizens.';
COMMENT ON COLUMN births.id IS 'The unique identifier for the birth record.';
COMMENT ON COLUMN births.voter_id IS 'Reference to the voter associated with the birth.';
COMMENT ON COLUMN births.date_of_birth IS 'Date of birth.';
COMMENT ON COLUMN births.place_id IS 'Place of birth, references the places table.';
COMMENT ON COLUMN births.country_code IS 'Country code of the birth place, references the countries table.';