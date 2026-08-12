-- ============================================================================
-- Dumps the current public schema (tables' column lists, views, functions)
-- into a single text blob. Run via:
--   psql "$SUPABASE_DB_URL" -X -q -A -t -f dump_schema.sql -o schema.sql
-- -A (unaligned) + -t (tuples only) make psql print exactly the text value
-- below and nothing else — no column headers, no row count footer.
-- ============================================================================

WITH table_defs AS (
    SELECT
        c.table_name,
        string_agg(c.column_name || ' (' || c.data_type || ')', ', ' ORDER BY c.ordinal_position) AS cols
    FROM information_schema.columns c
    JOIN information_schema.tables t
        ON t.table_name = c.table_name AND t.table_schema = c.table_schema
    WHERE c.table_schema = 'public' AND t.table_type = 'BASE TABLE'
    GROUP BY c.table_name
),
tables_block AS (
    SELECT string_agg('-- ' || table_name || ':' || E'\n' || '--   ' || cols, E'\n' ORDER BY table_name) AS txt
    FROM table_defs
),
views_block AS (
    SELECT string_agg(
        '-- ----------------------------------------------------------------------------' || E'\n' ||
        '-- VIEW: ' || c.relname || E'\n' ||
        '-- ----------------------------------------------------------------------------' || E'\n' ||
        'CREATE OR REPLACE VIEW public.' || c.relname || ' AS' || E'\n' ||
        pg_get_viewdef(c.oid, true) || ';' || E'\n',
        E'\n' ORDER BY c.relname
    ) AS txt
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind = 'v'
),
functions_block AS (
    SELECT string_agg(
        '-- ----------------------------------------------------------------------------' || E'\n' ||
        '-- FUNCTION: ' || p.proname || E'\n' ||
        '-- ----------------------------------------------------------------------------' || E'\n' ||
        pg_get_functiondef(p.oid) || E'\n;' || E'\n',
        E'\n' ORDER BY p.proname
    ) AS txt
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prokind = 'f'
)
SELECT
    '-- ============================================================================' || E'\n' ||
    '-- INVENTORY REPORTING SYSTEM — SCHEMA SNAPSHOT (AUTO-GENERATED)' || E'\n' ||
    '-- Generated automatically by .github/workflows/sync.yml on every scheduled or' || E'\n' ||
    '-- manually-triggered run. DO NOT hand-edit this file — changes made here get' || E'\n' ||
    '-- overwritten on the next run. Make schema changes in Supabase (SQL Editor or' || E'\n' ||
    '-- a migration file); this file catches up automatically within 30 minutes, or' || E'\n' ||
    '-- immediately if you click "Sync / Reload" in the app.' || E'\n' ||
    '--' || E'\n' ||
    '-- This is a live reflection of what is currently deployed. It is NOT' || E'\n' ||
    '-- guaranteed to be safely re-runnable top-to-bottom (functions are listed' || E'\n' ||
    '-- alphabetically, not in dependency order), and it deliberately excludes RLS' || E'\n' ||
    '-- policies and GRANT statements — those still live only in their own numbered' || E'\n' ||
    '-- migration files. See PROJECT_HANDOFF.md for full architecture context.' || E'\n' ||
    '-- Generated: ' || now()::text || E'\n' ||
    '-- ============================================================================' || E'\n' ||
    E'\n' ||
    '-- ----------------------------------------------------------------------------' || E'\n' ||
    '-- TABLE STRUCTURE (column reference only — not full CREATE TABLE statements)' || E'\n' ||
    '-- ----------------------------------------------------------------------------' || E'\n' ||
    (SELECT txt FROM tables_block) || E'\n' ||
    E'\n' ||
    (SELECT txt FROM views_block) ||
    (SELECT txt FROM functions_block);
