CREATE TABLE IF NOT EXISTS citizen (
    id SERIAL PRIMARY KEY,
    status_id INTEGER REFERENCES citizen-status(id)
);




