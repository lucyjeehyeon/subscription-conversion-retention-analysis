-- 2022년 6월 로그 export
SELECT *
FROM event_log_thin_cohort
WHERE event_month = '2022-06-01'
ORDER BY user_id, event_time, id;