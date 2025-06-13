CREATE TABLE IF NOT EXISTS citizen_status (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL
);

INSERT INTO citizen_statuses (status_code, status_description) VALUES
('B', 'born in UK'),
('N', 'Naturalized'),
('R', 'Citizenship revoked'),
('D', 'Citizenship renounced'),
('F', 'Foreign');
