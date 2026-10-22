-- 유저 단위 분석 마트 생성
DROP TABLE IF EXISTS dm_user_activation_payment;

CREATE TABLE dm_user_activation_payment AS
SELECT
    x.*,

    CASE
        WHEN x.lesson_complete_7d > 0 THEN 1
        ELSE 0
    END AS is_activated_lesson_7d,

    CASE
        WHEN x.lesson_complete_7d > 0
          OR x.content_end_7d > 0
        THEN 1 ELSE 0
    END AS is_activated_strong_7d

FROM (
    SELECT
        b.user_id,
        b.signup_time,
        b.cohort_month,
        b.period_group,
        b.signup_type,
        b.signup_platform,
        b.signup_device_type,

        p.first_payment_time,
        CASE
            WHEN p.first_payment_time IS NOT NULL THEN 1
            ELSE 0
        END AS paid_30d,

        CASE
            WHEN p.first_payment_time IS NOT NULL
            THEN TIMESTAMPDIFF(DAY, b.signup_time, p.first_payment_time)
            ELSE NULL
        END AS days_to_payment,

        p.first_plan_price,
        p.first_paid_amount,
        p.first_discount_amount,
        p.first_pg_type,

        -- 가입 후 7일 내 콘텐츠 탐색/시작
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'enter_content_page'
            THEN 1 END
        ) AS content_view_7d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'enter_content_page'
            THEN e.content_id END
        ) AS unique_content_view_7d,

        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'start_content'
            THEN 1 END
        ) AS content_start_7d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'start_content'
            THEN e.content_id END
        ) AS unique_content_start_7d,

        -- 가입 후 7일 내 레슨 진입/완료
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'enter_lesson_page'
            THEN 1 END
        ) AS lesson_enter_7d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'enter_lesson_page'
            THEN e.lesson_id END
        ) AS unique_lesson_enter_7d,

        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'complete_lesson'
            THEN 1 END
        ) AS lesson_complete_7d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'complete_lesson'
            THEN e.lesson_id END
        ) AS unique_lesson_complete_7d,

        -- 가입 후 7일 내 콘텐츠 완료
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'end_content'
            THEN 1 END
        ) AS content_end_7d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'end_content'
            THEN e.content_id END
        ) AS unique_content_end_7d,

        -- 후기/질문 클릭
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'click_content_page_more_review_button'
            THEN 1 END
        ) AS review_click_7d,

        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'click_lesson_page_related_question_box'
            THEN 1 END
        ) AS question_click_7d,

        -- 결제 페이지 진입은 보조 지표
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND e.event_name = 'enter_payment_page'
            THEN 1 END
        ) AS payment_page_enter_7d,

        -- 결제 전 7일 내 학습 행동
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND (p.first_payment_time IS NULL OR e.event_time < p.first_payment_time)
             AND e.event_name = 'complete_lesson'
            THEN 1 END
        ) AS lesson_complete_prepay_7d,

        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND (p.first_payment_time IS NULL OR e.event_time < p.first_payment_time)
             AND e.event_name = 'end_content'
            THEN 1 END
        ) AS content_end_prepay_7d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 7 DAY)
             AND (p.first_payment_time IS NULL OR e.event_time < p.first_payment_time)
             AND e.event_name IN (
                'enter_content_page',
                'start_content',
                'complete_lesson',
                'end_content'
             )
            THEN e.content_id END
        ) AS unique_content_prepay_7d,

        -- 결제 전 30일 내 학습 행동
        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 30 DAY)
             AND (p.first_payment_time IS NULL OR e.event_time < p.first_payment_time)
             AND e.event_name = 'complete_lesson'
            THEN 1 END
        ) AS lesson_complete_prepay_30d,

        COUNT(CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 30 DAY)
             AND (p.first_payment_time IS NULL OR e.event_time < p.first_payment_time)
             AND e.event_name = 'end_content'
            THEN 1 END
        ) AS content_end_prepay_30d,

        COUNT(DISTINCT CASE
            WHEN e.event_time >= b.signup_time
             AND e.event_time < DATE_ADD(b.signup_time, INTERVAL 30 DAY)
             AND (p.first_payment_time IS NULL OR e.event_time < p.first_payment_time)
             AND e.event_name IN (
                'enter_content_page',
                'start_content',
                'complete_lesson',
                'end_content'
             )
            THEN e.content_id END
        ) AS unique_content_prepay_30d

    FROM dm_signup_cohort b
    LEFT JOIN dm_first_payment_30d p
        ON b.user_id = p.user_id
    LEFT JOIN event_log_thin_cohort e
        ON b.user_id = e.user_id
       AND e.event_time >= b.signup_time
       AND e.event_time <  DATE_ADD(b.signup_time, INTERVAL 30 DAY)

    GROUP BY
        b.user_id,
        b.signup_time,
        b.cohort_month,
        b.period_group,
        b.signup_type,
        b.signup_platform,
        b.signup_device_type,
        p.first_payment_time,
        p.first_plan_price,
        p.first_paid_amount,
        p.first_discount_amount,
        p.first_pg_type
) x;