--
-- PostgreSQL database dump
--

\restrict 0bzHSo7ro2zCEbl0LLvnTZIkG0r2jJQPApAcTr5E3X2ZNHdsKS3tbvGgm8yZt7X

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.11 (Ubuntu 17.11-1.pgdg24.04+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP POLICY IF EXISTS "store select by user access" ON public.store;
DROP POLICY IF EXISTS "select own store access" ON public.user_store_access;
DROP POLICY IF EXISTS "select own category access" ON public.user_category_access;
DROP POLICY IF EXISTS allow_authenticated_read ON public.sync_log;
DROP POLICY IF EXISTS allow_authenticated_read ON public.store_dml;
DROP POLICY IF EXISTS allow_authenticated_read ON public.store_delivery_receive;
DROP POLICY IF EXISTS allow_authenticated_read ON public.store_delivery_details;
DROP POLICY IF EXISTS allow_authenticated_read ON public.sale;
DROP POLICY IF EXISTS allow_authenticated_read ON public.purchase_return_details;
DROP POLICY IF EXISTS allow_authenticated_read ON public.purchase_rcv_details;
DROP POLICY IF EXISTS allow_authenticated_read ON public.product_stock;
DROP POLICY IF EXISTS allow_authenticated_read ON public.product_file;
DROP POLICY IF EXISTS allow_authenticated_read ON public.inv_tracking_summary;
ALTER TABLE IF EXISTS ONLY public.user_store_access DROP CONSTRAINT IF EXISTS user_store_access_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_category_access DROP CONSTRAINT IF EXISTS user_category_access_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.admin_users DROP CONSTRAINT IF EXISTS admin_users_user_id_fkey;
DROP INDEX IF EXISTS public.uq_sync_log_table_name;
DROP INDEX IF EXISTS public.uq_store_store_code;
DROP INDEX IF EXISTS public.uq_product_stock_sal_barcode;
DROP INDEX IF EXISTS public.uq_product_file_barcode;
DROP INDEX IF EXISTS public.store_dml_staging_store_code_barcode_sal_barcode_txn_date_idx;
DROP INDEX IF EXISTS public.store_delivery_receive_stagin_delivery_to_barcode_sal_barco_idx;
DROP INDEX IF EXISTS public.store_delivery_receive_stagin_challan_no_barcode_sal_barcod_idx;
DROP INDEX IF EXISTS public.store_delivery_details_stagin_delivery_from_barcode_sal_bar_idx;
DROP INDEX IF EXISTS public.store_delivery_details_stagin_challan_no_barcode_sal_barcod_idx;
DROP INDEX IF EXISTS public.sale_staging_store_code_barcode_sal_barcode_txn_date_idx;
DROP INDEX IF EXISTS public.purchase_return_details_stagi_store_code_barcode_sal_barcod_idx;
DROP INDEX IF EXISTS public.purchase_rcv_details_staging_store_code_barcode_sal_barcode_idx;
DROP INDEX IF EXISTS public.product_stock_staging_barcode_idx;
DROP INDEX IF EXISTS public.ix_sale_lookup;
DROP INDEX IF EXISTS public.ix_pur_rtn_lookup;
DROP INDEX IF EXISTS public.ix_pur_rcv_lookup;
DROP INDEX IF EXISTS public.ix_product_stock_barcode;
DROP INDEX IF EXISTS public.ix_inv_tracking_lookup;
DROP INDEX IF EXISTS public.ix_dml_lookup;
DROP INDEX IF EXISTS public.ix_delivery_receive_lookup;
DROP INDEX IF EXISTS public.ix_delivery_receive_challan;
DROP INDEX IF EXISTS public.ix_delivery_details_lookup;
DROP INDEX IF EXISTS public.ix_delivery_details_challan;
DROP INDEX IF EXISTS public.inv_tracking_summary_staging_store_code_barcode_sal_barcode_idx;
DROP INDEX IF EXISTS public.idx_user_category_access_user_id;
DROP INDEX IF EXISTS public.idx_store_store_code;
DROP INDEX IF EXISTS public.idx_store_dml_store_date;
DROP INDEX IF EXISTS public.idx_store_dml_store_barcode_date;
DROP INDEX IF EXISTS public.idx_store_dml_report;
DROP INDEX IF EXISTS public.idx_store_dml_date_report;
DROP INDEX IF EXISTS public.idx_store_delivery_receive_to_pending;
DROP INDEX IF EXISTS public.idx_store_delivery_receive_to_date;
DROP INDEX IF EXISTS public.idx_store_delivery_receive_date_pending;
DROP INDEX IF EXISTS public.idx_store_delivery_receive_challan;
DROP INDEX IF EXISTS public.idx_store_delivery_details_to_pending;
DROP INDEX IF EXISTS public.idx_store_delivery_details_from_report;
DROP INDEX IF EXISTS public.idx_store_delivery_details_from_date;
DROP INDEX IF EXISTS public.idx_store_delivery_details_date_pending;
DROP INDEX IF EXISTS public.idx_store_delivery_details_date_from;
DROP INDEX IF EXISTS public.idx_store_delivery_details_challan;
DROP INDEX IF EXISTS public.idx_sale_store_date;
DROP INDEX IF EXISTS public.idx_sale_store_barcode_date;
DROP INDEX IF EXISTS public.idx_sale_report;
DROP INDEX IF EXISTS public.idx_sale_date_report;
DROP INDEX IF EXISTS public.idx_purchase_return_store_barcode_date;
DROP INDEX IF EXISTS public.idx_purchase_return_details_store_date;
DROP INDEX IF EXISTS public.idx_purchase_return_details_report;
DROP INDEX IF EXISTS public.idx_purchase_return_details_date_report;
DROP INDEX IF EXISTS public.idx_purchase_rcv_store_barcode_date;
DROP INDEX IF EXISTS public.idx_purchase_rcv_details_store_date;
DROP INDEX IF EXISTS public.idx_purchase_rcv_details_report;
DROP INDEX IF EXISTS public.idx_purchase_rcv_details_date_report;
DROP INDEX IF EXISTS public.idx_product_stock_sal_barcode_report;
DROP INDEX IF EXISTS public.idx_product_stock_sal_barcode;
DROP INDEX IF EXISTS public.idx_product_file_category;
DROP INDEX IF EXISTS public.idx_product_file_barcode_report;
DROP INDEX IF EXISTS public.idx_product_file_barcode;
DROP INDEX IF EXISTS public.idx_inv_tracking_summary_store_date;
DROP INDEX IF EXISTS public.idx_inv_tracking_summary_report;
DROP INDEX IF EXISTS public.idx_inv_tracking_summary_date_report;
DROP INDEX IF EXISTS public.idx_inv_tracking_store_barcode_date;
DROP INDEX IF EXISTS public.idx_delivery_receive_to_barcode_date;
DROP INDEX IF EXISTS public.idx_delivery_details_from_barcode_date;
ALTER TABLE IF EXISTS ONLY public.user_store_access DROP CONSTRAINT IF EXISTS user_store_access_pkey;
ALTER TABLE IF EXISTS ONLY public.user_category_access DROP CONSTRAINT IF EXISTS user_category_access_pkey;
ALTER TABLE IF EXISTS ONLY public.sync_log DROP CONSTRAINT IF EXISTS sync_log_pkey;
ALTER TABLE IF EXISTS ONLY public.store_staging DROP CONSTRAINT IF EXISTS store_staging_pkey;
ALTER TABLE IF EXISTS ONLY public.store DROP CONSTRAINT IF EXISTS store_pkey;
ALTER TABLE IF EXISTS ONLY public.product_stock_staging DROP CONSTRAINT IF EXISTS product_stock_staging_pkey;
ALTER TABLE IF EXISTS ONLY public.product_stock DROP CONSTRAINT IF EXISTS product_stock_pkey;
ALTER TABLE IF EXISTS ONLY public.product_file_staging DROP CONSTRAINT IF EXISTS product_file_staging_pkey;
ALTER TABLE IF EXISTS ONLY public.product_file DROP CONSTRAINT IF EXISTS product_file_pkey;
ALTER TABLE IF EXISTS ONLY public.admin_users DROP CONSTRAINT IF EXISTS admin_users_pkey;
DROP VIEW IF EXISTS public.vw_stock_ledger;
DROP TABLE IF EXISTS public.user_store_access;
DROP TABLE IF EXISTS public.user_category_access;
DROP TABLE IF EXISTS public.sync_log;
DROP TABLE IF EXISTS public.store_staging;
DROP TABLE IF EXISTS public.store_dml_staging;
DROP TABLE IF EXISTS public.store_dml;
DROP TABLE IF EXISTS public.store_delivery_receive_staging;
DROP TABLE IF EXISTS public.store_delivery_receive;
DROP TABLE IF EXISTS public.store_delivery_details_staging;
DROP TABLE IF EXISTS public.store_delivery_details;
DROP TABLE IF EXISTS public.store;
DROP TABLE IF EXISTS public.sale_staging;
DROP TABLE IF EXISTS public.sale;
DROP TABLE IF EXISTS public.purchase_return_details_staging;
DROP TABLE IF EXISTS public.purchase_return_details;
DROP TABLE IF EXISTS public.purchase_rcv_details_staging;
DROP TABLE IF EXISTS public.purchase_rcv_details;
DROP TABLE IF EXISTS public.product_stock_staging;
DROP TABLE IF EXISTS public.product_stock;
DROP TABLE IF EXISTS public.product_file_staging;
DROP TABLE IF EXISTS public.product_file;
DROP TABLE IF EXISTS public.inv_tracking_summary_staging;
DROP TABLE IF EXISTS public.inv_tracking_summary;
DROP TABLE IF EXISTS public.admin_users;
DROP FUNCTION IF EXISTS public.get_store_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]);
DROP FUNCTION IF EXISTS public.get_sale_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[], p_search text);
DROP FUNCTION IF EXISTS public.get_distinct_sub_categories_for_categories(p_category text[]);
DROP FUNCTION IF EXISTS public.get_distinct_sub_categories();
DROP FUNCTION IF EXISTS public.get_distinct_categories();
DROP FUNCTION IF EXISTS public.get_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]);
DROP FUNCTION IF EXISTS public.fn_validate_report_master_integrity();
DROP FUNCTION IF EXISTS public.fn_user_allowed_stores();
DROP FUNCTION IF EXISTS public.fn_user_allowed_categories();
DROP FUNCTION IF EXISTS public.fn_stock_qty(as_of_date date, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.fn_stock_opening_onhand(as_of_date date, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.fn_pending_stock(as_of_date date, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.fn_is_admin();
DROP FUNCTION IF EXISTS public.fn_effective_store_codes(p_requested text[]);
DROP FUNCTION IF EXISTS public.fn_barcode_stock_age(as_of_date date, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.admin_set_user_stores(p_user_id uuid, p_store_codes text[]);
DROP FUNCTION IF EXISTS public.admin_set_user_categories(p_user_id uuid, p_categories text[]);
DROP FUNCTION IF EXISTS public.admin_list_users();
DROP FUNCTION IF EXISTS public.admin_get_store_access();
DROP FUNCTION IF EXISTS public.admin_get_category_access();
DROP FUNCTION IF EXISTS public.admin_get_all_stores();
DROP FUNCTION IF EXISTS public.admin_get_all_categories();
DROP SCHEMA IF EXISTS public;
--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA public;


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- Name: admin_get_all_categories(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_get_all_categories() RETURNS TABLE(category text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


--
-- Name: admin_get_all_stores(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_get_all_stores() RETURNS TABLE(store_code text, store_name text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT
        s.store_code,
        s.store_name
    FROM public.store s
    ORDER BY
        s.store_name,
        s.store_code;
END;
$$;


--
-- Name: admin_get_category_access(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_get_category_access() RETURNS TABLE(user_id uuid, category text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT uca.user_id, uca.category
    FROM public.user_category_access uca;
END;
$$;


--
-- Name: admin_get_store_access(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_get_store_access() RETURNS TABLE(user_id uuid, store_code text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT
        usa.user_id,
        usa.store_code
    FROM public.user_store_access usa
    ORDER BY
        usa.user_id,
        usa.store_code;
END;
$$;


--
-- Name: admin_list_users(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_list_users() RETURNS TABLE(user_id uuid, email text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    RETURN QUERY
    SELECT u.id, u.email::text
    FROM auth.users u
    ORDER BY u.email;
END;
$$;


--
-- Name: admin_set_user_categories(uuid, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_set_user_categories(p_user_id uuid, p_categories text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    DELETE FROM public.user_category_access
    WHERE user_id = p_user_id;

    -- NULL / empty means unrestricted.
    IF p_categories IS NOT NULL
       AND array_length(p_categories, 1) > 0
    THEN

        IF EXISTS (
            SELECT 1
            FROM unnest(p_categories)
                AS requested(category)
            WHERE requested.category IS NULL
               OR NOT EXISTS (
                    SELECT 1
                    FROM public.product_file pf
                    WHERE pf.category = requested.category
               )
        ) THEN
            RAISE EXCEPTION
                'One or more selected categories do not exist in the current product catalog.';
        END IF;

        INSERT INTO public.user_category_access (
            user_id,
            category
        )
        SELECT DISTINCT
            p_user_id,
            requested.category
        FROM unnest(p_categories)
            AS requested(category)
        WHERE requested.category IS NOT NULL;
    END IF;
END;
$$;


--
-- Name: admin_set_user_stores(uuid, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_set_user_stores(p_user_id uuid, p_store_codes text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF NOT public.fn_is_admin() THEN
        RAISE EXCEPTION 'Not authorized';
    END IF;

    DELETE FROM public.user_store_access
    WHERE user_id = p_user_id;

    -- NULL / empty means unrestricted.
    IF p_store_codes IS NOT NULL
       AND array_length(p_store_codes, 1) > 0
    THEN

        IF EXISTS (
            SELECT 1
            FROM unnest(p_store_codes)
                AS requested(store_code)
            WHERE requested.store_code IS NULL
               OR NOT EXISTS (
                    SELECT 1
                    FROM public.store s
                    WHERE s.store_code = requested.store_code
               )
        ) THEN
            RAISE EXCEPTION
                'One or more selected stores do not exist in the current store master.';
        END IF;

        INSERT INTO public.user_store_access (
            user_id,
            store_code
        )
        SELECT DISTINCT
            p_user_id,
            requested.store_code
        FROM unnest(p_store_codes)
            AS requested(store_code)
        WHERE requested.store_code IS NOT NULL;
    END IF;
END;
$$;


--
-- Name: fn_barcode_stock_age(date, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_barcode_stock_age(as_of_date date, p_store_codes text[] DEFAULT NULL::text[]) RETURNS TABLE(store_code text, barcode text, stock_age_days numeric)
    LANGUAGE sql
    AS $$
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
$$;


--
-- Name: fn_effective_store_codes(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_effective_store_codes(p_requested text[] DEFAULT NULL::text[]) RETURNS text[]
    LANGUAGE sql STABLE
    AS $$
    WITH a AS (
        SELECT public.fn_user_allowed_stores() AS allowed
    )
    SELECT
        CASE
            WHEN a.allowed IS NULL
                THEN p_requested

            WHEN p_requested IS NULL
                THEN a.allowed

            ELSE ARRAY(
                SELECT x
                FROM unnest(p_requested) AS x
                WHERE x = ANY(a.allowed)
                ORDER BY x
            )
        END
    FROM a
$$;


--
-- Name: fn_is_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_is_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
    SELECT EXISTS (SELECT 1 FROM public.admin_users WHERE user_id = auth.uid())
$$;


--
-- Name: fn_pending_stock(date, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_pending_stock(as_of_date date, p_store_codes text[] DEFAULT NULL::text[]) RETURNS TABLE(store_code text, barcode text, sal_barcode text, pending_stock numeric)
    LANGUAGE sql STABLE
    AS $$
    WITH delivered AS (
        SELECT
            challan_no,
            delivery_to AS store_code,
            barcode,
            sal_barcode,
            SUM(del_qty) AS del_qty
        FROM public.store_delivery_details
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
        FROM public.store_delivery_receive
        WHERE txn_date <= as_of_date
          AND (p_store_codes IS NULL OR delivery_to = ANY(p_store_codes))
        GROUP BY challan_no, barcode, sal_barcode
    ),
    per_challan AS (
        SELECT
            d.store_code,
            d.barcode,
            d.sal_barcode,
            GREATEST(d.del_qty - COALESCE(r.rcv_qty, 0), 0) AS pending_qty
        FROM delivered d
        LEFT JOIN received r
          ON r.challan_no = d.challan_no
         AND r.barcode = d.barcode
         AND r.sal_barcode = d.sal_barcode
    )
    SELECT
        store_code,
        barcode,
        sal_barcode,
        SUM(pending_qty) AS pending_stock
    FROM per_challan
    GROUP BY store_code, barcode, sal_barcode;
$$;


--
-- Name: fn_sale_barcode_stock_cycles(date, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[] DEFAULT NULL::text[]) RETURNS TABLE(store_code text, barcode text, sal_barcode text, cycle_start date, cycle_end date)
    LANGUAGE sql
    AS $$
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
$$;


--
-- Name: fn_sale_barcode_stock_period(date, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[] DEFAULT NULL::text[]) RETURNS TABLE(store_code text, barcode text, sal_barcode text, first_stock_date date, last_stock_date date, stock_age_days numeric)
    LANGUAGE sql
    AS $$
    SELECT
        store_code,
        barcode,
        sal_barcode,
        MIN(cycle_start) AS first_stock_date,
        MAX(cycle_end)   AS last_stock_date,
        SUM(
            cycle_end - cycle_start + 1
        )::numeric AS stock_age_days
    FROM public.fn_sale_barcode_stock_cycles(
        as_of_date,
        p_store_codes
    )
    GROUP BY
        store_code,
        barcode,
        sal_barcode
$$;


--
-- Name: fn_stock_opening_onhand(date, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_stock_opening_onhand(as_of_date date, p_store_codes text[] DEFAULT NULL::text[]) RETURNS TABLE(store_code text, barcode text, sal_barcode text, opening_qty numeric, onhand_qty numeric)
    LANGUAGE sql
    AS $$
    SELECT
        store_code,
        barcode,
        sal_barcode,
        COALESCE(SUM(in_qty)  FILTER (WHERE txn_date <= as_of_date - 1), 0)
            - COALESCE(SUM(out_qty) FILTER (WHERE txn_date <= as_of_date - 1), 0) AS opening_qty,
        COALESCE(SUM(in_qty)  FILTER (WHERE txn_date <= as_of_date), 0)
            - COALESCE(SUM(out_qty) FILTER (WHERE txn_date <= as_of_date), 0)     AS onhand_qty
    FROM vw_stock_ledger
    WHERE txn_date <= as_of_date
      AND (p_store_codes IS NULL OR store_code = ANY(p_store_codes))
    GROUP BY store_code, barcode, sal_barcode
$$;


--
-- Name: fn_stock_qty(date, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_stock_qty(as_of_date date, p_store_codes text[] DEFAULT NULL::text[]) RETURNS TABLE(store_code text, barcode text, sal_barcode text, stock_qty numeric)
    LANGUAGE sql
    AS $$
    SELECT store_code, barcode, sal_barcode,
           SUM(in_qty) - SUM(out_qty) AS stock_qty
    FROM vw_stock_ledger
    WHERE txn_date <= as_of_date
      AND (p_store_codes IS NULL OR store_code = ANY(p_store_codes))
    GROUP BY store_code, barcode, sal_barcode
$$;


--
-- Name: fn_user_allowed_categories(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_user_allowed_categories() RETURNS text[]
    LANGUAGE sql STABLE
    AS $$
    SELECT ARRAY_AGG(
        uca.category
        ORDER BY uca.category
    )
    FROM public.user_category_access uca
    WHERE uca.user_id = auth.uid()
      AND EXISTS (
          SELECT 1
          FROM public.product_file pf
          WHERE pf.category = uca.category
      )
$$;


--
-- Name: fn_user_allowed_stores(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_user_allowed_stores() RETURNS text[]
    LANGUAGE sql STABLE
    AS $$
    SELECT ARRAY_AGG(
        usa.store_code
        ORDER BY usa.store_code
    )
    FROM public.user_store_access usa
    WHERE usa.user_id = auth.uid()
$$;


--
-- Name: fn_validate_report_master_integrity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_validate_report_master_integrity() RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.store
        WHERE store_code IS NOT NULL
        GROUP BY store_code
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Report blocked: duplicate store_code exists in store master.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.product_file
        WHERE barcode IS NOT NULL
        GROUP BY barcode
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Report blocked: duplicate barcode exists in product_file master.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.product_stock
        WHERE sal_barcode IS NOT NULL
        GROUP BY sal_barcode
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION 'Report blocked: duplicate sal_barcode exists in product_stock master.';
    END IF;

    RETURN TRUE;
END;
$$;


--
-- Name: get_barcode_wise_report(date, text[], text[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_barcode_wise_report(as_of_date date, p_store_codes text[] DEFAULT NULL::text[], p_category text[] DEFAULT NULL::text[], p_sub_category text[] DEFAULT NULL::text[]) RETURNS TABLE(report_date date, store_name text, barcode text, user_barcode text, category text, sub_category text, item_name text, opening_stock_qty numeric, on_hand_stock_qty numeric, pending_stock_qty numeric, gross_stock_qty numeric, lt_sale_qty numeric, opening_cost_value numeric, on_hand_cost_value numeric, pending_cost_value numeric, gross_cost_value numeric, opening_sal_value numeric, on_hand_sal_value numeric, pending_sal_value numeric, gross_sal_value numeric, stock_age_days numeric)
    LANGUAGE sql
    AS $$
    WITH batch AS (
        SELECT
            COALESCE(so.store_code, p.store_code)      AS store_code,
            COALESCE(so.barcode,    p.barcode)          AS barcode,
            COALESCE(so.sal_barcode, p.sal_barcode)    AS sal_barcode,
            COALESCE(so.opening_qty, 0)   AS opening_qty,
            COALESCE(so.onhand_qty, 0)    AS on_hand_qty,
            COALESCE(p.pending_stock, 0)  AS pending_qty
        FROM fn_stock_opening_onhand(as_of_date, p_store_codes) so
        FULL OUTER JOIN fn_pending_stock(as_of_date, p_store_codes) p
            ON so.store_code = p.store_code AND so.barcode = p.barcode AND so.sal_barcode = p.sal_barcode
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
    ),
    priced AS (
        SELECT
            s.store_name, b.barcode, pf.user_barcode, pf.category, pf.sub_category, pf.item_name,
            b.opening_qty,
            b.on_hand_qty,
            b.pending_qty,
            b.on_hand_qty + b.pending_qty                AS gross_qty,
            COALESCE(ls.lt_sale_qty, 0)                    AS lt_sale_qty,
            b.opening_qty * ps.cpu                         AS opening_cost_value,
            b.on_hand_qty * ps.cpu                         AS on_hand_cost_value,
            b.pending_qty * ps.cpu                         AS pending_cost_value,
            (b.on_hand_qty + b.pending_qty) * ps.cpu       AS gross_cost_value,
            b.opening_qty * ps.mrp                         AS opening_sal_value,
            b.on_hand_qty * ps.mrp                         AS on_hand_sal_value,
            b.pending_qty * ps.mrp                         AS pending_sal_value,
            (b.on_hand_qty + b.pending_qty) * ps.mrp       AS gross_sal_value
        FROM batch b
        JOIN store s         ON s.store_code = b.store_code
        JOIN product_file pf ON pf.barcode   = b.barcode
        LEFT JOIN product_stock ps ON ps.sal_barcode = b.sal_barcode
        LEFT JOIN lt_sale ls
            ON ls.store_code = b.store_code AND ls.barcode = b.barcode AND ls.sal_barcode = b.sal_barcode
        WHERE (p_store_codes IS NULL OR b.store_code = ANY(p_store_codes))
          AND (p_category IS NULL OR pf.category = ANY(p_category))
          AND (p_sub_category IS NULL OR pf.sub_category = ANY(p_sub_category))
          AND (public.fn_user_allowed_categories() IS NULL OR pf.category = ANY(public.fn_user_allowed_categories()))
          AND (
                b.store_code = '100010001'
                OR EXISTS (
                    SELECT 1 FROM store_has_history hh
                    WHERE hh.store_code = b.store_code AND hh.barcode = b.barcode
                )
              )
    ),
    agg AS (
        SELECT
            store_name, barcode, user_barcode, category, sub_category, item_name,
            SUM(opening_qty)         AS opening_stock_qty,
            SUM(on_hand_qty)         AS on_hand_stock_qty,
            SUM(pending_qty)         AS pending_stock_qty,
            SUM(gross_qty)           AS gross_stock_qty,
            SUM(lt_sale_qty)         AS lt_sale_qty,
            SUM(opening_cost_value)  AS opening_cost_value,
            SUM(on_hand_cost_value)  AS on_hand_cost_value,
            SUM(pending_cost_value)  AS pending_cost_value,
            SUM(gross_cost_value)    AS gross_cost_value,
            SUM(opening_sal_value)   AS opening_sal_value,
            SUM(on_hand_sal_value)   AS on_hand_sal_value,
            SUM(pending_sal_value)   AS pending_sal_value,
            SUM(gross_sal_value)     AS gross_sal_value
        FROM priced
        GROUP BY store_name, barcode, user_barcode, category, sub_category, item_name
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
$$;


--
-- Name: get_distinct_categories(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_distinct_categories() RETURNS TABLE(category text)
    LANGUAGE sql
    AS $$

    SELECT DISTINCT
        pf.category

    FROM public.product_file pf

    WHERE pf.category IS NOT NULL

      AND (
          public.fn_user_allowed_categories() IS NULL
          OR pf.category = ANY(
              public.fn_user_allowed_categories()
          )
      )

    ORDER BY
        pf.category

$$;


--
-- Name: get_distinct_sub_categories(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_distinct_sub_categories() RETURNS TABLE(sub_category text)
    LANGUAGE sql
    AS $$

    SELECT DISTINCT
        pf.sub_category

    FROM public.product_file pf

    WHERE pf.sub_category IS NOT NULL

      AND (
          public.fn_user_allowed_categories() IS NULL
          OR pf.category = ANY(
              public.fn_user_allowed_categories()
          )
      )

    ORDER BY
        pf.sub_category

$$;


--
-- Name: get_distinct_sub_categories_for_categories(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_distinct_sub_categories_for_categories(p_category text[] DEFAULT NULL::text[]) RETURNS TABLE(sub_category text)
    LANGUAGE sql
    AS $$
    SELECT DISTINCT sub_category
    FROM product_file
    WHERE sub_category IS NOT NULL
      AND (p_category IS NULL OR category = ANY(p_category))
      AND (public.fn_user_allowed_categories() IS NULL OR category = ANY(public.fn_user_allowed_categories()))
    ORDER BY sub_category
$$;


--
-- Name: get_sale_barcode_wise_report(date, text[], text[], text[], text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_sale_barcode_wise_report(as_of_date date, p_store_codes text[] DEFAULT NULL::text[], p_category text[] DEFAULT NULL::text[], p_sub_category text[] DEFAULT NULL::text[], p_search text DEFAULT NULL::text) RETURNS TABLE(report_date date, store_name text, barcode text, sal_barcode text, user_barcode text, category text, sub_category text, item_name text, cpu numeric, mrp numeric, opening_stock_qty numeric, on_hand_stock_qty numeric, pending_stock_qty numeric, gross_stock_qty numeric, lt_sale_qty numeric, opening_cost_value numeric, on_hand_cost_value numeric, pending_cost_value numeric, gross_cost_value numeric, opening_sal_value numeric, on_hand_sal_value numeric, pending_sal_value numeric, gross_sal_value numeric, stock_age_days numeric)
    LANGUAGE sql
    AS $$
    WITH batch AS (
        SELECT
            COALESCE(so.store_code, p.store_code)      AS store_code,
            COALESCE(so.barcode,    p.barcode)          AS barcode,
            COALESCE(so.sal_barcode, p.sal_barcode)    AS sal_barcode,
            COALESCE(so.opening_qty, 0)   AS opening_qty,
            COALESCE(so.onhand_qty, 0)    AS on_hand_qty,
            COALESCE(p.pending_stock, 0)  AS pending_qty
        FROM fn_stock_opening_onhand(as_of_date, p_store_codes) so
        FULL OUTER JOIN fn_pending_stock(as_of_date, p_store_codes) p
            ON so.store_code = p.store_code AND so.barcode = p.barcode AND so.sal_barcode = p.sal_barcode
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
$$;


--
-- Name: get_store_wise_report(date, text[], text[], text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_store_wise_report(as_of_date date, p_store_codes text[] DEFAULT NULL::text[], p_category text[] DEFAULT NULL::text[], p_sub_category text[] DEFAULT NULL::text[]) RETURNS TABLE(store_name text, opening_stock_qty numeric, on_hand_stock_qty numeric, pending_stock_qty numeric, gross_stock_qty numeric, lt_sale_qty numeric, opening_cost_value numeric, on_hand_cost_value numeric, pending_cost_value numeric, gross_cost_value numeric, opening_sal_value numeric, on_hand_sal_value numeric, pending_sal_value numeric, gross_sal_value numeric)
    LANGUAGE sql
    AS $$
    WITH batch AS (
        SELECT
            COALESCE(so.store_code, p.store_code)      AS store_code,
            COALESCE(so.barcode,    p.barcode)          AS barcode,
            COALESCE(so.sal_barcode, p.sal_barcode)    AS sal_barcode,
            COALESCE(so.opening_qty, 0)   AS opening_qty,
            COALESCE(so.onhand_qty, 0)    AS on_hand_qty,
            COALESCE(p.pending_stock, 0)  AS pending_qty
        FROM fn_stock_opening_onhand(as_of_date, p_store_codes) so
        FULL OUTER JOIN fn_pending_stock(as_of_date, p_store_codes) p
            ON so.store_code = p.store_code AND so.barcode = p.barcode AND so.sal_barcode = p.sal_barcode
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
    ),
    priced AS (
        SELECT
            s.store_name,
            b.opening_qty,
            b.on_hand_qty,
            b.pending_qty,
            b.on_hand_qty + b.pending_qty                AS gross_qty,
            COALESCE(ls.lt_sale_qty, 0)                    AS lt_sale_qty,
            b.opening_qty * ps.cpu                         AS opening_cost_value,
            b.on_hand_qty * ps.cpu                         AS on_hand_cost_value,
            b.pending_qty * ps.cpu                         AS pending_cost_value,
            (b.on_hand_qty + b.pending_qty) * ps.cpu       AS gross_cost_value,
            b.opening_qty * ps.mrp                         AS opening_sal_value,
            b.on_hand_qty * ps.mrp                         AS on_hand_sal_value,
            b.pending_qty * ps.mrp                         AS pending_sal_value,
            (b.on_hand_qty + b.pending_qty) * ps.mrp       AS gross_sal_value
        FROM batch b
        JOIN store s         ON s.store_code = b.store_code
        JOIN product_file pf ON pf.barcode   = b.barcode
        LEFT JOIN product_stock ps ON ps.sal_barcode = b.sal_barcode
        LEFT JOIN lt_sale ls
            ON ls.store_code = b.store_code AND ls.barcode = b.barcode AND ls.sal_barcode = b.sal_barcode
        WHERE (p_store_codes IS NULL OR b.store_code = ANY(p_store_codes))
          AND (p_category IS NULL OR pf.category = ANY(p_category))
          AND (p_sub_category IS NULL OR pf.sub_category = ANY(p_sub_category))
          AND (public.fn_user_allowed_categories() IS NULL OR pf.category = ANY(public.fn_user_allowed_categories()))
          AND (
                b.store_code = '100010001'
                OR EXISTS (
                    SELECT 1 FROM store_has_history hh
                    WHERE hh.store_code = b.store_code AND hh.barcode = b.barcode
                )
              )
    )
    SELECT
        store_name,
        SUM(opening_qty)         AS opening_stock_qty,
        SUM(on_hand_qty)         AS on_hand_stock_qty,
        SUM(pending_qty)         AS pending_stock_qty,
        SUM(gross_qty)           AS gross_stock_qty,
        SUM(lt_sale_qty)         AS lt_sale_qty,
        SUM(opening_cost_value)  AS opening_cost_value,
        SUM(on_hand_cost_value)  AS on_hand_cost_value,
        SUM(pending_cost_value)  AS pending_cost_value,
        SUM(gross_cost_value)    AS gross_cost_value,
        SUM(opening_sal_value)   AS opening_sal_value,
        SUM(on_hand_sal_value)   AS on_hand_sal_value,
        SUM(pending_sal_value)   AS pending_sal_value,
        SUM(gross_sal_value)     AS gross_sal_value
    FROM priced
    GROUP BY store_name
    ORDER BY store_name
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_users (
    user_id uuid NOT NULL
);


--
-- Name: inv_tracking_summary; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inv_tracking_summary (
    challan_no text,
    txn_date date,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    adj_qty numeric(18,4) NOT NULL
);


--
-- Name: inv_tracking_summary_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inv_tracking_summary_staging (
    challan_no text,
    txn_date date,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    adj_qty numeric(18,4) NOT NULL
);


--
-- Name: product_file; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_file (
    barcode text NOT NULL,
    user_barcode text,
    category text,
    sub_category text,
    item_name text
);


--
-- Name: product_file_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_file_staging (
    barcode text NOT NULL,
    user_barcode text,
    category text,
    sub_category text,
    item_name text
);


--
-- Name: product_stock; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_stock (
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4)
);


--
-- Name: product_stock_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_stock_staging (
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4)
);


--
-- Name: purchase_rcv_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_rcv_details (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    pur_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: purchase_rcv_details_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_rcv_details_staging (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    pur_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: purchase_return_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_return_details (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    rtn_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: purchase_return_details_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.purchase_return_details_staging (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    rtn_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: sale; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale (
    invoice_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    sale_qty numeric(18,4) DEFAULT 0 NOT NULL,
    rtn_qty numeric(18,4) DEFAULT 0 NOT NULL
);


--
-- Name: sale_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_staging (
    invoice_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    sale_qty numeric(18,4) DEFAULT 0 NOT NULL,
    rtn_qty numeric(18,4) DEFAULT 0 NOT NULL
);


--
-- Name: store; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store (
    store_code text NOT NULL,
    store_name text NOT NULL
);


--
-- Name: store_delivery_details; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_delivery_details (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    delivery_from text NOT NULL,
    delivery_to text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    del_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: store_delivery_details_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_delivery_details_staging (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    delivery_from text NOT NULL,
    delivery_to text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    del_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: store_delivery_receive; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_delivery_receive (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    delivery_from text NOT NULL,
    delivery_to text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    del_qty numeric(18,4),
    rcv_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: store_delivery_receive_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_delivery_receive_staging (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    delivery_from text NOT NULL,
    delivery_to text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    del_qty numeric(18,4),
    rcv_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: store_dml; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_dml (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    dml_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: store_dml_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_dml_staging (
    challan_no text NOT NULL,
    txn_date date NOT NULL,
    store_code text NOT NULL,
    barcode text NOT NULL,
    sal_barcode text NOT NULL,
    cpu numeric(18,4),
    mrp numeric(18,4),
    dml_qty numeric(18,4) NOT NULL,
    status text
);


--
-- Name: store_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.store_staging (
    store_code text NOT NULL,
    store_name text NOT NULL
);


--
-- Name: sync_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sync_log (
    table_name text NOT NULL,
    last_synced_date date,
    last_synced_at timestamp with time zone,
    rows_synced integer
);


--
-- Name: user_category_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_category_access (
    user_id uuid NOT NULL,
    category text NOT NULL
);


--
-- Name: user_store_access; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_store_access (
    user_id uuid NOT NULL,
    store_code text NOT NULL
);


--
-- Name: vw_stock_ledger; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.vw_stock_ledger WITH (security_invoker='on') AS
 SELECT purchase_rcv_details.store_code,
    purchase_rcv_details.barcode,
    purchase_rcv_details.sal_barcode,
    purchase_rcv_details.txn_date,
    purchase_rcv_details.pur_qty AS in_qty,
    (0)::numeric(18,4) AS out_qty,
    'PURCHASE'::text AS source_type
   FROM public.purchase_rcv_details
  WHERE ((TRIM(BOTH FROM upper(purchase_rcv_details.status)) <> ALL (ARRAY['REJECTED'::text, 'PENDING'::text])) OR (purchase_rcv_details.status IS NULL))
UNION ALL
 SELECT store_delivery_receive.delivery_to AS store_code,
    store_delivery_receive.barcode,
    store_delivery_receive.sal_barcode,
    store_delivery_receive.txn_date,
    store_delivery_receive.rcv_qty AS in_qty,
    (0)::numeric(18,4) AS out_qty,
    'DELIVERY_RECEIVE'::text AS source_type
   FROM public.store_delivery_receive
UNION ALL
 SELECT sale.store_code,
    sale.barcode,
    sale.sal_barcode,
    sale.txn_date,
    sale.rtn_qty AS in_qty,
    sale.sale_qty AS out_qty,
    'SALE'::text AS source_type
   FROM public.sale
UNION ALL
 SELECT inv_tracking_summary.store_code,
    inv_tracking_summary.barcode,
    inv_tracking_summary.sal_barcode,
    inv_tracking_summary.txn_date,
        CASE
            WHEN (inv_tracking_summary.adj_qty > (0)::numeric) THEN inv_tracking_summary.adj_qty
            ELSE (0)::numeric
        END AS in_qty,
        CASE
            WHEN (inv_tracking_summary.adj_qty < (0)::numeric) THEN (- inv_tracking_summary.adj_qty)
            ELSE (0)::numeric
        END AS out_qty,
    'ADJUSTMENT'::text AS source_type
   FROM public.inv_tracking_summary
UNION ALL
 SELECT store_delivery_details.delivery_from AS store_code,
    store_delivery_details.barcode,
    store_delivery_details.sal_barcode,
    store_delivery_details.txn_date,
    (0)::numeric(18,4) AS in_qty,
    store_delivery_details.del_qty AS out_qty,
    'DELIVERY_DISPATCH'::text AS source_type
   FROM public.store_delivery_details
  WHERE (TRIM(BOTH FROM upper(store_delivery_details.status)) IS DISTINCT FROM 'REJECTED'::text)
UNION ALL
 SELECT store_dml.store_code,
    store_dml.barcode,
    store_dml.sal_barcode,
    store_dml.txn_date,
    (0)::numeric(18,4) AS in_qty,
    store_dml.dml_qty AS out_qty,
    'DAMAGE'::text AS source_type
   FROM public.store_dml
  WHERE (TRIM(BOTH FROM upper(store_dml.status)) IS DISTINCT FROM 'REJECTED'::text)
UNION ALL
 SELECT purchase_return_details.store_code,
    purchase_return_details.barcode,
    purchase_return_details.sal_barcode,
    purchase_return_details.txn_date,
    (0)::numeric(18,4) AS in_qty,
    purchase_return_details.rtn_qty AS out_qty,
    'PURCHASE_RETURN'::text AS source_type
   FROM public.purchase_return_details
  WHERE (TRIM(BOTH FROM upper(purchase_return_details.status)) IS DISTINCT FROM 'REJECTED'::text);


--
-- Name: admin_users admin_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (user_id);


--
-- Name: product_file product_file_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_file
    ADD CONSTRAINT product_file_pkey PRIMARY KEY (barcode);


--
-- Name: product_file_staging product_file_staging_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_file_staging
    ADD CONSTRAINT product_file_staging_pkey PRIMARY KEY (barcode);


--
-- Name: product_stock product_stock_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_stock
    ADD CONSTRAINT product_stock_pkey PRIMARY KEY (sal_barcode);


--
-- Name: product_stock_staging product_stock_staging_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_stock_staging
    ADD CONSTRAINT product_stock_staging_pkey PRIMARY KEY (sal_barcode);


--
-- Name: store store_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store
    ADD CONSTRAINT store_pkey PRIMARY KEY (store_code);


--
-- Name: store_staging store_staging_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.store_staging
    ADD CONSTRAINT store_staging_pkey PRIMARY KEY (store_code);


--
-- Name: sync_log sync_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sync_log
    ADD CONSTRAINT sync_log_pkey PRIMARY KEY (table_name);


--
-- Name: user_category_access user_category_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_category_access
    ADD CONSTRAINT user_category_access_pkey PRIMARY KEY (user_id, category);


--
-- Name: user_store_access user_store_access_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_store_access
    ADD CONSTRAINT user_store_access_pkey PRIMARY KEY (user_id, store_code);


--
-- Name: idx_delivery_details_from_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_delivery_details_from_barcode_date ON public.store_delivery_details USING btree (delivery_from, barcode, txn_date);


--
-- Name: idx_delivery_receive_to_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_delivery_receive_to_barcode_date ON public.store_delivery_receive USING btree (delivery_to, barcode, txn_date);


--
-- Name: idx_inv_tracking_store_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_tracking_store_barcode_date ON public.inv_tracking_summary USING btree (store_code, barcode, txn_date);


--
-- Name: idx_inv_tracking_summary_date_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_tracking_summary_date_report ON public.inv_tracking_summary USING btree (txn_date, store_code, barcode, sal_barcode);


--
-- Name: idx_inv_tracking_summary_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_tracking_summary_report ON public.inv_tracking_summary USING btree (store_code, txn_date, barcode, sal_barcode);


--
-- Name: idx_inv_tracking_summary_store_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inv_tracking_summary_store_date ON public.inv_tracking_summary USING btree (store_code, txn_date);


--
-- Name: idx_product_file_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_file_barcode ON public.product_file USING btree (barcode);


--
-- Name: idx_product_file_barcode_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_file_barcode_report ON public.product_file USING btree (barcode);


--
-- Name: idx_product_file_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_file_category ON public.product_file USING btree (category);


--
-- Name: idx_product_stock_sal_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_stock_sal_barcode ON public.product_stock USING btree (sal_barcode);


--
-- Name: idx_product_stock_sal_barcode_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_stock_sal_barcode_report ON public.product_stock USING btree (sal_barcode);


--
-- Name: idx_purchase_rcv_details_date_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_rcv_details_date_report ON public.purchase_rcv_details USING btree (txn_date, store_code, barcode, sal_barcode);


--
-- Name: idx_purchase_rcv_details_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_rcv_details_report ON public.purchase_rcv_details USING btree (store_code, txn_date, barcode, sal_barcode);


--
-- Name: idx_purchase_rcv_details_store_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_rcv_details_store_date ON public.purchase_rcv_details USING btree (store_code, txn_date);


--
-- Name: idx_purchase_rcv_store_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_rcv_store_barcode_date ON public.purchase_rcv_details USING btree (store_code, barcode, txn_date);


--
-- Name: idx_purchase_return_details_date_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_return_details_date_report ON public.purchase_return_details USING btree (txn_date, store_code, barcode, sal_barcode);


--
-- Name: idx_purchase_return_details_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_return_details_report ON public.purchase_return_details USING btree (store_code, txn_date, barcode, sal_barcode);


--
-- Name: idx_purchase_return_details_store_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_return_details_store_date ON public.purchase_return_details USING btree (store_code, txn_date);


--
-- Name: idx_purchase_return_store_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_purchase_return_store_barcode_date ON public.purchase_return_details USING btree (store_code, barcode, txn_date);


--
-- Name: idx_sale_date_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_date_report ON public.sale USING btree (txn_date, store_code, barcode, sal_barcode);


--
-- Name: idx_sale_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_report ON public.sale USING btree (store_code, txn_date, barcode, sal_barcode);


--
-- Name: idx_sale_store_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_store_barcode_date ON public.sale USING btree (store_code, barcode, txn_date);


--
-- Name: idx_sale_store_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_store_date ON public.sale USING btree (store_code, txn_date);


--
-- Name: idx_store_delivery_details_challan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_details_challan ON public.store_delivery_details USING btree (challan_no, delivery_to, barcode, sal_barcode);


--
-- Name: idx_store_delivery_details_date_from; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_details_date_from ON public.store_delivery_details USING btree (txn_date, delivery_from, barcode, sal_barcode);


--
-- Name: idx_store_delivery_details_date_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_details_date_pending ON public.store_delivery_details USING btree (txn_date, delivery_to, challan_no, barcode, sal_barcode);


--
-- Name: idx_store_delivery_details_from_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_details_from_date ON public.store_delivery_details USING btree (delivery_from, txn_date);


--
-- Name: idx_store_delivery_details_from_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_details_from_report ON public.store_delivery_details USING btree (delivery_from, txn_date, barcode, sal_barcode);


--
-- Name: idx_store_delivery_details_to_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_details_to_pending ON public.store_delivery_details USING btree (delivery_to, txn_date, challan_no, barcode, sal_barcode);


--
-- Name: idx_store_delivery_receive_challan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_receive_challan ON public.store_delivery_receive USING btree (challan_no, barcode, sal_barcode);


--
-- Name: idx_store_delivery_receive_date_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_receive_date_pending ON public.store_delivery_receive USING btree (txn_date, delivery_to, challan_no, barcode, sal_barcode);


--
-- Name: idx_store_delivery_receive_to_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_receive_to_date ON public.store_delivery_receive USING btree (delivery_to, txn_date);


--
-- Name: idx_store_delivery_receive_to_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_delivery_receive_to_pending ON public.store_delivery_receive USING btree (delivery_to, txn_date, challan_no, barcode, sal_barcode);


--
-- Name: idx_store_dml_date_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_dml_date_report ON public.store_dml USING btree (txn_date, store_code, barcode, sal_barcode);


--
-- Name: idx_store_dml_report; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_dml_report ON public.store_dml USING btree (store_code, txn_date, barcode, sal_barcode);


--
-- Name: idx_store_dml_store_barcode_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_dml_store_barcode_date ON public.store_dml USING btree (store_code, barcode, txn_date);


--
-- Name: idx_store_dml_store_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_dml_store_date ON public.store_dml USING btree (store_code, txn_date);


--
-- Name: idx_store_store_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_store_store_code ON public.store USING btree (store_code);


--
-- Name: idx_user_category_access_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_category_access_user_id ON public.user_category_access USING btree (user_id);


--
-- Name: inv_tracking_summary_staging_store_code_barcode_sal_barcode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX inv_tracking_summary_staging_store_code_barcode_sal_barcode_idx ON public.inv_tracking_summary_staging USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: ix_delivery_details_challan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_details_challan ON public.store_delivery_details USING btree (challan_no, barcode, sal_barcode);


--
-- Name: ix_delivery_details_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_details_lookup ON public.store_delivery_details USING btree (delivery_from, barcode, sal_barcode, txn_date);


--
-- Name: ix_delivery_receive_challan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_receive_challan ON public.store_delivery_receive USING btree (challan_no, barcode, sal_barcode);


--
-- Name: ix_delivery_receive_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_delivery_receive_lookup ON public.store_delivery_receive USING btree (delivery_to, barcode, sal_barcode, txn_date);


--
-- Name: ix_dml_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_dml_lookup ON public.store_dml USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: ix_inv_tracking_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_inv_tracking_lookup ON public.inv_tracking_summary USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: ix_product_stock_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_product_stock_barcode ON public.product_stock USING btree (barcode);


--
-- Name: ix_pur_rcv_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pur_rcv_lookup ON public.purchase_rcv_details USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: ix_pur_rtn_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_pur_rtn_lookup ON public.purchase_return_details USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: ix_sale_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_sale_lookup ON public.sale USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: product_stock_staging_barcode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX product_stock_staging_barcode_idx ON public.product_stock_staging USING btree (barcode);


--
-- Name: purchase_rcv_details_staging_store_code_barcode_sal_barcode_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX purchase_rcv_details_staging_store_code_barcode_sal_barcode_idx ON public.purchase_rcv_details_staging USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: purchase_return_details_stagi_store_code_barcode_sal_barcod_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX purchase_return_details_stagi_store_code_barcode_sal_barcod_idx ON public.purchase_return_details_staging USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: sale_staging_store_code_barcode_sal_barcode_txn_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX sale_staging_store_code_barcode_sal_barcode_txn_date_idx ON public.sale_staging USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: store_delivery_details_stagin_challan_no_barcode_sal_barcod_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX store_delivery_details_stagin_challan_no_barcode_sal_barcod_idx ON public.store_delivery_details_staging USING btree (challan_no, barcode, sal_barcode);


--
-- Name: store_delivery_details_stagin_delivery_from_barcode_sal_bar_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX store_delivery_details_stagin_delivery_from_barcode_sal_bar_idx ON public.store_delivery_details_staging USING btree (delivery_from, barcode, sal_barcode, txn_date);


--
-- Name: store_delivery_receive_stagin_challan_no_barcode_sal_barcod_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX store_delivery_receive_stagin_challan_no_barcode_sal_barcod_idx ON public.store_delivery_receive_staging USING btree (challan_no, barcode, sal_barcode);


--
-- Name: store_delivery_receive_stagin_delivery_to_barcode_sal_barco_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX store_delivery_receive_stagin_delivery_to_barcode_sal_barco_idx ON public.store_delivery_receive_staging USING btree (delivery_to, barcode, sal_barcode, txn_date);


--
-- Name: store_dml_staging_store_code_barcode_sal_barcode_txn_date_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX store_dml_staging_store_code_barcode_sal_barcode_txn_date_idx ON public.store_dml_staging USING btree (store_code, barcode, sal_barcode, txn_date);


--
-- Name: uq_product_file_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_product_file_barcode ON public.product_file USING btree (barcode) WHERE (barcode IS NOT NULL);


--
-- Name: uq_product_stock_sal_barcode; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_product_stock_sal_barcode ON public.product_stock USING btree (sal_barcode) WHERE (sal_barcode IS NOT NULL);


--
-- Name: uq_store_store_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_store_store_code ON public.store USING btree (store_code) WHERE (store_code IS NOT NULL);


--
-- Name: uq_sync_log_table_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_sync_log_table_name ON public.sync_log USING btree (table_name);


--
-- Name: admin_users admin_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_users
    ADD CONSTRAINT admin_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_category_access user_category_access_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_category_access
    ADD CONSTRAINT user_category_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: user_store_access user_store_access_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_store_access
    ADD CONSTRAINT user_store_access_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: admin_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

--
-- Name: inv_tracking_summary allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.inv_tracking_summary FOR SELECT TO authenticated USING (true);


--
-- Name: product_file allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.product_file FOR SELECT TO authenticated USING (true);


--
-- Name: product_stock allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.product_stock FOR SELECT TO authenticated USING (true);


--
-- Name: purchase_rcv_details allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.purchase_rcv_details FOR SELECT TO authenticated USING (true);


--
-- Name: purchase_return_details allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.purchase_return_details FOR SELECT TO authenticated USING (true);


--
-- Name: sale allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.sale FOR SELECT TO authenticated USING (true);


--
-- Name: store_delivery_details allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.store_delivery_details FOR SELECT TO authenticated USING (true);


--
-- Name: store_delivery_receive allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.store_delivery_receive FOR SELECT TO authenticated USING (true);


--
-- Name: store_dml allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.store_dml FOR SELECT TO authenticated USING (true);


--
-- Name: sync_log allow_authenticated_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY allow_authenticated_read ON public.sync_log FOR SELECT TO authenticated USING (true);


--
-- Name: inv_tracking_summary; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inv_tracking_summary ENABLE ROW LEVEL SECURITY;

--
-- Name: inv_tracking_summary_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.inv_tracking_summary_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: product_file; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_file ENABLE ROW LEVEL SECURITY;

--
-- Name: product_file_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_file_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: product_stock; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_stock ENABLE ROW LEVEL SECURITY;

--
-- Name: product_stock_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_stock_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_rcv_details; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_rcv_details ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_rcv_details_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_rcv_details_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_return_details; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_return_details ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_return_details_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.purchase_return_details_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: sale; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sale ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sale_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: user_category_access select own category access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "select own category access" ON public.user_category_access FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: user_store_access select own store access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "select own store access" ON public.user_store_access FOR SELECT TO authenticated USING ((user_id = auth.uid()));


--
-- Name: store; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store ENABLE ROW LEVEL SECURITY;

--
-- Name: store store select by user access; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "store select by user access" ON public.store FOR SELECT TO authenticated USING (((public.fn_user_allowed_stores() IS NULL) OR (store_code = ANY (public.fn_user_allowed_stores()))));


--
-- Name: store_delivery_details; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_delivery_details ENABLE ROW LEVEL SECURITY;

--
-- Name: store_delivery_details_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_delivery_details_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: store_delivery_receive; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_delivery_receive ENABLE ROW LEVEL SECURITY;

--
-- Name: store_delivery_receive_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_delivery_receive_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: store_dml; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_dml ENABLE ROW LEVEL SECURITY;

--
-- Name: store_dml_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_dml_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: store_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.store_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: sync_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sync_log ENABLE ROW LEVEL SECURITY;

--
-- Name: user_category_access; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_category_access ENABLE ROW LEVEL SECURITY;

--
-- Name: user_store_access; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.user_store_access ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: FUNCTION admin_get_all_categories(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_get_all_categories() TO authenticated;
GRANT ALL ON FUNCTION public.admin_get_all_categories() TO service_role;


--
-- Name: FUNCTION admin_get_all_stores(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_get_all_stores() TO authenticated;
GRANT ALL ON FUNCTION public.admin_get_all_stores() TO service_role;


--
-- Name: FUNCTION admin_get_category_access(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_get_category_access() TO authenticated;
GRANT ALL ON FUNCTION public.admin_get_category_access() TO service_role;


--
-- Name: FUNCTION admin_get_store_access(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_get_store_access() TO authenticated;
GRANT ALL ON FUNCTION public.admin_get_store_access() TO service_role;


--
-- Name: FUNCTION admin_list_users(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_list_users() TO authenticated;
GRANT ALL ON FUNCTION public.admin_list_users() TO service_role;


--
-- Name: FUNCTION admin_set_user_categories(p_user_id uuid, p_categories text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_set_user_categories(p_user_id uuid, p_categories text[]) TO authenticated;
GRANT ALL ON FUNCTION public.admin_set_user_categories(p_user_id uuid, p_categories text[]) TO service_role;


--
-- Name: FUNCTION admin_set_user_stores(p_user_id uuid, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.admin_set_user_stores(p_user_id uuid, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.admin_set_user_stores(p_user_id uuid, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_barcode_stock_age(as_of_date date, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_barcode_stock_age(as_of_date date, p_store_codes text[]) TO anon;
GRANT ALL ON FUNCTION public.fn_barcode_stock_age(as_of_date date, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_barcode_stock_age(as_of_date date, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_effective_store_codes(p_requested text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_effective_store_codes(p_requested text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_effective_store_codes(p_requested text[]) TO service_role;


--
-- Name: FUNCTION fn_is_admin(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_is_admin() TO authenticated;
GRANT ALL ON FUNCTION public.fn_is_admin() TO service_role;


--
-- Name: FUNCTION fn_pending_stock(as_of_date date, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_pending_stock(as_of_date date, p_store_codes text[]) TO anon;
GRANT ALL ON FUNCTION public.fn_pending_stock(as_of_date date, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_pending_stock(as_of_date date, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[]) TO anon;
GRANT ALL ON FUNCTION public.fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_sale_barcode_stock_cycles(as_of_date date, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[]) TO anon;
GRANT ALL ON FUNCTION public.fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_sale_barcode_stock_period(as_of_date date, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_stock_opening_onhand(as_of_date date, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_stock_opening_onhand(as_of_date date, p_store_codes text[]) TO anon;
GRANT ALL ON FUNCTION public.fn_stock_opening_onhand(as_of_date date, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_stock_opening_onhand(as_of_date date, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_stock_qty(as_of_date date, p_store_codes text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_stock_qty(as_of_date date, p_store_codes text[]) TO anon;
GRANT ALL ON FUNCTION public.fn_stock_qty(as_of_date date, p_store_codes text[]) TO authenticated;
GRANT ALL ON FUNCTION public.fn_stock_qty(as_of_date date, p_store_codes text[]) TO service_role;


--
-- Name: FUNCTION fn_user_allowed_categories(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_user_allowed_categories() TO authenticated;
GRANT ALL ON FUNCTION public.fn_user_allowed_categories() TO service_role;


--
-- Name: FUNCTION fn_user_allowed_stores(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_user_allowed_stores() TO authenticated;
GRANT ALL ON FUNCTION public.fn_user_allowed_stores() TO service_role;


--
-- Name: FUNCTION fn_validate_report_master_integrity(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.fn_validate_report_master_integrity() TO authenticated;
GRANT ALL ON FUNCTION public.fn_validate_report_master_integrity() TO service_role;


--
-- Name: FUNCTION get_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]) TO anon;
GRANT ALL ON FUNCTION public.get_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]) TO authenticated;
GRANT ALL ON FUNCTION public.get_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]) TO service_role;


--
-- Name: FUNCTION get_distinct_categories(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_distinct_categories() TO anon;
GRANT ALL ON FUNCTION public.get_distinct_categories() TO authenticated;
GRANT ALL ON FUNCTION public.get_distinct_categories() TO service_role;


--
-- Name: FUNCTION get_distinct_sub_categories(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_distinct_sub_categories() TO anon;
GRANT ALL ON FUNCTION public.get_distinct_sub_categories() TO authenticated;
GRANT ALL ON FUNCTION public.get_distinct_sub_categories() TO service_role;


--
-- Name: FUNCTION get_distinct_sub_categories_for_categories(p_category text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_distinct_sub_categories_for_categories(p_category text[]) TO authenticated;
GRANT ALL ON FUNCTION public.get_distinct_sub_categories_for_categories(p_category text[]) TO service_role;


--
-- Name: FUNCTION get_sale_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[], p_search text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_sale_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[], p_search text) TO anon;
GRANT ALL ON FUNCTION public.get_sale_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[], p_search text) TO authenticated;
GRANT ALL ON FUNCTION public.get_sale_barcode_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[], p_search text) TO service_role;


--
-- Name: FUNCTION get_store_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_store_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]) TO anon;
GRANT ALL ON FUNCTION public.get_store_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]) TO authenticated;
GRANT ALL ON FUNCTION public.get_store_wise_report(as_of_date date, p_store_codes text[], p_category text[], p_sub_category text[]) TO service_role;


--
-- Name: TABLE admin_users; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.admin_users TO anon;
GRANT ALL ON TABLE public.admin_users TO authenticated;
GRANT ALL ON TABLE public.admin_users TO service_role;


--
-- Name: TABLE inv_tracking_summary; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.inv_tracking_summary TO anon;
GRANT ALL ON TABLE public.inv_tracking_summary TO authenticated;
GRANT ALL ON TABLE public.inv_tracking_summary TO service_role;


--
-- Name: TABLE inv_tracking_summary_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.inv_tracking_summary_staging TO anon;
GRANT ALL ON TABLE public.inv_tracking_summary_staging TO authenticated;
GRANT ALL ON TABLE public.inv_tracking_summary_staging TO service_role;


--
-- Name: TABLE product_file; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.product_file TO anon;
GRANT ALL ON TABLE public.product_file TO authenticated;
GRANT ALL ON TABLE public.product_file TO service_role;


--
-- Name: TABLE product_file_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_file_staging TO anon;
GRANT ALL ON TABLE public.product_file_staging TO authenticated;
GRANT ALL ON TABLE public.product_file_staging TO service_role;


--
-- Name: TABLE product_stock; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.product_stock TO anon;
GRANT ALL ON TABLE public.product_stock TO authenticated;
GRANT ALL ON TABLE public.product_stock TO service_role;


--
-- Name: TABLE product_stock_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_stock_staging TO anon;
GRANT ALL ON TABLE public.product_stock_staging TO authenticated;
GRANT ALL ON TABLE public.product_stock_staging TO service_role;


--
-- Name: TABLE purchase_rcv_details; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.purchase_rcv_details TO anon;
GRANT ALL ON TABLE public.purchase_rcv_details TO authenticated;
GRANT ALL ON TABLE public.purchase_rcv_details TO service_role;


--
-- Name: TABLE purchase_rcv_details_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.purchase_rcv_details_staging TO anon;
GRANT ALL ON TABLE public.purchase_rcv_details_staging TO authenticated;
GRANT ALL ON TABLE public.purchase_rcv_details_staging TO service_role;


--
-- Name: TABLE purchase_return_details; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.purchase_return_details TO anon;
GRANT ALL ON TABLE public.purchase_return_details TO authenticated;
GRANT ALL ON TABLE public.purchase_return_details TO service_role;


--
-- Name: TABLE purchase_return_details_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.purchase_return_details_staging TO anon;
GRANT ALL ON TABLE public.purchase_return_details_staging TO authenticated;
GRANT ALL ON TABLE public.purchase_return_details_staging TO service_role;


--
-- Name: TABLE sale; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.sale TO anon;
GRANT ALL ON TABLE public.sale TO authenticated;
GRANT ALL ON TABLE public.sale TO service_role;


--
-- Name: TABLE sale_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sale_staging TO anon;
GRANT ALL ON TABLE public.sale_staging TO authenticated;
GRANT ALL ON TABLE public.sale_staging TO service_role;


--
-- Name: TABLE store; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.store TO anon;
GRANT ALL ON TABLE public.store TO authenticated;
GRANT ALL ON TABLE public.store TO service_role;


--
-- Name: TABLE store_delivery_details; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.store_delivery_details TO anon;
GRANT ALL ON TABLE public.store_delivery_details TO authenticated;
GRANT ALL ON TABLE public.store_delivery_details TO service_role;


--
-- Name: TABLE store_delivery_details_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.store_delivery_details_staging TO anon;
GRANT ALL ON TABLE public.store_delivery_details_staging TO authenticated;
GRANT ALL ON TABLE public.store_delivery_details_staging TO service_role;


--
-- Name: TABLE store_delivery_receive; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.store_delivery_receive TO anon;
GRANT ALL ON TABLE public.store_delivery_receive TO authenticated;
GRANT ALL ON TABLE public.store_delivery_receive TO service_role;


--
-- Name: TABLE store_delivery_receive_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.store_delivery_receive_staging TO anon;
GRANT ALL ON TABLE public.store_delivery_receive_staging TO authenticated;
GRANT ALL ON TABLE public.store_delivery_receive_staging TO service_role;


--
-- Name: TABLE store_dml; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.store_dml TO anon;
GRANT ALL ON TABLE public.store_dml TO authenticated;
GRANT ALL ON TABLE public.store_dml TO service_role;


--
-- Name: TABLE store_dml_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.store_dml_staging TO anon;
GRANT ALL ON TABLE public.store_dml_staging TO authenticated;
GRANT ALL ON TABLE public.store_dml_staging TO service_role;


--
-- Name: TABLE store_staging; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.store_staging TO anon;
GRANT ALL ON TABLE public.store_staging TO authenticated;
GRANT ALL ON TABLE public.store_staging TO service_role;


--
-- Name: TABLE sync_log; Type: ACL; Schema: public; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE public.sync_log TO anon;
GRANT ALL ON TABLE public.sync_log TO authenticated;
GRANT ALL ON TABLE public.sync_log TO service_role;


--
-- Name: TABLE user_category_access; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.user_category_access TO anon;
GRANT ALL ON TABLE public.user_category_access TO authenticated;
GRANT ALL ON TABLE public.user_category_access TO service_role;


--
-- Name: TABLE user_store_access; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.user_store_access TO authenticated;
GRANT ALL ON TABLE public.user_store_access TO service_role;


--
-- Name: TABLE vw_stock_ledger; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.vw_stock_ledger TO anon;
GRANT ALL ON TABLE public.vw_stock_ledger TO authenticated;
GRANT ALL ON TABLE public.vw_stock_ledger TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES TO service_role;


--
-- PostgreSQL database dump complete
--

\unrestrict 0bzHSo7ro2zCEbl0LLvnTZIkG0r2jJQPApAcTr5E3X2ZNHdsKS3tbvGgm8yZt7X

