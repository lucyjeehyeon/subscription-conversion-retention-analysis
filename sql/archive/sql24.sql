-- 확인 쿼리
SELECT
    period_group,
    content_id,
    SUM(content_view_users_7d) AS view_users,
    SUM(content_start_users_7d) AS start_users,
    SUM(content_end_users_7d) AS end_users,
    SUM(paid_30d_users) AS paid_users,
    ROUND(SUM(paid_30d_users) / NULLIF(SUM(content_view_users_7d), 0) * 100, 2) AS paid_rate_from_view
FROM dm_content_7d_performance
GROUP BY period_group, content_id
HAVING view_users >= 30
ORDER BY period_group, paid_rate_from_view DESC;