DROP TABLE IF EXISTS citizen_changes CASCADE;

-- Table Definition
CREATE TABLE IF NOT EXISTS citizen_changes (
    id SERIAL PRIMARY KEY,
    citizen_id INTEGER NOT NULL REFERENCES citizen(id),
    change_date DATE NOT NULL,
    details JSONB
);

-- Add comments to the table and columns
COMMENT ON TABLE citizen_changes IS 'Tracks changes to citizen records.';
COMMENT ON COLUMN citizen_changes.citizen_id IS 'Reference to the citizen who was changed.';
COMMENT ON COLUMN citizen_changes.change_date IS 'The date the change occurred.';
COMMENT ON COLUMN citizen_changes.details IS 'JSON document describing the change.'; 