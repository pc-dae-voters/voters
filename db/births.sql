CREATE TABLE IF NOT EXISTS births (
    citizen_id INTEGER PRIMARY KEY REFERENCES citizen(id),
    surname_id INTEGER REFERENCES surnames(id),
    first_name_id INTEGER REFERENCES first-names(id),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    date DATE NOT NULL,
    place_id INTEGER REFERENCES places(id),
    father_id INTEGER REFERENCES citizen(id),
    mother_id INTEGER REFERENCES citizen(id)
);

COMMENT ON TABLE births IS 'Records birth events for citizens with name and relationship information.';
COMMENT ON COLUMN births.citizen_id IS 'The unique identifier for the birth record, same as citizen ID.';
COMMENT ON COLUMN births.surname_id IS 'Reference to the surname from the surnames table.';
COMMENT ON COLUMN births.first_name_id IS 'Reference to the first name from the first-names table.';
COMMENT ON COLUMN births.gender IS 'Gender of the person (M or F).';
COMMENT ON COLUMN births.date IS 'Date of birth.';
COMMENT ON COLUMN births.place_id IS 'Place of birth, references the places table.';
COMMENT ON COLUMN births.father_id IS 'Reference to the father''s citizen record (optional).';
COMMENT ON COLUMN births.mother_id IS 'Reference to the mother''s citizen record (optional).';