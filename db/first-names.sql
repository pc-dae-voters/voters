DROP TABLE IF EXISTS first_names CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS first_names (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    gender CHAR(1)
);

-- Add comments to the table and columns
COMMENT ON TABLE first_names IS 'Stores unique first names.';
COMMENT ON COLUMN first_names.id IS 'Unique identifier for the first name.';
COMMENT ON COLUMN first_names.name IS 'The first name.';
COMMENT ON COLUMN first_names.gender IS 'The gender associated with the name (M/F).'; 