-- 핵심 아이디 결측 확인
SELECT
    event_name,
    COUNT(*) AS total_rows,

    SUM(CASE WHEN user_id IS NULL OR user_id = '' THEN 1 ELSE 0 END) AS blank_user_id,

    SUM(CASE
        WHEN event_name IN (
            'enter_content_page',
            'click_content_page_start_content_button',
            'click_content_page_more_review_button',
            'start_content',
            'enter_lesson_page',
            'complete_lesson',
            'click_lesson_page_related_question_box',
            'end_content'
        )
        AND (content_id IS NULL OR content_id = '')
        THEN 1 ELSE 0
    END) AS blank_content_id,

    SUM(CASE
        WHEN event_name IN (
            'enter_lesson_page',
            'complete_lesson',
            'click_lesson_page_related_question_box'
        )
        AND (lesson_id IS NULL OR lesson_id = '')
        THEN 1 ELSE 0
    END) AS blank_lesson_id

FROM event_log_thin_cohort
GROUP BY event_name
ORDER BY event_name;