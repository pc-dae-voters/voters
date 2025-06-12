CREATE TABLE births (
    citizen_id BIGINT PRIMARY KEY,
    surname_id INT NOT NULL,
    first_name_id INT NOT NULL,
    gender CHAR(1) NOT NULL,
    date DATE NOT NULL,
    place_id BIGINT,
    father_id BIGINT,
    mother_id BIGINT,
    FOREIGN KEY (citizen_id) REFERENCES citizens(id) ON DELETE CASCADE,
    FOREIGN KEY (surname_id) REFERENCES surnames(id),
    FOREIGN KEY (first_name_id) REFERENCES first_names(id),
    FOREIGN KEY (father_id) REFERENCES citizens(id) ON DELETE SET NULL,
    FOREIGN KEY (mother_id) REFERENCES citizens(id) ON DELETE SET NULL,
    FOREIGN KEY (place_id) REFERENCES places(id)
);

COMMENT ON TABLE births IS 'Records birth events for citizens.';
COMMENT ON COLUMN births.citizen_id IS 'The citizen who was born.';
COMMENT ON COLUMN births.surname_id IS 'Reference to the surname of the citizen at birth.';
COMMENT ON COLUMN births.first_name_id IS 'Reference to the first name(s) of the citizen at birth.';
COMMENT ON COLUMN births.gender IS 'Gender of the citizen at birth.';
COMMENT ON COLUMN births.date IS 'Date of birth.';
COMMENT ON COLUMN births.place_id IS 'Place of birth, references the places table.';
COMMENT ON COLUMN births.father_id IS 'Citizen ID of the father, if known.';
COMMENT ON COLUMN births.mother_id IS 'Citizen ID of the mother, if known.';