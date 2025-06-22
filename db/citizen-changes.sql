CREATE TABLE IF NOT EXISTS citizen-changes (
    id SERIAL PRIMARY KEY,
    citizen_id INTEGER NOT NULL,
    change_date DATE NOT NULL DEFAULT CURRENT_DATE,
    change_type VARCHAR(50) NOT NULL,
    details TEXT,
    FOREIGN KEY (citizen_id) REFERENCES citizen(id)
);

COMMENT ON TABLE citizen-changes IS 'Tracks changes to citizen details over time, like name changes, gender reassignment, or corrections.';
COMMENT ON COLUMN citizen-changes.citizen_id IS 'Reference to the citizen this change applies to.';
COMMENT ON COLUMN citizen-changes.change_date IS 'The date this change became effective.';
COMMENT ON COLUMN citizen-changes.change_type IS 'The type of change that occurred.';
COMMENT ON COLUMN citizen-changes.details IS 'Details about the change.'; 