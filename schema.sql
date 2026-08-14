-- ============================================================================
-- INVENTORY REPORTING SYSTEM — SCHEMA SNAPSHOT (AUTO-GENERATED)
-- Generated automatically by .github/workflows/sync.yml on every scheduled or
-- manually-triggered run. DO NOT hand-edit this file — changes made here get
-- overwritten on the next run. Make schema changes in Supabase (SQL Editor or
-- a migration file); this file catches up automatically within 30 minutes, or
-- immediately if you click "Sync / Reload" in the app.
--
-- This is a live reflection of what is currently deployed. It is NOT
-- guaranteed to be safely re-runnable top-to-bottom (functions are listed
-- alphabetically, not in dependency order), and it deliberately excludes RLS
-- policies and GRANT statements — those still live only in their own numbered
-- migration files. See PROJECT_HANDOFF.md for full architecture context.
-- Generated: 2026-08-14 12:09:59.110479+00
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TABLE STRUCTURE (column reference only — not full CREATE TABLE statements)
-- ----------------------------------------------------------------------------
-- admin_users:
--   user_id (uuid)
-- inv_tracking_summary:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), adj_qty (numeric)
-- inv_tracking_summary_staging:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), adj_qty (numeric)
-- product_file:
--   barcode (text), user_barcode (text), category (text), sub_category (text), item_name (text)
-- product_file_staging:
--   barcode (text), user_barcode (text), category (text), sub_category (text), item_name (text)
-- product_stock:
--   barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric)
-- product_stock_staging:
--   barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric)
-- purchase_rcv_details:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), pur_qty (numeric), status (text)
-- purchase_rcv_details_staging:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), pur_qty (numeric), status (text)
-- purchase_return_details:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), rtn_qty (numeric), status (text)
-- purchase_return_details_staging:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), rtn_qty (numeric), status (text)
-- sale:
--   invoice_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), sale_qty (numeric), rtn_qty (numeric)
-- sale_staging:
--   invoice_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), sale_qty (numeric), rtn_qty (numeric)
-- store:
--   store_code (text), store_name (text)
-- store_delivery_details:
--   challan_no (text), txn_date (date), delivery_from (text), delivery_to (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), del_qty (numeric), status (text)
-- store_delivery_details_staging:
--   challan_no (text), txn_date (date), delivery_from (text), delivery_to (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), del_qty (numeric), status (text)
-- store_delivery_receive:
--   challan_no (text), txn_date (date), delivery_from (text), delivery_to (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), del_qty (numeric), rcv_qty (numeric), status (text)
-- store_delivery_receive_staging:
--   challan_no (text), txn_date (date), delivery_from (text), delivery_to (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), del_qty (numeric), rcv_qty (numeric), status (text)
-- store_dml:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), dml_qty (numeric), status (text)
-- store_dml_staging:
--   challan_no (text), txn_date (date), store_code (text), barcode (text), sal_barcode (text), cpu (numeric), mrp (numeric), dml_qty (numeric), status (text)
-- store_staging:
--   store_code (text), store_name (text)
-- sync_log:
--   table_name (text), last_synced_date (date), last_synced_at (timestamp with time zone), rows_synced (integer)
-- user_category_access:
--   user_id (uuid), category (text)

-- ----------------------------------------------------------------------------
-- VIEW: vw_stock_ledger
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.vw_stock_ledger AS
 SELECT purchase_rcv_details.store_code,
    purchase_rcv_details.barcode,
    purchase_rcv_details.sal_barcode,
    purchase_rcv_details.txn_date,
    purchase_rcv_details.pur_qty AS in_qty,
    0::numeric(18,4) AS out_qty,
    'PURCHASE'::text AS source_type
   FROM purchase_rcv_details
  WHERE (TRIM(BOTH FROM upper(purchase_rcv_details.status)) <> ALL (ARRAY['REJECTED'::text, 'PENDING'::text])) OR purchase_rcv_details.status IS NULL
UNION ALL
 SELECT store_delivery_receive.delivery_to AS store_code,
    store_delivery_receive.barcode,
    store_delivery_receive.sal_barcode,
    store_delivery_receive.txn_date,
    store_delivery_receive.rcv_qty AS in_qty,
    0::numeric(18,4) AS out_qty,
    'DELIVERY_RECEIVE'::text AS source_type
   FROM store_delivery_receive
UNION ALL
 SELECT sale.store_code,
    sale.barcode,
    sale.sal_barcode,
    sale.txn_date,
    sale.rtn_qty AS in_qty,
    sale.sale_qty AS out_qty,
    'SALE'::text AS source_type
   FROM sale
UNION ALL
 SELECT inv_tracking_summary.store_code,
    inv_tracking_summary.barcode,
    inv_tracking_summary.sal_barcode,
    inv_tracking_summary.txn_date,
        CASE
            WHEN inv_tracking_summary.adj_qty > 0::numeric THEN inv_tracking_summary.adj_qty
            ELSE 0::numeric
        END AS in_qty,
        CASE
            WHEN inv_tracking_summary.adj_qty < 0::numeric THEN - inv_tracking_summary.adj_qty
            ELSE 0::numeric
        END AS out_qty,
    'ADJUSTMENT'::text AS source_type
   FROM inv_tracking_summary
UNION ALL
 SELECT store_delivery_details.delivery_from AS store_code,
    store_delivery_details.barcode,
    store_delivery_details.sal_barcode,
    store_delivery_details.txn_date,
    0::numeric(18,4) AS in_qty,
    store_delivery_details.del_qty AS out_qty,
    'DELIVERY_DISPATCH'::text AS source_type
   FROM store_delivery_details
  WHERE TRIM(BOTH FROM upper(store_delivery_details.status)) IS DISTINCT FROM 'REJECTED'::text
UNION ALL
 SELECT store_dml.store_code,
    store_dml.barcode,
    store_dml.sal_barcode,
    store_dml.txn_date,
    0::numeric(18,4) AS in_qty,
    store_dml.dml_qty AS out_qty,
    'DAMAGE'::text AS source_type
   FROM store_dml
  WHERE TRIM(BOTH FROM upper(store_dml.status)) IS DISTINCT FROM 'REJECTED'::text
UNION ALL
 SELECT purchase_return_details.store_code,
    purchase_return_details.barcode,
    purchase_return_details.sal_barcode,
    purchase_return_details.txn_date,
    0::numeric(18,4) AS in_qty,
    purchase_return_details.rtn_qty AS out_qty,
    'PURCHASE_RETURN'::text AS source_type
   FROM purchase_return_details
  WHERE TRIM(BOTH FROM upper(purchase_return_details.status)) IS DISTINCT FROM 'REJECTED'::text;;
-- ----------------------------------------------------------------------------
-- FUNCTION: admin_get_all_categories
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_get_all_categories()
 RETURNS TABLE(category text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT DISTINCT pf.category
    FROM public.product_file pf
    WHERE pf.category IS NOT NULL
    ORDER BY pf.category;
END;
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: admin_get_category_access
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_get_category_access()
 RETURNS TABLE(user_id uuid, category text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT uca.user_id, uca.category
    FROM public.user_category_access uca;
END;
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: admin_list_users
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_list_users()
 RETURNS TABLE(user_id uuid, email text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT u.id, u.email::text
    FROM auth.users u
    ORDER BY u.email;
END;
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: admin_set_user_categories
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_set_user_categories(p_user_id uuid, p_categories text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    DELETE FROM public.user_category_access WHERE user_id = p_user_id;

    IF p_categories IS NOT NULL AND array_length(p_categories, 1) > 0 THEN
        INSERT INTO public.user_category_access (user_id, category)
        SELECT p_user_id, unnest(p_categories);
    END IF;
END;
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_barcode_stock_age
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_barcode_stock_age(as_of_date date, p_store_codes text[] DEFAULT NULL::text[])
 RETURNS TABLE(store_code text, barcode text, stock_age_days numeric)
 LANGUAGE sql
AS $function$
    WITH cycles AS (
        SELECT store_code, barcode, sal_barcode, cycle_start, cycle_end
        FROM fn_sale_barcode_stock_cycles(as_of_date, p_store_codes)
    ),
    ordered AS (
        SELECT store_code, barcode, cycle_start, cycle_end,
            MAX(cycle_end) OVER (
                PARTITION BY store_code, barcode
                ORDER BY cycle_start, sal_barcode
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ) AS prev_max_end
        FROM cycles
    ),
    flagged AS (
        SELECT *,
            CASE WHEN prev_max_end IS NULL OR cycle_start > prev_max_end + 1 THEN 1 ELSE 0 END AS new_island
        FROM ordered
    ),
    grouped AS (
        SELECT *,
            SUM(new_island) OVER (
                PARTITION BY store_code, barcode
                ORDER BY cycle_start
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS island_id
        FROM flagged
    ),
    islands AS (
        SELECT store_code, barcode, island_id,
               MIN(cycle_start) AS island_start,
               MAX(cycle_end)   AS island_end
        FROM grouped
        GROUP BY store_code, barcode, island_id
    )
    SELECT store_code, barcode,
           SUM(island_end - island_start + 1)::numeric AS stock_age_days
    FROM islands
    GROUP BY store_code, barcode
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_is_admin
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_is_admin()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_pending_stock
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_pending_stock(as_of_date date, p_store_codes text[] DEFAULT NULL::text[])
 RETURNS TABLE(store_code text, barcode text, sal_barcode text, pending_stock numeric)
 LANGUAGE sql
AS $function$
    WITH delivered AS (
        SELECT
            challan_no,
            delivery_to AS store_code,
            barcode,
            sal_barcode,
            SUM(del_qty) AS del_qty
        FROM store_delivery_details
        WHERE txn_date <= as_of_date
          AND TRIM(UPPER(status)) IS DISTINCT FROM 'REJECTED'
          AND (p_store_codes IS NULL OR delivery_to = ANY(p_store_codes))
        GROUP BY challan_no, delivery_to, barcode, sal_barcode
    ),
    received AS (
        SELECT
            challan_no,
            barcode,
            sal_barcode,
            SUM(rcv_qty) AS rcv_qty
        FROM store_delivery_receive
        WHERE txn_date <= as_of_date
          AND (p_store_codes IS NULL OR delivery_to = ANY(p_store_codes))
        GROUP BY challan_no, barcode, sal_barcode
    )
    SELECT
        d.store_code,
        d.barcode,
        d.sal_barcode,
        SUM(d.del_qty - COALESCE(r.rcv_qty, 0)) AS pending_stock
    FROM delivered d
    LEFT JOIN received r
        ON r.challan_no  = d.challan_no
       AND r.barcode     = d.barcode
       AND r.sal_barcode = d.sal_barcode
    GROUP BY d.store_code, d.barcode, d.sal_barcode
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_sale_barcode_stock_cycles
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[] DEFAULT NULL::text[])
 RETURNS TABLE(store_code text, barcode text, sal_barcode text, cycle_start date, cycle_end date)
 LANGUAGE sql
AS $function$
    WITH daily AS (
        SELECT store_code, barcode, sal_barcode, txn_date,
               SUM(in_qty - out_qty) AS net_qty
        FROM vw_stock_ledger
        WHERE txn_date <= as_of_date
          AND (p_store_codes IS NULL OR store_code = ANY(p_store_codes))
        GROUP BY store_code, barcode, sal_barcode, txn_date
    ),
    running AS (
        SELECT store_code, barcode, sal_barcode, txn_date,
               SUM(net_qty) OVER (
                   PARTITION BY store_code, barcode, sal_barcode ORDER BY txn_date
               ) AS running_balance
        FROM daily
    ),
    with_prev_next AS (
        SELECT *,
               LAG(running_balance) OVER (PARTITION BY store_code, barcode, sal_barcode ORDER BY txn_date) AS prev_balance,
               LEAD(txn_date) OVER (PARTITION BY store_code, barcode, sal_barcode ORDER BY txn_date) AS next_txn_date,
               LEAD(running_balance) OVER (PARTITION BY store_code, barcode, sal_barcode ORDER BY txn_date) AS next_balance
        FROM running
    ),
    -- A cycle STARTS at any transaction where the balance becomes positive,
    -- having previously been zero-or-below (or being the very first ever).
    cycle_starts AS (
        SELECT store_code, barcode, sal_barcode, txn_date AS cycle_start,
               ROW_NUMBER() OVER (PARTITION BY store_code, barcode, sal_barcode ORDER BY txn_date) AS rn
        FROM with_prev_next
        WHERE running_balance > 0 AND (prev_balance IS NULL OR prev_balance <= 0)
    ),
    -- A cycle ENDS at the next transaction that brings the balance back to
    -- zero-or-below — or stays open through as_of_date if that never happens.
    cycle_ends AS (
        SELECT store_code, barcode, sal_barcode,
               CASE WHEN next_balance IS NULL THEN as_of_date ELSE next_txn_date END AS cycle_end,
               ROW_NUMBER() OVER (PARTITION BY store_code, barcode, sal_barcode ORDER BY txn_date) AS rn
        FROM with_prev_next
        WHERE running_balance > 0 AND (next_balance IS NULL OR next_balance <= 0)
    )
    -- Starts and ends alternate 1:1 in chronological order, so matching row
    -- numbers pairs each start with its correct corresponding end.
    SELECT s.store_code, s.barcode, s.sal_barcode, s.cycle_start, e.cycle_end
    FROM cycle_starts s
    JOIN cycle_ends e
        ON e.store_code = s.store_code AND e.barcode = s.barcode AND e.sal_barcode = s.sal_barcode
       AND e.rn = s.rn
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_sale_barcode_stock_period
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[] DEFAULT NULL::text[])
 RETURNS TABLE(store_code text, barcode text, sal_barcode text, start_date date, end_date date, stock_age_days numeric)
 LANGUAGE sql
AS $function$
    SELECT store_code, barcode, sal_barcode,
           MIN(cycle_start) AS start_date,
           MAX(cycle_end)   AS end_date,
           SUM(cycle_end - cycle_start + 1)::numeric AS stock_age_days
    FROM fn_sale_barcode_stock_cycles(as_of_date, p_store_codes)
    GROUP BY store_code, barcode, sal_barcode
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_stock_qty
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_stock_qty(as_of_date date, p_store_codes text[] DEFAULT NULL::text[])
 RETURNS TABLE(store_code text, barcode text, sal_barcode text, stock_qty numeric)
 LANGUAGE sql
AS $function$
    SELECT store_code, barcode, sal_barcode,
           SUM(in_qty) - SUM(out_qty) AS stock_qty
    FROM vw_stock_ledger
    WHERE txn_date <= as_of_date
      AND (p_store_codes IS NULL OR store_code = ANY(p_store_codes))
    GROUP BY store_code, barcode, sal_barcode
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: fn_user_allowed_categories
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_user_allowed_categories()
 RETURNS text[]
 LANGUAGE sql
 STABLE
AS $function$
    SELECT ARRAY_AGG(category)
    FROM public.user_category_access
    WHERE user_id = auth.uid()
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: get_barcode_wise_report
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_barcode_wise_report(as_of_date date, p_store_codes text[] DEFAULT NULL::text[], p_category text[] DEFAULT NULL::text[], p_sub_category text[] DEFAULT NULL::text[])
 RETURNS TABLE(report_date date, store_name text, barcode text, user_barcode text, category text, sub_category text, item_name text, opening_stock_qty numeric, on_hand_stock_qty numeric, pending_stock_qty numeric, gross_stock_qty numeric, lt_sale_qty numeric, opening_cost_value numeric, on_hand_cost_value numeric, pending_cost_value numeric, gross_cost_value numeric, opening_sal_value numeric, on_hand_sal_value numeric, pending_sal_value numeric, gross_sal_value numeric, stock_age_days numeric)
 LANGUAGE sql
AS $function$
    WITH agg AS (
        SELECT
            r.store_name, r.barcode, r.user_barcode, r.category, r.sub_category, r.item_name,
            SUM(r.opening_stock_qty)  AS opening_stock_qty,
            SUM(r.on_hand_stock_qty)  AS on_hand_stock_qty,
            SUM(r.pending_stock_qty)  AS pending_stock_qty,
            SUM(r.gross_stock_qty)    AS gross_stock_qty,
            SUM(r.lt_sale_qty)        AS lt_sale_qty,
            SUM(r.opening_cost_value) AS opening_cost_value,
            SUM(r.on_hand_cost_value) AS on_hand_cost_value,
            SUM(r.pending_cost_value) AS pending_cost_value,
            SUM(r.gross_cost_value)   AS gross_cost_value,
            SUM(r.opening_sal_value)  AS opening_sal_value,
            SUM(r.on_hand_sal_value)  AS on_hand_sal_value,
            SUM(r.pending_sal_value)  AS pending_sal_value,
            SUM(r.gross_sal_value)    AS gross_sal_value
        FROM get_sale_barcode_wise_report(as_of_date, p_store_codes, p_category, p_sub_category, NULL) r
        GROUP BY r.store_name, r.barcode, r.user_barcode, r.category, r.sub_category, r.item_name
    )
    SELECT
        as_of_date AS report_date,
        a.store_name, a.barcode, a.user_barcode, a.category, a.sub_category, a.item_name,
        a.opening_stock_qty, a.on_hand_stock_qty, a.pending_stock_qty, a.gross_stock_qty,
        a.lt_sale_qty,
        a.opening_cost_value, a.on_hand_cost_value, a.pending_cost_value, a.gross_cost_value,
        a.opening_sal_value, a.on_hand_sal_value, a.pending_sal_value, a.gross_sal_value,
        ba.stock_age_days
    FROM agg a
    JOIN store s ON s.store_name = a.store_name
    LEFT JOIN fn_barcode_stock_age(as_of_date, p_store_codes) ba
        ON ba.store_code = s.store_code AND ba.barcode = a.barcode
    ORDER BY a.store_name, a.barcode
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: get_distinct_categories
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_distinct_categories()
 RETURNS TABLE(category text)
 LANGUAGE sql
AS $function$
    SELECT DISTINCT category
    FROM product_file
    WHERE category IS NOT NULL
      AND (public.fn_user_allowed_categories() IS NULL OR category = ANY(public.fn_user_allowed_categories()))
    ORDER BY category
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: get_distinct_sub_categories
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_distinct_sub_categories()
 RETURNS TABLE(sub_category text)
 LANGUAGE sql
AS $function$
    SELECT DISTINCT sub_category
    FROM product_file
    WHERE sub_category IS NOT NULL
      AND (public.fn_user_allowed_categories() IS NULL OR category = ANY(public.fn_user_allowed_categories()))
    ORDER BY sub_category
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: get_sale_barcode_wise_report
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_sale_barcode_wise_report(as_of_date date, p_store_codes text[] DEFAULT NULL::text[], p_category text[] DEFAULT NULL::text[], p_sub_category text[] DEFAULT NULL::text[], p_search text DEFAULT NULL::text)
 RETURNS TABLE(report_date date, store_name text, barcode text, sal_barcode text, user_barcode text, category text, sub_category text, item_name text, cpu numeric, mrp numeric, opening_stock_qty numeric, on_hand_stock_qty numeric, pending_stock_qty numeric, gross_stock_qty numeric, lt_sale_qty numeric, opening_cost_value numeric, on_hand_cost_value numeric, pending_cost_value numeric, gross_cost_value numeric, opening_sal_value numeric, on_hand_sal_value numeric, pending_sal_value numeric, gross_sal_value numeric, stock_age_days numeric)
 LANGUAGE sql
AS $function$
    WITH batch AS (
        SELECT
            COALESCE(o.store_code, h.store_code, p.store_code)      AS store_code,
            COALESCE(o.barcode,    h.barcode,    p.barcode)          AS barcode,
            COALESCE(o.sal_barcode, h.sal_barcode, p.sal_barcode)    AS sal_barcode,
            COALESCE(o.stock_qty, 0)   AS opening_qty,
            COALESCE(h.stock_qty, 0)   AS on_hand_qty,
            COALESCE(p.pending_stock, 0) AS pending_qty
        FROM fn_stock_qty(as_of_date - 1, p_store_codes) o
        FULL OUTER JOIN fn_stock_qty(as_of_date, p_store_codes) h
            ON o.store_code = h.store_code AND o.barcode = h.barcode AND o.sal_barcode = h.sal_barcode
        FULL OUTER JOIN fn_pending_stock(as_of_date, p_store_codes) p
            ON COALESCE(o.store_code, h.store_code) = p.store_code
           AND COALESCE(o.barcode, h.barcode) = p.barcode
           AND COALESCE(o.sal_barcode, h.sal_barcode) = p.sal_barcode
    ),
    lt_sale AS (
        SELECT store_code, barcode, sal_barcode,
               SUM(sale_qty) - SUM(rtn_qty) AS lt_sale_qty
        FROM sale
        WHERE txn_date <= as_of_date
          AND (p_store_codes IS NULL OR store_code = ANY(p_store_codes))
        GROUP BY store_code, barcode, sal_barcode
    ),
    store_has_history AS (
        SELECT DISTINCT store_code, barcode
        FROM vw_stock_ledger
        WHERE (in_qty <> 0 OR out_qty <> 0)
          AND txn_date <= as_of_date
          AND (p_store_codes IS NULL OR store_code = ANY(p_store_codes))
    )
    SELECT
        as_of_date AS report_date,
        s.store_name,
        b.barcode,
        b.sal_barcode,
        pf.user_barcode,
        pf.category,
        pf.sub_category,
        pf.item_name,
        ps.cpu,
        ps.mrp,
        b.opening_qty,
        b.on_hand_qty,
        b.pending_qty,
        b.on_hand_qty + b.pending_qty                            AS gross_stock_qty,
        COALESCE(ls.lt_sale_qty, 0)                               AS lt_sale_qty,
        b.opening_qty * ps.cpu                                    AS opening_cost_value,
        b.on_hand_qty * ps.cpu                                    AS on_hand_cost_value,
        b.pending_qty * ps.cpu                                    AS pending_cost_value,
        (b.on_hand_qty + b.pending_qty) * ps.cpu                  AS gross_cost_value,
        b.opening_qty * ps.mrp                                    AS opening_sal_value,
        b.on_hand_qty * ps.mrp                                    AS on_hand_sal_value,
        b.pending_qty * ps.mrp                                    AS pending_sal_value,
        (b.on_hand_qty + b.pending_qty) * ps.mrp                  AS gross_sal_value,
        sp.stock_age_days
    FROM batch b
    JOIN store s         ON s.store_code = b.store_code
    JOIN product_file pf ON pf.barcode   = b.barcode
    LEFT JOIN product_stock ps ON ps.sal_barcode = b.sal_barcode
    LEFT JOIN fn_sale_barcode_stock_period(as_of_date, p_store_codes) sp
        ON sp.store_code = b.store_code AND sp.barcode = b.barcode AND sp.sal_barcode = b.sal_barcode
    LEFT JOIN lt_sale ls
        ON ls.store_code = b.store_code AND ls.barcode = b.barcode AND ls.sal_barcode = b.sal_barcode
    WHERE (p_store_codes IS NULL OR b.store_code = ANY(p_store_codes))
      AND (p_category IS NULL OR pf.category = ANY(p_category))
      AND (p_sub_category IS NULL OR pf.sub_category = ANY(p_sub_category))
      AND (public.fn_user_allowed_categories() IS NULL OR pf.category = ANY(public.fn_user_allowed_categories()))
      AND (p_search IS NULL OR p_search = '' OR
           b.barcode ILIKE '%' || p_search || '%' OR
           b.sal_barcode ILIKE '%' || p_search || '%' OR
           pf.user_barcode ILIKE '%' || p_search || '%')
      AND (
            b.store_code = '100010001'
            OR EXISTS (
                SELECT 1 FROM store_has_history hh
                WHERE hh.store_code = b.store_code AND hh.barcode = b.barcode
            )
          )
    ORDER BY s.store_name, b.barcode, b.sal_barcode
$function$

;

-- ----------------------------------------------------------------------------
-- FUNCTION: get_store_wise_report
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_store_wise_report(as_of_date date, p_store_codes text[] DEFAULT NULL::text[], p_category text[] DEFAULT NULL::text[], p_sub_category text[] DEFAULT NULL::text[])
 RETURNS TABLE(store_name text, opening_stock_qty numeric, on_hand_stock_qty numeric, pending_stock_qty numeric, gross_stock_qty numeric, lt_sale_qty numeric, opening_cost_value numeric, on_hand_cost_value numeric, pending_cost_value numeric, gross_cost_value numeric, opening_sal_value numeric, on_hand_sal_value numeric, pending_sal_value numeric, gross_sal_value numeric)
 LANGUAGE sql
AS $function$
    SELECT
        r.store_name,
        SUM(r.opening_stock_qty)  AS opening_stock_qty,
        SUM(r.on_hand_stock_qty)  AS on_hand_stock_qty,
        SUM(r.pending_stock_qty)  AS pending_stock_qty,
        SUM(r.gross_stock_qty)    AS gross_stock_qty,
        SUM(r.lt_sale_qty)        AS lt_sale_qty,
        SUM(r.opening_cost_value) AS opening_cost_value,
        SUM(r.on_hand_cost_value) AS on_hand_cost_value,
        SUM(r.pending_cost_value) AS pending_cost_value,
        SUM(r.gross_cost_value)   AS gross_cost_value,
        SUM(r.opening_sal_value)  AS opening_sal_value,
        SUM(r.on_hand_sal_value)  AS on_hand_sal_value,
        SUM(r.pending_sal_value)  AS pending_sal_value,
        SUM(r.gross_sal_value)    AS gross_sal_value
    FROM get_sale_barcode_wise_report(as_of_date, p_store_codes, p_category, p_sub_category, NULL) r
    GROUP BY r.store_name
    ORDER BY r.store_name
$function$

;

