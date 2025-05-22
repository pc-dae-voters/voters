CREATE TABLE births (
    citizen_id BIGINT PRIMARY KEY,
    surname VARCHAR(255) NOT NULL,
    first_names VARCHAR(255) NOT NULL,
    gender CHAR(1) NOT NULL,
    date DATE NOT NULL,
    place_id BIGINT,
    father_id BIGINT,
    mother_id BIGINT,
    FOREIGN KEY (citizen_id) REFERENCES citizens(id),
    FOREIGN KEY (father_id) REFERENCES citizens(id),
    FOREIGN KEY (mother_id) REFERENCES citizens(id),
    FOREIGN KEY (place_id) REFERENCES places(id)
);