CREATE TABLE IF NOT EXISTS first_names (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    gender CHAR(1)
);
 
COMMENT ON TABLE first_names IS 'Stores unique first names.';
COMMENT ON COLUMN first_names.id IS 'Unique identifier for the first name.';
COMMENT ON COLUMN first_names.name IS 'The first name.';
COMMENT ON COLUMN first_names.gender IS 'The gender associated with the first name.'; 