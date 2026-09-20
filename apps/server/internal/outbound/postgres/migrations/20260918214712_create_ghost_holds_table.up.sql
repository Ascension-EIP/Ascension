CREATE TABLE ghost_holds (
    ghost_id  UUID NOT NULL REFERENCES ghosts(id) ON DELETE CASCADE,
    hold_id   UUID NOT NULL REFERENCES holds(id) ON DELETE CASCADE,
    position  SMALLINT,

    PRIMARY KEY (ghost_id, hold_id)
);

CREATE INDEX idx_ghost_holds_hold_id ON ghost_holds(hold_id);
