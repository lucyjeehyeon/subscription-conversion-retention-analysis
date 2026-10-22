-- 레슨 완료 수별 결제율
SELECT
    period_group,

    CASE
        WHEN lesson_complete_prepay_7d = 0 THEN '0회'
        WHEN lesson_complete_prepay_7d = 1 THEN '1회'
        WHEN lesson_complete_prepay_7d BETWEEN 2 AND 3 THEN '2~3회'
        WHEN lesson_complete_prepay_7d BETWEEN 4 AND 10 THEN '4~10회'
        WHEN lesson_complete_prepay_7d BETWEEN 11 AND 30 THEN '11~30회'
        ELSE '31회 이상'
    END AS lesson_complete_prepay_7d_group,

    COUNT(*) AS users,
    SUM(paid_30d) AS paid_30d_users,
    ROUND(AVG(paid_30d) * 100, 2) AS paid_30d_rate

FROM dm_user_activation_payment
GROUP BY
    period_group,
    CASE
        WHEN lesson_complete_prepay_7d = 0 THEN '0회'
        WHEN lesson_complete_prepay_7d = 1 THEN '1회'
        WHEN lesson_complete_prepay_7d BETWEEN 2 AND 3 THEN '2~3회'
        WHEN lesson_complete_prepay_7d BETWEEN 4 AND 10 THEN '4~10회'
        WHEN lesson_complete_prepay_7d BETWEEN 11 AND 30 THEN '11~30회'
        ELSE '31회 이상'
    END
ORDER BY
    period_group,
    MIN(lesson_complete_prepay_7d);