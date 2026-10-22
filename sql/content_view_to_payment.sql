-- Portfolio correction, 2026-10-22. Read-only, MySQL 8-style SQL.
-- Denominator: distinct users who viewed a specific content item during
-- [signup, signup + 7 days), before their first payment (if any).
-- Numerator: members of that SAME group with paid_30d = 1.
-- This is a retrospective association, not a causal content effect.
-- Not executed against the source database during repository preparation.

WITH eligible_viewers AS (
    SELECT DISTINCT
        u.period_group,
        e.content_id,
        u.user_id,
        u.paid_30d
    FROM event_log_thin_cohort AS e
    INNER JOIN dm_user_activation_payment AS u
        ON u.user_id = e.user_id
    WHERE e.event_name = 'enter_content_page'
      AND e.content_id IS NOT NULL
      AND e.content_id <> ''
      AND e.event_time >= u.signup_time
      AND e.event_time < DATE_ADD(u.signup_time, INTERVAL 7 DAY)
      AND (u.first_payment_time IS NULL OR e.event_time < u.first_payment_time)
)
SELECT
    period_group,
    content_id,
    COUNT(*) AS prepayment_view_users,
    SUM(paid_30d) AS viewers_with_first_payment_30d,
    ROUND(100.0 * SUM(paid_30d) / NULLIF(COUNT(*), 0), 2)
        AS first_payment_rate_among_prepayment_viewers_pct
FROM eligible_viewers
GROUP BY period_group, content_id
HAVING COUNT(*) >= 30
ORDER BY period_group, first_payment_rate_among_prepayment_viewers_pct DESC;
