-- Drop the table if it exists
DROP TABLE IF EXISTS citizen_status CASCADE;

-- Create the table, the column names are used by load-synthetic-people.py and voters-api's CitizenStatus entity
CREATE TABLE IF NOT EXISTS citizen_status (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) UNIQUE NOT NULL,
    description VARCHAR(255)
);

-- The citizenship codes load-synthetic-people.py assigns
INSERT INTO citizen_status (code, description) VALUES
('A', 'Active'),
('B', 'British Citizen'),
('N', 'Naturalized'),
('F', 'Foreign National');
