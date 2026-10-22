-- dm_user_activation_payment.csv export
SELECT *
FROM dm_user_activation_payment
ORDER BY period_group, cohort_month, signup_time, user_id;