-- 인덱스 추가
ALTER TABLE dm_user_activation_payment
ADD PRIMARY KEY (user_id),
ADD INDEX idx_cohort_month (cohort_month),
ADD INDEX idx_period_group (period_group),
ADD INDEX idx_paid_30d (paid_30d),
ADD INDEX idx_activation (is_activated_lesson_7d, is_activated_strong_7d);