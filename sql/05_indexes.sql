-- CP3: Indexes justified by the baseline workload plans.
-- pg_trgm is used for the contains/prefix ILIKE searches in R06 and R16.
SET search_path TO instagram, public;

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

-- R01, R02: active-user feeds/profile grids, ordered newest first.
CREATE INDEX IF NOT EXISTS posts_active_by_user_created_idx
    ON instagram.posts (user_id, created_at DESC)
    INCLUDE (post_id, post_type, like_count, comment_count)
    WHERE NOT is_archived;

-- R05, R11, R12, R16, R18, R20: selective time ranges and their joins/projections.
CREATE INDEX IF NOT EXISTS posts_by_created_at_idx
    ON instagram.posts (created_at, post_id)
    INCLUDE (user_id, like_count, comment_count, post_type);

-- R17: restrict the date-range scan to reels.
CREATE INDEX IF NOT EXISTS posts_reels_by_created_at_idx
    ON instagram.posts (created_at, user_id)
    INCLUDE (post_id, like_count)
    WHERE post_type = 'REEL';

-- R21: find posts by their author before probing likes.
CREATE INDEX IF NOT EXISTS posts_by_user_post_idx
    ON instagram.posts (user_id, post_id)
    INCLUDE (created_at);

-- R05: the existing primary key starts with post_id, not hashtag_id.
CREATE INDEX IF NOT EXISTS post_hashtags_by_hashtag_idx
    ON instagram.post_hashtags (hashtag_id, post_id);

-- R07: avoid scanning the full likes table for a post; also supplies sort values.
CREATE INDEX IF NOT EXISTS likes_by_post_idx
    ON instagram.likes (post_id, user_id)
    INCLUDE (created_at);

-- R14, R15, W04: accepted relationships by followee; follower_id covers R14.
CREATE INDEX IF NOT EXISTS follows_accepted_by_followee_idx
    ON instagram.follows (followee_id, follower_id)
    WHERE status = 'ACCEPTED';

-- R09, W06: pending requests for one followee, newest first.
CREATE INDEX IF NOT EXISTS follows_pending_by_followee_created_idx
    ON instagram.follows (followee_id, created_at DESC)
    INCLUDE (follower_id)
    WHERE status = 'PENDING';

-- R04, R13, R20: locate comments for a post (the existing key starts with comment_id).
CREATE INDEX IF NOT EXISTS comments_by_post_idx
    ON instagram.comments (post_id);

-- R04, R13: locate replies/children by their parent comment.
CREATE INDEX IF NOT EXISTS comments_by_parent_idx
    ON instagram.comments (parent_comment_id)
    WHERE parent_comment_id IS NOT NULL;

-- R22: filter hidden comments and read them in newest-first order.
CREATE INDEX IF NOT EXISTS comments_hidden_by_created_idx
    ON instagram.comments (created_at DESC)
    WHERE is_hidden;

-- R10: stories for followed users within a date range, newest first.
CREATE INDEX IF NOT EXISTS stories_by_user_created_idx
    ON instagram.stories (user_id, created_at DESC)
    INCLUDE (story_id, media_type, view_count);

-- R24: date-range scan and covered inputs for per-user aggregation.
CREATE INDEX IF NOT EXISTS stories_by_created_user_idx
    ON instagram.stories (created_at, user_id)
    INCLUDE (view_count);

-- R06: GIN trigram indexes support ILIKE prefix/substring predicates.
CREATE INDEX IF NOT EXISTS users_username_trgm_idx
    ON instagram.users USING GIN (username gin_trgm_ops);

CREATE INDEX IF NOT EXISTS users_full_name_trgm_idx
    ON instagram.users USING GIN (full_name gin_trgm_ops);

-- R16: support the leading-wildcard location search.
CREATE INDEX IF NOT EXISTS posts_location_trgm_idx
    ON instagram.posts USING GIN (location_name gin_trgm_ops);
