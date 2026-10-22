-- 고유 콘텐츠 탐색 수별 결제율
SELECT
    period_group,

    CASE
        WHEN unique_content_prepay_7d = 0 THEN '0개'
        WHEN unique_content_prepay_7d = 1 THEN '1개'
        WHEN unique_content_prepay_7d BETWEEN 2 AND 3 THEN '2~3개'
        ELSE '4개 이상'
    END AS unique_content_group,

    COUNT(*) AS users,
    SUM(paid_30d) AS paid_30d_users,
    ROUND(AVG(paid_30d) * 100, 2) AS paid_30d_rate

FROM dm_user_activation_payment
GROUP BY
    period_group,
    CASE
        WHEN unique_content_prepay_7d = 0 THEN '0개'
        WHEN unique_content_prepay_7d = 1 THEN '1개'
        WHEN unique_content_prepay_7d BETWEEN 2 AND 3 THEN '2~3개'
        ELSE '4개 이상'
    END
ORDER BY period_group, MIN(unique_content_prepay_7d);