# CP4 — Scalability report

## Setup

Measured on 23 November 2026 with PostgreSQL 18.3 (Homebrew), Apple M4, and
16 GB RAM. Both datasets used the CP1 schema and loader and the CP3 indexes.
The large load changed only the loader's CSV directory. Session time zone was
UTC. The temporary instance used 512 MB shared buffers, 512 MB maintenance work
memory, 4 MB work memory, at most two parallel workers per gather, and a 4 GB
WAL checkpoint budget. Autovacuum was paused on the benchmark instance and
`VACUUM (ANALYZE)` ran before the comparison passes.

| Table | Seed rows | Large rows |
|---|---:|---:|
| users | 30,000 | 600,000 |
| follows | 258,588 | 5,195,968 |
| hashtags | 50 | 50 |
| posts | 60,000 | 1,200,000 |
| post_hashtags | 150,000 | 3,000,000 |
| post_media | 89,854 | 1,800,749 |
| likes | 419,954 | 8,399,946 |
| comments | 150,000 | 3,000,000 |
| stories | 40,000 | 800,000 |
| **Total** | **1,198,446** | **23,996,713** |

Every pass used the optimized workload. Each query ran three times in its own
`psql` session with `EXPLAIN (ANALYZE, BUFFERS)`. The runner reports PostgreSQL
execution time, excluding client/network latency and transaction commit.
W01–W06 ran inside transactions that rolled back. Subsequent runs could
benefit from warmed caches, and rolled-back writes can leave dead tuples.
W01 now supplies the required zero counts and the unarchived flag for a new
post. R22 keeps `OFFSET 1500 LIMIT 25` and uses the partial hidden-comment
index. Its offset cost grows with the page number.

## Results

The CP3 column comes from the [historical seed summary](../benchmarks/results/optimized/summary.csv),
recorded on PostgreSQL 16.15. CP4 reran the seed and large indexed heaps
on the same PostgreSQL 18.3 instance to measure data growth. The partition-only
pass kept the same workload and the final run included the R13 rewrite.
Growth divides the indexed large average by the indexed CP4 seed average.
All timings and targets below are in milliseconds.

| Query | CP3 seed | CP4 seed | Large indexed | Large partitioned | Final | Heap growth | Target | Final status |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| R01 | 2.235 | 0.402 | 3.232 | 3.400 | 3.670 | 8.04× | < 5 | Met |
| R02 | 0.381 | 0.042 | 0.076 | 0.101 | 0.082 | 1.81× | < 5 | Met |
| R03 | 0.084 | 0.022 | 0.133 | 0.024 | 0.028 | 6.05× | < 5 | Met |
| R04 | 0.636 | 0.163 | 0.295 | 0.239 | 0.189 | 1.81× | < 5 | Met |
| R05 | 7.284 | 0.693 | 15.682 | 15.869 | 10.825 | 22.63× | < 250 | Met |
| R06 | 3.632 | 1.122 | 125.952 | 28.385 | 20.929 | 112.26× | < 250 | Met |
| R07 | 0.511 | 0.096 | 0.484 | 0.112 | 0.100 | 5.04× | < 5 | Met |
| R08 | 0.417 | 0.134 | 0.357 | 0.762 | 0.402 | 2.66× | < 250 | Met |
| R09 | 0.371 | 0.068 | 2.345 | 0.616 | 0.294 | 34.49× | < 5 | Met |
| R10 | 0.675 | 0.068 | 0.429 | 0.486 | 0.486 | 6.31× | < 250 | Met |
| R11 | 8.963 | 3.691 | 52.851 | 33.677 | 33.259 | 14.32× | < 5,000 | Met |
| R12 | 1.744 | 0.750 | 10.030 | 10.275 | 10.169 | 13.37× | < 5,000 | Met |
| R13 | 25.695 | 12.768 | 372.676 | 357.059 | 0.040 | 29.19× | < 250 | Met |
| R14 | 0.183 | 0.037 | 0.364 | 0.247 | 0.073 | 9.84× | < 250 | Met |
| R15 | 19.903 | 9.773 | 291.462 | 210.492 | 157.687 | 29.82× | < 5,000 | Met |
| R16 | 0.359 | 0.235 | 7.601 | 6.139 | 3.686 | 32.34× | < 250 | Met |
| R17 | 8.810 | 3.330 | 44.192 | 26.937 | 18.995 | 13.27× | < 5,000 | Met |
| R18 | 2.103 | 0.670 | 12.807 | 12.532 | 12.741 | 19.11× | < 5,000 | Met |
| R19 | 61.430 | 78.413 | 1699.030 | 1540.091 | 1422.472 | 21.67× | < 5,000 | Met |
| R20 | 3.669 | 2.987 | 46.272 | 49.415 | 48.257 | 15.49× | < 5,000 | Met |
| R21 | 0.726 | 0.089 | 0.387 | 4.441 | 4.800 | 4.35× | < 250 | Met |
| R22 | 2.756 | 1.630 | 5.369 | 1.986 | 30.201 | 3.29× | < 250 | Met |
| R23 | 0.060 | 0.028 | 0.031 | 0.032 | 0.104 | 1.11× | < 5 | Met |
| R24 | 1.612 | 0.463 | 9.442 | 8.392 | 9.619 | 20.39× | < 5,000 | Met |
| W01 | — | 0.990 | 1.458 | 1.349 | 1.822 | 1.47× | < 5 | Met |
| W02 | 2.363 | 0.686 | 1.005 | 0.955 | 1.024 | 1.47× | < 5 | Met |
| W03 | 1.770 | 0.540 | 1.050 | 1.018 | 0.916 | 1.94× | < 5 | Met |
| W04 | 111.404 | 67.566 | 1161.321 | 1144.573 | 1087.614 | 17.19× | < 3,000 | Met |
| W05 | 9.056 | 6.970 | 206.837 | 204.100 | 205.078 | 29.68× | < 3,000 | Met |
| W06 | 0.262 | 0.251 | 3.875 | 4.596 | 2.733 | 15.44× | < 5 | Met |

W01 had no published CP3 timing because the insert omitted required fields.

## Growth and plan changes

The following groups use the same SQL and index configuration on both data sizes.

| Heap growth | Queries |
|---|---|
| Up to 3× | R02, R04, R08, R23, W01, W02, W03 |
| Over 3× and under 10× | R01, R03, R07, R10, R14, R21, R22 |
| 10–25× | R05, R11, R12, R17, R18, R19, R20, R24, W04, W06 |
| Over 25× | R06, R09, R13, R15, R16, W05 |

Point probes such as R02 and R23 reused selective indexes as the dataset
grew. W01–W03 remained single-row operations. R05, R18–R20, R24, and the
batch jobs work over larger ranges or whole relations. W04 scanned about
5.0 million accepted follows and updated 24,000 users whose counts differed.
W05 sequentially scanned stories to remove an old date range. Both batch
jobs stayed within their 3,000 ms budgets.

The largest growth ratios include cache-sensitive and set-processing queries.
R06 used the same two GIN indexes but examined 24,000 candidate user rows on
the large dataset. Its first indexed large run took 342.371 ms and the next
two took about 18 ms each. R09 likewise had one 6.525 ms first run and two
runs below 0.3 ms. These differences matter for tail latency even when the
three-run average passes. R15 probes accepted follows for every verified or
creator account, so work increases with the candidate population. R16's
trigram/date bitmap intersection touches more rows and pages at scale.

**R13 was the sole target miss on the indexed large dataset.** The
partition-only pass reproduced it at 357.059 ms. The original subquery
materialized all three million comment rows and wrote 3,899 temporary blocks
per run on the indexed heap. The rewrite checks once whether any parent ID
is NULL, then probes replies by parent ID only if that check passes.

```text
Before (indexed large, run 1)
  Index Scan using comments_by_post_idx
    Filter: NOT (ANY (... SubPlan 1 ...))
    SubPlan 1: Materialize (actual rows=3000000)
      Seq Scan on comments
    Buffers: temp written=3899
  Execution Time: 369.525 ms

After (partitioned large, run 1)
  Result
    One-Time Filter: NOT (InitPlan 1).col1
    InitPlan 1: Seq Scan on comments (actual rows=1)
    Nested Loop Anti Join (never executed)
  Execution Time: 0.064 ms
```

The final average was 0.040 ms. The original SQL returns an empty result
when any top-level comment supplies a NULL parent ID. The rewrite preserves
that result and the anti-join behavior when no NULL exists. Bidirectional
`EXCEPT ALL` checks returned zero differences on both datasets. Changing
the query to return unreplied comments on this dataset would change
the supplied workload's semantics.

R19 scanned all eight likes partitions with `Parallel Append` in the
final plan. Its hash join used 16 batches, and the partial aggregation
spilled to disk. R21 used an `Append` of partition indexes with post IDs
supplied by the join. Its final timings ranged from 0.493 to 13.400 ms,
compared with a mean of 0.387 ms in the indexed heap. These are costs
to track alongside the selective R07 and R23 plans.

## Storage

Sizes were collected after vacuum/analyze and before timing each layout.
Database totals include system catalogs and other objects. The table
and index columns count physical Instagram relations, including the
eight likes children in the partitioned layout.

| Layout | Database (MiB) | Instagram tables (MiB) | Instagram indexes (MiB) | Likes tables (MiB) | Likes indexes (MiB) |
|---|---:|---:|---:|---:|---:|
| Seed indexed | 151.7 | 69.1 | 74.5 | 17.8 | 21.7 |
| Large indexed | 2,890.5 | 1,381.6 | 1,500.8 | 354.9 | 432.4 |
| Large partitioned | 2,900.6 | 1,379.9 | 1,512.4 | 355.1 | 432.7 |

The indexed large database was 19.05× the indexed seed size. Linear
extrapolation from the partitioned large snapshot gives about 14 GiB at
100× seed volume, before free-space headroom, WAL, backups and replicas.

## Architecture at 100× seed volume

### Partitioning

[The migration](../sql/08_partitioning.sql) splits `likes` into eight hash
partitions by `post_id`. R07 lists likes for one post, R23 checks one
(user, post) pair, and W02 inserts one such pair. Those shapes identify a
single partition. A query spanning all posts, such as R19 in the initial
workload, still needs access across partitions. Partitioning by time would
require the timestamp in the unique key and would allow multiple timestamps
for the same user and post. PostgreSQL requires every primary or unique key
on a partitioned table to include every partition-key column. Hashing by
`post_id` preserves the current primary key `(user_id, post_id)`, both
foreign keys, and the conflict target used by W02.
[PostgreSQL partitioning documentation](https://www.postgresql.org/docs/18/ddl-partitioning.html)

The migration copied 8,399,946 likes in an 11-second wall-clock run on the
test instance. Counts and an order-independent row checksum matched before
migration and after the final benchmark. The eight partitions contained
between 1,045,071 and 1,057,442 rows each. The migration takes an exclusive
lock and briefly needs both copies, so it belongs in a maintenance window
or a fresh load.

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, created_at
FROM instagram.likes
WHERE post_id = 59689;
```

With pruning enabled, PostgreSQL planned one index-only scan on `likes_p1`
and touched four shared buffers. With `enable_partition_pruning = off`,
the same query planned an `Append` of eight index-only scans and touched
25 shared buffers. Both returned five rows.

```text
Pruning on
  Index Only Scan using likes_p1_post_id_user_id_created_at_idx on likes_p1
    Index Cond: (post_id = 59689)
    Buffers: shared hit=1 read=3

Pruning off
  Append
    Buffers: shared hit=4 read=21
    -> Index Only Scan on likes_p0
    -> Index Only Scan on likes_p1
    ... six more partition index scans ...
```

In the full workload, R07's
average changed from 0.484 ms on the indexed heap to 0.112 ms in the
partition-only pass, with similar warmed medians (0.088 and 0.094 ms).
R23's averages were 0.031 and 0.032 ms. The plans demonstrate pruning
while the timings show how small these probes already were on this dataset.

### Sharding

Start with one primary and a read replica when query load justifies it.
If the primary later hits a measured capacity limit, shard posts by author
and route related media, comments, and likes to the same shard using a
post-to-shard directory. R02 stays on one author shard and the post-side
lookups in R04 and R07 stay on one post's shard. R07 still needs user
profiles and the viewer's follow relationships. Fetch those in batches
from the user and follow services. R01 spans the shards of the viewer's
followees. Group those followees by shard, ask each shard for up to 30
authorized posts, and merge the results by timestamp. At sustained feed
load, materialize feeds for active viewers and define a tie-breaker for
pagination. A pure post-ID shard key would distribute individual posts
more evenly but would also scatter the author queries R02 and R21.
Monitor author skew before choosing physical shard boundaries.

### Replica routing and caching

| Destination | Queries and consistency |
|---|---|
| Primary | W01–W06, R23, and R09. Route follow changes, like state, write-after-read authorization, and read-your-writes views through the primary. Route R22 here when a moderator needs current state. |
| Replica, with a primary fallback for fresh reads | R01–R04, R07–R08, R10, R13–R14, and R21. R01/R07 caches would need viewer-specific keys and invalidation on follow or privacy changes. Access checks must enforce current permissions. |
| Replica or short-lived cache where permitted | R05–R06, R11–R12, R15–R20, R22 for historical browsing, and R24. Cache aggregate reports and popular discovery results with their filters and observation timestamp in the key. Avoid caching moderation actions or private search results without an authorization-aware key. |

All writes and workflows requiring read-your-writes stay on the primary
until a replica has replayed the relevant commit. Measure replica lag
during W04 and W05 before routing latency-sensitive reads there.

### Maintenance

At 100× seed volume, plan for about 42 million likes, or 5.25 million per
partition with an even distribution. Start by testing an autovacuum vacuum
scale factor of 0.02 on each likes partition. With a base threshold of 50,
that would schedule cleanup after about 105,050 obsolete tuples per
partition at that size. Tune it and the insert-triggered vacuum settings
against observed dead tuples, write rate, and index-only heap fetches.
Schedule `ANALYZE instagram.likes` after major loads or distribution changes
to refresh parent statistics. Archive expired stories in bounded batches
and retain historical likes according to product retention rules. Hash
partitions cannot be detached by date. For archival by time, write
eligible records to verified cold storage before batched deletion and
preserve any required aggregate totals. Refresh per-post and per-author
summaries on a schedule or from committed changes, and keep a periodic
reconciliation against source rows.
[PostgreSQL routine vacuuming documentation](https://www.postgresql.org/docs/18/routine-vacuuming.html)

## Conclusion

All 30 final query averages met their 20× targets, including the six
writes. That supports next year's volume for this workload on a single
instance. It leaves concurrency, replication lag, sustained write throughput
and tail latency unmeasured. R01 had the smallest proportional headroom
at 3.670 ms against 5 ms. At five times the large dataset, linear
extrapolation from W04's 1,087.614 ms would put the batch job
at about 5.4 seconds and the 1,422.472 ms R19 report at about 7.1 seconds.
Measure those jobs under concurrent load before relying on the 100× design.

## Reproduction

Run from the project root with PostgreSQL connection settings in the usual
`PGHOST`, `PGPORT`, and `PGUSER` variables. Use a dedicated database for the
migration. To reproduce the partitioned summary after extracting the archive:

```bash
createdb cp4_large
psql -X -v ON_ERROR_STOP=1 -d cp4_large -f sql/01_schema.sql
sed 's|seed_data/|large_data/|g' sql/02_load_data.sql |
  psql -X -v ON_ERROR_STOP=1 -d cp4_large
psql -X -v ON_ERROR_STOP=1 -d cp4_large -f sql/05_indexes.sql -c 'ANALYZE'
psql -X -v ON_ERROR_STOP=1 -d cp4_large -f sql/08_partitioning.sql -c 'VACUUM (ANALYZE)'
./benchmarks/run_benchmark.sh cp4_large large 3 sql/06_optimized_queries.sql
```

The runner writes [the submitted timing summary](../benchmarks/results/large/summary.csv)
and a local file with all three execution plans for each query.
