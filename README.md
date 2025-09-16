# E‑Commerce Analytics SQL (PostgreSQL)

Modularized version of the monolithic SQL file.

## Structure
- `sql/00_schema_and_extensions.sql` – schema, search_path, required extensions
- `sql/10_tables.sql` – core tables
- `sql/20_indexes.sql` – performance indexes
- `sql/30_sample_data.sql` – seed data
- `sql/40_views.sql` – derived views
- `sql/50_materialized_views.sql` – materialized view + refresh helper
- `sql/60_queries.sql` – ad-hoc analysis queries (optional)
- `sql/init.sql` – aggregator, runs all required parts in order

## How to run (psql)
```sh
createdb ecommerce_db || true
psql -d ecommerce_db -f sql/init.sql
```

## Notes
- `search_path` is `ecommerce, public` so `citext` type resolves.
- The refresh helper uses non-concurrent refresh. If you need online refresh, run manually:
```sql
CREATE UNIQUE INDEX IF NOT EXISTS uq_mv_monthly_kpis_month ON mv_monthly_kpis (month);
REFRESH MATERIALIZED VIEW CONCURRENTLY ecommerce.mv_monthly_kpis;
```
