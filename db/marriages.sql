CREATE TABLE IF NOT EXISTS marriages (
    id SERIAL PRIMARY KEY,
    partner1_id INTEGER NOT NULL,
    partner2_id INTEGER NOT NULL,
    married_date DATE NOT NULL,
    divorced_date DATE,
    FOREIGN KEY (partner1_id) REFERENCES citizen(id),
    FOREIGN KEY (partner2_id) REFERENCES citizen(id),
    CHECK (partner1_id != partner2_id)
);

COMMENT ON TABLE marriages IS 'Records marriages between citizens with marriage and divorce dates.';
COMMENT ON COLUMN marriages.id IS 'Unique identifier for the marriage record.';
COMMENT ON COLUMN marriages.partner1_id IS 'Reference to the first partner in the marriage.';
COMMENT ON COLUMN marriages.partner2_id IS 'Reference to the second partner in the marriage.';
COMMENT ON COLUMN marriages.married_date IS 'Date when the marriage took place.';
COMMENT ON COLUMN marriages.divorced_date IS 'Date when the marriage ended in divorce (NULL if still married).'; 