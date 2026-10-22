-- 콘텐츠 완료 여부별 결제율
SELECT
    period_group,

    CASE
        WHEN content_end_prepay_7d = 0 THEN '콘텐츠 완료 없음'
        ELSE '콘텐츠 완료 있음'
    END AS content_end_group,

    COUNT(*) AS users,
    SUM(paid_30d) AS paid_30d_users,
    ROUND(AVG(paid_30d) * 100, 2) AS paid_30d_rate

FROM dm_user_activation_payment
GROUP BY
    period_group,
    CASE
        WHEN content_end_prepay_7d = 0 THEN '콘텐츠 완료 없음'
        ELSE '콘텐츠 완료 있음'
    END
ORDER BY period_group, content_end_group;