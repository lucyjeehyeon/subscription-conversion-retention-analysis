create database topic2_db;

use topic2_db;

SHOW FULL PROCESSLIST;

SELECT 
    ID,
    USER,
    HOST,
    DB,
    COMMAND,
    TIME,
    STATE,
    LEFT(INFO, 300) AS QUERY_TEXT
FROM INFORMATION_SCHEMA.PROCESSLIST
WHERE DB = 'topic2_db'
ORDER BY TIME DESC;

SELECT 
    TABLE_NAME,
    TABLE_ROWS,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS DATA_MB,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS INDEX_MB,
    UPDATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'topic2_db'
ORDER BY TOTAL_MB DESC;


SELECT 
    NOW() AS checked_at,
    TABLE_NAME,
    TABLE_ROWS,
    ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 2) AS TOTAL_MB,
    ROUND(DATA_LENGTH / 1024 / 1024, 2) AS DATA_MB,
    ROUND(INDEX_LENGTH / 1024 / 1024, 2) AS INDEX_MB,
    AUTO_INCREMENT,
    UPDATE_TIME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'topic2_db'
ORDER BY TOTAL_MB DESC;


USE topic2_db;

-- 분석 코호트 기준
SET @pre_start  = '2022-05-01 00:00:00';
SET @pre_end    = '2022-12-01 00:00:00';  -- 2022년 5~11월 가입자

SET @post_start = '2023-05-01 00:00:00';
SET @post_end   = '2023-12-01 00:00:00';  -- 2023년 5~11월 가입자

-- 가입 전 행동을 보조로 볼 경우
SET @pre_signup_days = 7;

-- 가입 후 행동/결제 관찰 기간
SET @activation_days = 7;
SET @payment_days    = 30;


-- 가입 코호트 테이블 생성
DROP TABLE IF EXISTS dm_signup_cohort;

CREATE TABLE dm_signup_cohort AS
SELECT
    user_id,
    signup_time,
    DATE_FORMAT(signup_time, '%Y-%m-01') AS cohort_month,

    CASE
        WHEN signup_time >= @pre_start
         AND signup_time <  @pre_end
            THEN 'pre_2022_05_11'

        WHEN signup_time >= @post_start
         AND signup_time <  @post_end
            THEN 'post_2023_05_11'
    END AS period_group,

    signup_type,
    signup_platform,
    signup_device_type

FROM (
    SELECT
        user_id,
        client_event_time AS signup_time,
        `type` AS signup_type,
        platform AS signup_platform,
        device_type AS signup_device_type,

        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY client_event_time
        ) AS rn

    FROM complete_signup
    WHERE user_id IS NOT NULL
      AND user_id <> ''
      AND client_event_time IS NOT NULL
) s
WHERE rn = 1
  AND (
        (signup_time >= @pre_start  AND signup_time < @pre_end)
     OR (signup_time >= @post_start AND signup_time < @post_end)
  );


-- 인덱스 추가
ALTER TABLE dm_signup_cohort
ADD PRIMARY KEY (user_id),
ADD INDEX idx_signup_time (signup_time),
ADD INDEX idx_cohort_month (cohort_month),
ADD INDEX idx_period_group (period_group);

-- 확인 쿼리
SELECT 
    period_group,
    cohort_month,
    COUNT(*) AS signup_users,
    MIN(signup_time) AS min_signup_time,
    MAX(signup_time) AS max_signup_time
FROM
    dm_signup_cohort
GROUP BY period_group , cohort_month


-- 가입 후 30일 내 첫 결제 테이블 생성
DROP TABLE IF EXISTS dm_first_payment_30d;

CREATE TABLE dm_first_payment_30d AS
SELECT
    user_id,
    first_payment_time,
    first_plan_price,
    first_paid_amount,
    first_discount_amount,
    first_pg_type
FROM (
    SELECT
        b.user_id,
        cs.client_event_time AS first_payment_time,
        cs.`plan.price` AS first_plan_price,
        cs.paid_amount AS first_paid_amount,
        cs.`coupon.discount_amount` AS first_discount_amount,
        cs.`pg.type` AS first_pg_type,

        ROW_NUMBER() OVER (
            PARTITION BY b.user_id
            ORDER BY cs.client_event_time
        ) AS rn

    FROM dm_signup_cohort b
    JOIN complete_subscription cs
        ON b.user_id = cs.user_id
       AND cs.client_event_time >= b.signup_time
       AND cs.client_event_time <  DATE_ADD(b.signup_time, INTERVAL 30 DAY)
    WHERE cs.user_id IS NOT NULL
      AND cs.user_id <> ''
      AND cs.client_event_time IS NOT NULL
) x
WHERE rn = 1;

-- 인덱스 추가
ALTER TABLE dm_first_payment_30d
ADD PRIMARY KEY (user_id),
ADD INDEX idx_first_payment_time (first_payment_time);


-- 획인 쿼리
SELECT
    b.period_group,
    b.cohort_month,
    COUNT(*) AS signup_users,
    COUNT(p.user_id) AS paid_30d_users,
    ROUND(COUNT(p.user_id) / COUNT(*) * 100, 2) AS paid_30d_rate
FROM dm_signup_cohort b
LEFT JOIN dm_first_payment_30d p
    ON b.user_id = p.user_id
GROUP BY b.period_group, b.cohort_month
ORDER BY b.period_group, b.cohort_month;

-- 얇은 통합 로그 테이블 생성
DROP TABLE IF EXISTS event_log_thin_cohort;

CREATE TABLE event_log_thin_cohort (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,

    user_id VARCHAR(255) NOT NULL,
    cohort_month DATE,
    period_group VARCHAR(30),

    event_time DATETIME,
    event_month DATE,
    event_name VARCHAR(80),
    source_table VARCHAR(80),

    content_id VARCHAR(255),
    lesson_id VARCHAR(255),
    question_id VARCHAR(255),
    button_name VARCHAR(255),
    content_difficulty VARCHAR(100),

    signup_type VARCHAR(100),

    plan_price INT,
    paid_amount INT,
    discount_amount INT,
    pg_type VARCHAR(100),

    is_trial VARCHAR(100),
    is_free_trial VARCHAR(100),

    platform VARCHAR(100),
    device_type VARCHAR(100)
);



-- 핵심 이벤트 통합 로그에 넣기
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
    'complete_signup',
    'complete_signup',

    NULL, NULL, NULL, NULL, NULL,
    t.`type`,

    NULL, NULL, NULL, NULL,
    NULL, NULL,

    t.platform,
    t.device_type

FROM complete_signup t
JOIN dm_signup_cohort b
    ON t.user_id = b.user_id
   AND t.client_event_time >= DATE_SUB(b.signup_time, INTERVAL 7 DAY)
   AND t.client_event_time <  DATE_ADD(b.signup_time, INTERVAL 30 DAY);



-- 회원가입 완









