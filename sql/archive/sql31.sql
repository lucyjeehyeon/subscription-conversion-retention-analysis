-- 2022년 4월 로그 export
SELECT *
FROM event_log_thin_cohort
WHERE event_month = '2022-04-01'
ORDER BY user_id, event_time, id;