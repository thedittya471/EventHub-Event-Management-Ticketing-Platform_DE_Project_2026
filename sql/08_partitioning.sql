-- CP4: Offline migration for the benchmark database after 05_indexes.sql.
-- The table is locked during the copy and needs space for both versions.
BEGIN;
SET LOCAL search_path TO instagram, public;

ALTER TABLE likes RENAME TO likes_unpartitioned;

CREATE TABLE likes (
    user_id INTEGER NOT NULL,
    post_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
) PARTITION BY HASH (post_id);

CREATE TABLE likes_p0 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 0);
CREATE TABLE likes_p1 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 1);
CREATE TABLE likes_p2 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 2);
CREATE TABLE likes_p3 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 3);
CREATE TABLE likes_p4 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 4);
CREATE TABLE likes_p5 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 5);
CREATE TABLE likes_p6 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 6);
CREATE TABLE likes_p7 PARTITION OF likes FOR VALUES WITH (MODULUS 8, REMAINDER 7);

INSERT INTO likes (user_id, post_id, created_at)
SELECT user_id, post_id, created_at FROM likes_unpartitioned;

DROP TABLE likes_unpartitioned;

ALTER TABLE likes
    ADD PRIMARY KEY (user_id, post_id),
    ADD FOREIGN KEY (user_id) REFERENCES users(user_id),
    ADD FOREIGN KEY (post_id) REFERENCES posts(post_id);

CREATE INDEX likes_by_post_idx ON likes (post_id, user_id) INCLUDE (created_at);

ANALYZE likes;
COMMIT;
