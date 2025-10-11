-- Drop the table if it exists
DROP TABLE IF EXISTS citizen_status CASCADE;

-- Create the table
CREATE TABLE IF NOT EXISTS citizen_status (
    id SERIAL PRIMARY KEY,
    status_code VARCHAR(10) UNIQUE NOT NULL,
    status_description VARCHAR(255)
);

-- Add some initial data
INSERT INTO citizen_status (status_code, status_description) VALUES
('ACTIVE', 'Active citizen'),
('DECEASED', 'Deceased citizen'),
('INACTIVE', 'Inactive citizen');
