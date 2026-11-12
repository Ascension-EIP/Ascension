-- Restore the previous foreign key on users(id); climbing session IDs do not satisfy it.
BEGIN;

ALTER TABLE videos DROP CONSTRAINT videos_climbing_session_id_fkey;

UPDATE videos SET climbing_session_id = NULL
 WHERE climbing_session_id IS NOT NULL
   AND climbing_session_id NOT IN (SELECT id FROM users);

ALTER TABLE videos ADD CONSTRAINT videos_climbing_session_id_fkey
    FOREIGN KEY (climbing_session_id) REFERENCES users(id) ON DELETE SET NULL;

COMMIT;
