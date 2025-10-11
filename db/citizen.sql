DROP TABLE IF EXISTS citizen CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS citizen (
    id SERIAL PRIMARY KEY,
    status_id INTEGER REFERENCES citizen_status(id),
    surname_id INTEGER REFERENCES surnames(id),
    first_name_id INTEGER REFERENCES first_names(id),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    died DATE
);

COMMENT ON TABLE citizen IS 'Records for all citizens with current name and status information.';
COMMENT ON COLUMN citizen.id IS 'Unique identifier for the citizen.';
COMMENT ON COLUMN citizen.status_id IS 'Reference to the citizen status from citizen-status table.';
COMMENT ON COLUMN citizen.surname_id IS 'Reference to the current surname from the surnames table.';
COMMENT ON COLUMN citizen.first_name_id IS 'Reference to the current first name from the first-names table.';
COMMENT ON COLUMN citizen.gender IS 'Gender of the person (M or F).';
COMMENT ON COLUMN citizen.died IS 'Date of death (NULL if still alive).';




