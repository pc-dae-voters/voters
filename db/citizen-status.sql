CREATE TABLE IF NOT EXISTS citizen-status (
    id SERIAL PRIMARY KEY,
    status_code CHAR(1) UNIQUE NOT NULL,
    status_description VARCHAR(255) NOT NULL
);

INSERT INTO citizen-status (status_code, status_description) VALUES
('A', 'Active'),
('B', 'British Citizen'),
('N', 'Naturalized'),
('F', 'Foreign National');
