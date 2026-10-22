SELECT COUNT(*) AS row_count
FROM dm_user_activation_payment;

SELECT COUNT(*) AS row_count
FROM dm_content_7d_performance;

SELECT COUNT(*) AS row_count
FROM event_log_thin_cohort;

SELECT
    event_month,
    COUNT(*) AS event_rows,
    COUNT(DISTINCT user_id) AS event_users
FROM event_log_thin_cohort
GROUP BY event_month
ORDER BY event_month;