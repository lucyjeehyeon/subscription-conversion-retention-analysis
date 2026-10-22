-- 최소 품질 점검
SELECT
    source_table,
    event_month,
    COUNT(*) AS event_rows,
    COUNT(DISTINCT user_id) AS event_users,
    MIN(event_time) AS min_event_time,
    MAX(event_time) AS max_event_time
FROM event_log_thin_cohort
GROUP BY source_table, event_month
ORDER BY source_table, event_month;