-- event_log_thin_cohort.csv는 월별 export
SELECT
    event_month,
    COUNT(*) AS event_rows
FROM event_log_thin_cohort
GROUP BY event_month
ORDER BY event_month;