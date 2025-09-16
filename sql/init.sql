-- init.sql
-- Run all parts in order
\i 'sql/00_schema_and_extensions.sql'
\i 'sql/10_tables.sql'
\i 'sql/20_indexes.sql'
\i 'sql/30_sample_data.sql'
\i 'sql/40_views.sql'
\i 'sql/50_materialized_views.sql'
\i 'sql/60_queries.sql'
-- Optional: analysis queries
-- \i 'sql/60_queries.sql'
