-- Add a real-time progress column to the analyses table.
-- The AI worker updates this value every ~30 frames so the client can display
-- a meaningful percentage instead of a fake time-based estimate.
-- Range: 0 (not started) → 100 (complete / failed).
ALTER TABLE analyses
    ADD COLUMN IF NOT EXISTS progress INTEGER NOT NULL DEFAULT 0;
