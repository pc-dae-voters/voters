CREATE TABLE IF NOT EXISTS first-names (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    gender CHAR(1)
);
 
COMMENT ON TABLE first-names IS 'Stores unique first names.';
COMMENT ON COLUMN first-names.id IS 'Unique identifier for the first name.';
COMMENT ON COLUMN first-names.name IS 'The first name.';
COMMENT ON COLUMN first-names.gender IS 'The gender associated with the first name.'; 