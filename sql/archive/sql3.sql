-- 콘텐츠 페이지 진입
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

    t.client_event_time,
    DATE_FORMAT(t.client_event_time, '%Y-%m-01'),
    'enter_content_page',
    'enter_content_page',

    t.`content.id`, NULL, NULL, NULL, NULL,
    NULL,

    NULL, NULL, NULL, NULL,
    NULL, NULL,

    t.platform,
    t.device_type

FROM enter_content_page t
JOIN dm_signup_cohort b
    ON t.user_id = b.user_id
   AND t.client_event_time >= DATE_SUB(b.signup_time, INTERVAL 7 DAY)
   AND t.client_event_time <  DATE_ADD(b.signup_time, INTERVAL 30 DAY);