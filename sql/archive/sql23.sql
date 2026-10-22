-- 콘텐츠별 성과 마트, 가벼운 버전
DROP TABLE IF EXISTS dm_content_7d_performance;

CREATE TABLE dm_content_7d_performance AS
SELECT
    e.period_group,
    e.cohort_month,
    e.content_id,

    COUNT(DISTINCT CASE
        WHEN e.event_name = 'enter_content_page'
        THEN e.user_id END
    ) AS content_view_users_7d,

    COUNT(DISTINCT CASE
        WHEN e.event_name = 'start_content'
        THEN e.user_id END
    ) AS content_start_users_7d,

    COUNT(DISTINCT CASE
        WHEN e.event_name = 'complete_lesson'
        THEN e.user_id END
    ) AS lesson_complete_users_7d,

    COUNT(DISTINCT CASE
        WHEN e.event_name = 'end_content'
        THEN e.user_id END
    ) AS content_end_users_7d,

    COUNT(DISTINCT CASE
        WHEN d.paid_30d = 1
        THEN e.user_id END
    ) AS paid_30d_users,

    ROUND(
        COUNT(DISTINCT CASE WHEN e.event_name = 'start_content' THEN e.user_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'enter_content_page' THEN e.user_id END), 0)
        * 100,
        2
    ) AS view_to_start_rate,

    ROUND(
        COUNT(DISTINCT CASE WHEN e.event_name = 'end_content' THEN e.user_id END)
        / NULLIF(COUNT(DISTINCT CASE WHEN e.event_name = 'start_content' THEN e.user_id END), 0)
        * 100,
        2
    ) AS start_to_end_rate,

    ROUND(
        COUNT(DISTINCT CASE WHEN d.paid_30d = 1 THEN e.user_id END)
        / NULLIF(COUNT(DISTINCT e.user_id), 0)
        * 100,
        2
    ) AS paid_30d_rate

FROM event_log_thin_cohort e
JOIN dm_user_activation_payment d
    ON e.user_id = d.user_id
WHERE e.event_time >= d.signup_time
  AND e.event_time <  DATE_ADD(d.signup_time, INTERVAL 7 DAY)
  AND e.content_id IS NOT NULL
  AND e.content_id <> ''
  AND e.event_name IN (
      'enter_content_page',
      'start_content',
      'complete_lesson',
      'end_content'
  )
GROUP BY
    e.period_group,
    e.cohort_month,
    e.content_id;