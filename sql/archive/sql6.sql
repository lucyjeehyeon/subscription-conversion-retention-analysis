-- 콘텐츠 시작
INSERT INTO event_log_thin_cohort (
    user_id, cohort_month, period_group,
    event_time, event_month, event_name, source_table,
    content_id, lesson_id, question_id, button_name, content_difficulty,
    signup_type,
    plan_price, paid_amount, discount_amount, pg_type,
    is_trial, is_free_trial,
    platform, device_type
)
SELECT
    t.user_id,
    b.cohort_month,
    b.period_group,

    t.event_time,
    CAST(DATE_FORMAT(t.event_time, '%Y-%m-01') AS DATE) AS event_month,
    'start_content' AS event_name,
    'start_content' AS source_table,

    t.content_id,
    NULL AS lesson_id,
    NULL AS question_id,
    NULL AS button_name,
    t.content_difficulty,

    NULL AS signup_type,
    NULL AS plan_price,
    NULL AS paid_amount,
    NULL AS discount_amount,
    NULL AS pg_type,
    NULL AS is_trial,
    NULL AS is_free_trial,

    t.platform,
    t.device_type

FROM (
    SELECT
        user_id,
        STR_TO_DATE(
            LEFT(TRIM(client_event_time), 19),
            '%Y-%m-%d %H:%i:%s'
        ) AS event_time,
        `content.id` AS content_id,
        `content.difficulty` AS content_difficulty,
        platform,
        device_type
    FROM start_content
    WHERE client_event_time IS NOT NULL
      AND TRIM(client_event_time) <> ''
      AND TRIM(client_event_time) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'
) t
JOIN dm_signup_cohort b
    ON t.user_id = b.user_id
   AND t.event_time >= DATE_SUB(b.signup_time, INTERVAL 7 DAY)
   AND t.event_time <  DATE_ADD(b.signup_time, INTERVAL 30 DAY)
WHERE t.event_time IS NOT NULL;