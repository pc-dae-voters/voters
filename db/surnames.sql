DROP TABLE IF EXISTS surnames CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS surnames (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);
 
COMMENT ON TABLE surnames IS 'Stores unique surnames.';
COMMENT ON COLUMN surnames.id IS 'Unique identifier for the surname.';
COMMENT ON COLUMN surnames.name IS 'The surname.'; 