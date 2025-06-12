CREATE TABLE citizen_changes (
    citizen_id BIGINT NOT NULL,
    change_date DATE NOT NULL,
    surname VARCHAR(255) NOT NULL,
    first_names VARCHAR(255) NOT NULL,
    gender CHAR(1),
    notes TEXT, -- Added notes here as it might be relevant to a change
    PRIMARY KEY (citizen_id, change_date),
    FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE
);

COMMENT ON TABLE citizen_changes IS 'Tracks changes to citizen details over time, like name changes, gender reassignment, or corrections.';
COMMENT ON COLUMN citizen_changes.citizen_id IS 'Reference to the citizen this change applies to.';
COMMENT ON COLUMN citizen_changes.change_date IS 'The date this change became effective.';
COMMENT ON COLUMN citizen_changes.surname IS 'The surname of the citizen as of this change date.';
COMMENT ON COLUMN citizen_changes.first_names IS 'The first names of the citizen as of this change date.';
COMMENT ON COLUMN citizen_changes.gender IS 'The gender of the citizen as of this change date';
COMMENT ON COLUMN citizen_changes.notes IS 'Optional notes about this specific change.'; 