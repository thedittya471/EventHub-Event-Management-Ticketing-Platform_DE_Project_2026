# CP3 - Optimization Report

## Objective and methodology

CP3 applies indexes and query rewrites to the Instagram workload and compares
execution times with the supplied baseline. Measurements are from PostgreSQL
16.15 and use `EXPLAIN (ANALYZE, BUFFERS)`. Each benchmarked query was run three
times; the tables below report the average execution time in milliseconds from
the benchmark summary files.

The comparison uses
[`benchmarks/results/baseline/summary.csv`](../benchmarks/results/baseline/summary.csv)
and
[`benchmarks/results/optimized/summary.csv`](../benchmarks/results/optimized/summary.csv).
The optimized run covers R01-R24 and W02-W06. W01 has no optimized timing and
is excluded from the count of benchmarked queries.

Percentage improvement is calculated as:

`(baseline average - optimized average) / baseline average * 100`

A negative percentage indicates a regression. Values are rounded to two
decimal places; the averages are shown to three decimal places.

## Indexes and supported query patterns

The 16 indexes in [`sql/05_indexes.sql`](../sql/05_indexes.sql) support these
filter, join, and ordering patterns:

| Index(es) | Workload patterns |
|---|---|
| `posts_active_by_user_created_idx` | R01/R02: user-specific active posts ordered by creation time |
| `posts_by_created_at_idx` | R05/R11/R12/R16/R18/R20: date-range scans and post joins/projections |
| `posts_reels_by_created_at_idx` | R17: date-range lookup restricted to reels |
| `posts_by_user_post_idx` | R01/R21: finding a user's posts by author for feed/like checks |
| `post_hashtags_by_hashtag_idx` | R05: hashtag-to-post lookup; complements the primary key beginning with `post_id` |
| `likes_by_post_idx` | R07: likes for one post, with user and creation time available |
| `follows_accepted_by_followee_idx` | R14/R15/W04: accepted follows keyed by followee |
| `follows_pending_by_followee_created_idx` | R09/W06: pending requests for a followee, ordered newest first |
| `comments_by_post_idx` | R04/R13/R20: comments for a post |
| `comments_by_parent_idx` | R04/R13: reply lookup by parent comment |
| `comments_hidden_by_created_idx` | R22: hidden comments in newest-first order |
| `stories_by_user_created_idx` | R10: a followed user's stories within a date range |
| `stories_by_created_user_idx` | R24: date-range story aggregation by user |
| `users_username_trgm_idx`, `users_full_name_trgm_idx` | R06: username prefix and full-name substring `ILIKE` searches |
| `posts_location_trgm_idx` | R16: leading-wildcard location search |

The trigram indexes use PostgreSQL's `pg_trgm` extension. Existing primary-key
and unique indexes continue to serve exact-key lookups; the indexes above do
not replace them.

## Per-query comparison

| Query | Type | Baseline avg (ms) | Optimized avg (ms) | Improvement | Status |
|---|---|---:|---:|---:|---|
| R01 | READ | 14.275 | 2.235 | 84.34% | Improved |
| R02 | READ | 8.202 | 0.381 | 95.35% | Improved |
| R03 | READ | 0.083 | 0.084 | -1.20% | Regression; +0.001 ms |
| R04 | READ | 26.642 | 0.636 | 97.61% | Improved |
| R05 | READ | 29.401 | 7.284 | 75.23% | Improved |
| R06 | READ | 20.900 | 3.632 | 82.62% | Improved |
| R07 | READ | 25.435 | 0.511 | 97.99% | Improved |
| R08 | READ | 0.617 | 0.417 | 32.41% | Improved |
| R09 | READ | 10.891 | 0.371 | 96.59% | Improved |
| R10 | READ | 9.071 | 0.675 | 92.56% | Improved |
| R11 | READ | 16.893 | 8.963 | 46.94% | Improved |
| R12 | READ | 9.751 | 1.744 | 82.11% | Improved |
| R13 | READ | 36.708 | 25.695 | 30.00% | Improved |
| R14 | READ | 9.776 | 0.183 | 98.13% | Improved |
| R15 | READ | 63.056 | 19.903 | 68.44% | Improved |
| R16 | READ | 9.094 | 0.359 | 96.05% | Improved |
| R17 | READ | 29.151 | 8.810 | 69.78% | Improved |
| R18 | READ | 14.863 | 2.103 | 85.85% | Improved |
| R19 | READ | 11005.175 | 61.430 | 99.44% | Improved |
| R20 | READ | 28.208 | 3.669 | 86.99% | Improved |
| R21 | READ | 12.527 | 0.726 | 94.20% | Improved |
| R22 | READ | 16.794 | 2.756 | 83.59% | Improved |
| R23 | READ | 0.055 | 0.060 | -9.09% | Regression; +0.005 ms |
| R24 | READ | 7.745 | 1.612 | 79.19% | Improved |
| W01 | WRITE | N/A | N/A | N/A | NOT RUN |
| W02 | WRITE | 3.434 | 2.363 | 31.19% | Improved |
| W03 | WRITE | 0.466 | 1.770 | -279.83% | Regression; +1.304 ms |
| W04 | WRITE | 137.134 | 111.404 | 18.76% | Improved |
| W05 | WRITE | 24.065 | 9.056 | 62.37% | Improved |
| W06 | WRITE | 11.715 | 0.262 | 97.76% | Improved |

## Overall results

Of the 29 queries with measurements, **26 improved** and **3 regressed**:

- READ: 22 of 24 improved; R03 and R23 regressed.
- WRITE: 4 of 5 improved; W03 regressed.
- W01 was not run and is not included in those counts.

R19 had the largest improvement: its average fell from 11,005.175 ms to
61.430 ms, a reduction of approximately **99.44%**. Its original correlated
subqueries repeatedly scanned posts and likes; the optimized query aggregates
post and like activity once and joins the per-user results.

Other large read improvements include R14 (98.13%), R07 (97.99%), R04 (97.61%),
and R09 (96.59%). The summaries show targeted index scans replacing several
baseline sequential scans.

## Regressions and trade-offs

- **R03:** increased by 0.001 ms, from 0.083 ms to 0.084 ms.
- **R23:** increased by 0.005 ms, from 0.055 ms to 0.060 ms.
  These are tiny absolute changes.
- **W03:** increased by 1.304 ms, from 0.466 ms to 1.770 ms (a 279.83%
  regression by the stated formula). The update changes `like_count`, which is
  included in several added indexes; index maintenance is a plausible
  contributor, but these timings alone do not establish the cause.

W01 remains **NOT RUN**. Its insert omits `like_count`, `comment_count`, and
`is_archived`, which are `NOT NULL` columns without defaults in the schema.
The original query was not changed to force a benchmark, and no W01 timing is
reported.

## Correctness audit

Original and optimized SELECT queries R01-R24 were compared against the same
database snapshot in one repeatable-read, read-only transaction, using
`EXCEPT ALL` in both directions. Every comparison returned zero differing
rows.

The R10 and R18 half-open timestamp ranges preserve the original date-cast
boundaries in the session time zone. R17's timestamp range preserves the
original year extraction boundary. R13 retains the original `NOT IN` behavior
for nullable `parent_comment_id`; it was not changed to `NOT EXISTS`. R19's
pre-aggregation preserves the original post-time and like-count results,
including accounts without posts or likes. R11 and R24 are unchanged.

The comparison checked result multisets, including duplicates. Ordering
expressions and limits were preserved in the rewritten queries; ordering among
rows tied on the specified sort keys remains unspecified by the workload.

## Source artifacts

- Original workload: [`queries/workload_30.sql`](../queries/workload_30.sql)
- Optimized workload: [`sql/06_optimized_queries.sql`](../sql/06_optimized_queries.sql)
- Index definitions: [`sql/05_indexes.sql`](../sql/05_indexes.sql)
- Baseline averages: [`benchmarks/results/baseline/summary.csv`](../benchmarks/results/baseline/summary.csv)
- Optimized averages: [`benchmarks/results/optimized/summary.csv`](../benchmarks/results/optimized/summary.csv)
