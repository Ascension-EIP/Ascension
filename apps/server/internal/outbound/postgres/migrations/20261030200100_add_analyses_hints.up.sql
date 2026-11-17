-- The AI worker writes the structured advice (schemas/hints.schema.json) here. `advice` is kept: the Go server still reads it.
ALTER TABLE analyses ADD COLUMN hints JSONB;
