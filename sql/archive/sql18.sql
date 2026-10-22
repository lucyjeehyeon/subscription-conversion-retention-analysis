-- 결과 sanity check
SELECT
    period_group,
    COUNT(*) AS signup_users,
    SUM(paid_30d) AS paid_30d_users,
    ROUND(AVG(paid_30d) * 100, 2) AS paid_30d_rate,

    ROUND(AVG(lesson_complete_7d), 2) AS avg_lesson_complete_7d,
    ROUND(AVG(content_end_7d), 2) AS avg_content_end_7d,
    ROUND(AVG(unique_content_view_7d), 2) AS avg_unique_content_view_7d,

    ROUND(AVG(is_activated_lesson_7d) * 100, 2) AS activated_lesson_7d_rate,
    ROUND(AVG(is_activated_strong_7d) * 100, 2) AS activated_strong_7d_rate

FROM dm_user_activation_payment
GROUP BY period_group
ORDER BY period_group;