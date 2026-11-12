-- videos.climbing_session_id referenced users(id): the videos migration runs before
-- climbing_sessions exists, so the foreign key could not point at the right table.
-- A video, and so its analyses, belongs to at most one climbing session.
BEGIN;

ALTER TABLE videos DROP CONSTRAINT videos_climbing_session_id_fkey;

-- Values accepted by the old constraint are user IDs, not climbing session IDs.
UPDATE videos SET climbing_session_id = NULL
 WHERE climbing_session_id IS NOT NULL
   AND climbing_session_id NOT IN (SELECT id FROM climbing_sessions);

ALTER TABLE videos ADD CONSTRAINT videos_climbing_session_id_fkey
    FOREIGN KEY (climbing_session_id) REFERENCES climbing_sessions(id) ON DELETE SET NULL;

COMMIT;
