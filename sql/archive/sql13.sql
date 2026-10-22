-- 인덱스 추가
ALTER TABLE event_log_thin_cohort
ADD INDEX idx_user_time (user_id, event_time),
ADD INDEX idx_event_time (event_name, event_time),
ADD INDEX idx_cohort_month (cohort_month),
ADD INDEX idx_period_group (period_group),
ADD INDEX idx_content_id (content_id),
ADD INDEX idx_lesson_id (lesson_id);