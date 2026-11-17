-- 11_assertions.sql
-- Fail loudly if a headline figure drifts from the value reported in the README.
-- Run after loading and building the views:
--     psql -v ON_ERROR_STOP=1 -d olist -f sql/11_assertions.sql

DO $$
DECLARE
    n bigint;
    v numeric;
BEGIN
    SELECT count(*) INTO n FROM orders;
    IF n <> 99441 THEN
        RAISE EXCEPTION 'orders: expected 99441, found %', n;
    END IF;

    SELECT count(*) INTO n FROM orders WHERE order_status = 'delivered';
    IF n <> 96478 THEN
        RAISE EXCEPTION 'delivered orders: expected 96478, found %', n;
    END IF;

    SELECT count(*) INTO n FROM fact_order_items;
    IF n <> 110197 THEN
        RAISE EXCEPTION 'fact_order_items rows: expected 110197, found %', n;
    END IF;

    SELECT round(sum(price), 2) INTO v FROM fact_order_items;
    IF v <> 13221498.11 THEN
        RAISE EXCEPTION 'product revenue: expected 13221498.11, found %', v;
    END IF;

    SELECT count(*) INTO n FROM fact_order_items WHERE delay_days IS NULL;
    IF n <> 8 THEN
        RAISE EXCEPTION 'rows without a delay measure: expected 8, found %', n;
    END IF;

    SELECT count(DISTINCT order_id) INTO n
    FROM fact_order_items
    WHERE is_late = 1;
    IF n <> 6534 THEN
        RAISE EXCEPTION 'late orders: expected 6534, found %', n;
    END IF;

    SELECT count(*) INTO n FROM dim_customers;
    IF n <> 96096 THEN
        RAISE EXCEPTION 'dim_customers rows: expected 96096, found %', n;
    END IF;

    SELECT count(*) INTO n FROM dim_products;
    IF n <> 32951 THEN
        RAISE EXCEPTION 'dim_products rows: expected 32951, found %', n;
    END IF;

    SELECT count(*) INTO n FROM dim_sellers;
    IF n <> 3095 THEN
        RAISE EXCEPTION 'dim_sellers rows: expected 3095, found %', n;
    END IF;

    SELECT count(*) INTO n FROM dim_date;
    IF n <> 1096 THEN
        RAISE EXCEPTION 'dim_date rows: expected 1096, found %', n;
    END IF;

    SELECT count(*) INTO n FROM rfm_segments;
    IF n <> 93358 THEN
        RAISE EXCEPTION 'rfm_segments rows: expected 93358, found %', n;
    END IF;

    SELECT sum(customers) INTO n FROM rfm_segment_summary;
    IF n <> 93358 THEN
        RAISE EXCEPTION 'RFM segment customers: expected 93358, found %', n;
    END IF;

    SELECT round(sum(revenue), 2) INTO v FROM rfm_segment_summary;
    IF v <> 13221498.11 THEN
        RAISE EXCEPTION 'RFM segment revenue: expected 13221498.11, found %', v;
    END IF;

    SELECT count(*) INTO n FROM cohort_retention;
    IF n <> 221 THEN
        RAISE EXCEPTION 'cohort_retention rows: expected 221, found %', n;
    END IF;

    SELECT count(*) INTO n
    FROM cohort_retention
    WHERE month_number = 0 AND retention_pct <> 100;
    IF n <> 0 THEN
        RAISE EXCEPTION 'month 0 retention must be 100%%, found % rows below it', n;
    END IF;

    RAISE NOTICE 'All headline assertions passed.';
END $$;
