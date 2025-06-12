CREATE TABLE citizen_statuses (
    status_code CHAR(1) PRIMARY KEY,
    status_description VARCHAR(255) NOT NULL
);

INSERT INTO citizen_statuses (status_code, status_description) VALUES
('B', 'born in UK'),
('N', 'Naturalized'),
('R', 'Citizenship revoked'),
('D', 'Citizenship renounced'),
('F', 'Foreign');
