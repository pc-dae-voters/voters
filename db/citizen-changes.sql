CREATE TABLE IF NOT EXISTS citizen_changes (
    id SERIAL PRIMARY KEY,
    citizen_id INTEGER REFERENCES citizen(id),
    change_date DATE NOT NULL,
    change_type VARCHAR(50) NOT NULL,
    details JSONB
);

COMMENT ON TABLE citizen_changes IS 'Tracks changes to citizen details over time, like name changes, gender reassignment, or corrections.';
COMMENT ON COLUMN citizen_changes.citizen_id IS 'Reference to the citizen this change applies to.';
COMMENT ON COLUMN citizen_changes.change_date IS 'The date this change became effective.';
COMMENT ON COLUMN citizen_changes.change_type IS 'The type of change that occurred.';
COMMENT ON COLUMN citizen_changes.details IS 'Details about the change.'; 