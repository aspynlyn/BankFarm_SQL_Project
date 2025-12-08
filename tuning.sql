db_odd_adv_2reminderCREATE TABLE reminder(
re_id INT PRIMARY KEY AUTO_INCREMENT,
re_title VARCHAR(15) NOT NULL,
re_content VARCHAR(30),
re_created DATETIME CURRENT_TIMESTAMP NOT NULL,
re_date DATE,
re_repeat BOOLEAN DEFAULT FALSE NOT NULL,
re_alarm BOOLEAN DEFAULT FALSE NOT NULL);

SELECT re_id AS id, re_title AS title, re_date AS date
FROM reminder
WHERE re_date LIKE CONCAT('2025','-','%7','-__') AND member_no_login = 18;


SELECT re_id AS id, re_title AS title, re_date AS DATE
FROM reminder;

CREATE TABLE reminder_exception(
re_id INT NOT NULL,
rx_date DATE,
FOREIGN KEY (re_id) REFERENCES reminder(re_id),
PRIMARY KEY (rx_date, re_id)
);

 SELECT r.member_no_login AS memberId,
            r.re_id AS id,
            r.re_title AS title,
            r.re_content AS content,
            r.re_created AS created,
            r.re_start_date AS startDate,
            r.re_end_date AS endDate,
            r.re_alarm AS alarm,
            r.re_repeat AS `repeat`,
            GROUP_CONCAT(DISTINCT rr.rr_dow) AS repeatDow,
            GROUP_CONCAT(DISTINCT rx.rx_exception_date) AS exception_date
        FROM reminder r
        LEFT JOIN reminder_repeat rr ON r.re_id = rr.re_id
        LEFT JOIN reminder_exception rx ON r.re_id = rx.re_id
         AND YEAR(rx.rx_exception_date) = 2025
      AND MONTH(rx.rx_exception_date) = 9
        WHERE(
            (r.re_repeat = 0
            AND YEAR(r.re_start_date) = 2025
            AND MONTH(r.re_start_date) = 8)
        OR
            (r.re_repeat = 1
            AND r.re_start_date < DATE_ADD(CONCAT('2025', '-', '08', '-01'), INTERVAL 1 MONTH)))
        AND r.member_no_login = 37
        GROUP BY r.re_id;

        INSERT INTO `challenge_definition` (`cd_id`, `cd_goal`, `cd_image`, `cd_name`, `cd_reward`, `cd_type`) VALUES
	(1, 250, 'weekly_squat.png', '스쿼트 250개', 20, 'weekly'),
	(2, 100, 'weekly_pushup.png', '푸시업 100개', 30, 'weekly'),
	(3, 10, 'weekly_plank.png', '플랭크 10분', 30, 'weekly'),
	(4, 900, 'competition_walking_15h.png', '산책', 120, 'competition'),
	(5, 1800, 'competition_walking_30h.png', '산책', 150, 'competition'),
	(6, 2700, 'competition_walking_45h.png', '산책', 200, 'competition'),
	(7, 3600, 'competition_walking_60h.png', '산책', 300, 'competition'),
	(8, 30, 'competition_running_30km.png', '러닝', 120, 'competition'),
	(9, 50, 'competition_running_50km.png', '러닝', 150, 'competition'),
	(10, 70, 'competition_running_70km.png', '러닝', 200, 'competition'),
	(11, 100, 'competition_running_100km.png', '러닝', 300, 'competition'),
	(12, 2, 'personal_water.png', '물마시기 2L', 300, 'personal'),
	(13, 100, 'personal_protein.png', '단백질 섭취', 300, 'personal'),
	(14, 200, 'competition_riding_200km.png', '라이딩', 120, 'competition'),
	(15, 400, 'competition_riding_400km.png', '라이딩', 150, 'competition'),
	(16, 600, 'competition_riding_600km.png', '라이딩', 200, 'competition'),
	(17, 800, 'competition_riding_800km.png', '라이딩', 300, 'competition'),
	(18, 1, 'daily_exercise.png', '운동하기', 5, 'daily'),
	(19, 1, 'daily_check.png', '기록하기', 5, 'daily');

SELECT m.food_amount,
m.meal_day,
m.meal_time,
COALESCE(f.carbohydrate, u.carbohydrate) AS carbohydrate,
COALESCE(f.kcal, u.kcal) AS kcal,
COALESCE(f.natrium, u.natrium) AS natrium,
COALESCE(f.protein, u.protein) AS protein,
COALESCE(f.sugar, u.sugar) AS sugar,
COALESCE(f.flag, u.flag) AS flag,
COALESCE(f.food_name, u.food_name) AS foodName
FROM meal_record m
LEFT JOIN meal_food_db f
ON m.food_id IS NOT NULL AND m.food_id = f.food_db_id
LEFT JOIN meal_food_make_db u
       ON m.user_food_id IS NOT NULL AND m.user_food_id = u.user_food_id
WHERE m.meal_day = '2025-10-02'
  AND m.meal_time = '간식'
  AND m.user_id = 3
  AND(food_id IS NULL OR food_id != -10000);

SELECT *
FROM meal_record
WHERE meal_day = '2025-10-01'
  AND meal_time = '아침'
  AND (food_id IS NULL OR food_id != -10000);

SELECT *
FROM inquiry;

INSERT INTO user_role (challenge_code, role_code, user_id)
VALUES
('01', '01', 34),
('02', '01', 35),
('03', '01', 36),
('04', '02', 37),
('01', '01', 38),
('02', '01', 39),
('03', '01', 40),
('04', '01', 41),
('01', '02', 42),
('02', '01', 43),
('03', '01', 44),
('04', '01', 45),
('01', '01', 46),
('02', '02', 47),
('03', '01', 48),
('04', '01', 49),
('01', '01', 50),
('02', '01', 51),
('03', '01', 52),
('04', '02', 53),
('01', '01', 54),
('02', '01', 55),
('03', '01', 56),
('04', '01', 57),
('01', '01', 58),
('02', '02', 59),
('03', '01', 60),
('04', '01', 61),
('01', '01', 62),
('02', '01', 63);

WITH RECURSIVE month_seq AS (
    SELECT DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 6 MONTH), '%Y-%m-01') AS month_start
    UNION ALL
    SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
    FROM month_seq
    WHERE month_start < DATE_FORMAT(CURDATE(), '%Y-%m-01')
)
SELECT
    DATE_FORMAT(ms.month_start, '%Y-%m') AS month,
    COUNT(DISTINCT u.user_id) AS total_user_count,
    COUNT(DISTINCT cp.user_id) AS participated_user_count,
    ROUND(COUNT(DISTINCT cp.user_id) / COUNT(DISTINCT u.user_id) * 100, 1) AS participation_rate
FROM month_seq ms
CROSS JOIN user u
LEFT JOIN challenge_progress cp
    ON cp.start_date BETWEEN ms.month_start AND LAST_DAY(ms.month_start)
GROUP BY ms.month_start
ORDER BY ms.month_start;

        SELECT
        cp.post_id,
        cp.title,
        cc.`name` AS categoryName,
        COUNT(DISTINCT cl.id) AS likeCount,
        cp.created_at
        FROM community_post cp
        JOIN community_category cc ON cp.category_id = cc.category_id
        LEFT JOIN community_like cl ON cp.post_id = cl.post_id
        LEFT JOIN community_comment cm ON cp.post_id = cm.post_id
        WHERE cp.is_deleted = 0
        GROUP BY cp.post_id
        ORDER BY likeCount DESC
        LIMIT 5;

                SELECT
        cp.post_id,
        cp.title,
        cc.name AS categoryName,
        COUNT(DISTINCT cm.comment_id) AS commentCount,
        cp.created_at
        FROM community_post cp
        JOIN community_category cc ON cp.category_id = cc.category_id
        LEFT JOIN community_comment cm ON cp.post_id = cm.post_id
        WHERE cp.is_deleted = false
        GROUP BY cp.post_id
        ORDER BY commentCount DESC
        LIMIT 5;

SELECT ROUND(AVG(user_daily_avg), 1)
FROM (
SELECT AVG(daily_sum) AS user_daily_avg
FROM (
SELECT user_id, DATE(created_at) AS record_date, SUM(duration) AS daily_sum
FROM exercise_record
GROUP BY user_id, DATE(created_at)
) AS daily
GROUP BY user_id
) AS user_avg;

  WITH RECURSIVE month_seq AS (
      SELECT DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 5 MONTH), '%Y-%m-01') AS month_start
      UNION ALL
      SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
      FROM month_seq
      WHERE month_start < DATE_FORMAT(CURDATE(), '%Y-%m-01')
  )
  SELECT DATE_FORMAT(m.month_start, '%Y-%m') AS month,
         COUNT(p.post_id) AS post_count
  FROM month_seq m
  LEFT JOIN community_post p
    ON DATE_FORMAT(p.created_at, '%Y-%m') = DATE_FORMAT(m.month_start, '%Y-%m')
   AND p.is_deleted = false
  GROUP BY month_start;

    SELECT
    c.exercise_name AS exerciseName,
    COUNT(r.exercise_record_id) AS recordCount
  FROM exercise_record r
  JOIN exercise_catalog c
    ON r.exercise_id = c.exercise_id
  GROUP BY c.exercise_name
  ORDER BY recordCount DESC;

    SELECT
    CASE
      WHEN HOUR(start_at) BETWEEN 0 AND 5 THEN '00시~06시'
      WHEN HOUR(start_at) BETWEEN 6 AND 11 THEN '06시~12시'
      WHEN HOUR(start_at) BETWEEN 12 AND 17 THEN '12시~18시'
      ELSE '18~24시'
    END AS time_range,
    COUNT(*) AS count
  FROM exercise_record
  GROUP BY time_range;

    WITH RECURSIVE month_seq AS (
      SELECT DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 5 MONTH), '%Y-%m-01') AS month_start
      UNION ALL
      SELECT DATE_ADD(month_start, INTERVAL 1 MONTH)
      FROM month_seq
      WHERE month_start < DATE_FORMAT(CURDATE(), '%Y-%m-01')
  )
  SELECT DATE_FORMAT(m.month_start, '%Y-%m') AS month,
         COUNT(*) AS record_count
  FROM month_seq m
  LEFT JOIN meal_record_detail md
    ON DATE_FORMAT(meal_day, '%Y-%m') = DATE_FORMAT(m.month_start, '%Y-%m')
  GROUP BY month_start;

  SELECT
    ROUND(AVG(total_carbohydrate), 1) AS avgCarbohydrate,
    ROUND(AVG(total_protein), 1) AS avgProtein,
    ROUND(AVG(total_fat), 1) AS avgFat
  FROM meal_record_detail;

SELECT *
from insr_payment_history;

explain
SELECT c.depo_contract_id,
       c.cust_id,
       cs.depo_payment_day,
       cs.depo_missed_cnt,
       sp.depo_payment_id,
       sp.depo_paid_dt,
       sp.depo_paid_amt,
       sp.depo_payment_yn
FROM depo_contract c
         JOIN depo_contract_savings cs
              ON c.depo_contract_id = cs.depo_contract_id
         JOIN depo_savings_payment sp
              ON c.depo_contract_id = sp.depo_contract_id
WHERE sp.depo_payment_yn = 'N'
  AND sp.depo_paid_dt < CURRENT_DATE()
  AND c.depo_active_cd NOT IN ('CS002','CS003','CS004')
ORDER BY sp.depo_paid_dt;

CREATE INDEX idx_sp_yn_paid_dt_contract
ON depo_savings_payment (
    depo_payment_yn,
    depo_paid_dt,
    depo_contract_id
);

DROP INDEX idx_sp_yn_paid_dt_contract ON depo_savings_payment;


SELECT c.depo_contract_id,
       c.cust_id,
       cs.depo_payment_day,
       cs.depo_missed_cnt,
       sp.depo_payment_id,
       sp.depo_paid_dt,
       sp.depo_paid_amt,
       sp.depo_payment_yn
FROM depo_contract c
         JOIN depo_contract_savings cs
              ON c.depo_contract_id = cs.depo_contract_id
         JOIN depo_savings_payment sp
              ON c.depo_contract_id = sp.depo_contract_id
                  AND sp.depo_payment_yn = 'N'
                  AND sp.depo_paid_dt < CURRENT_DATE()
WHERE c.depo_active_cd = 'CS001'
ORDER BY sp.depo_paid_dt;

    select c.insr_contract_id, h.insr_payment_dt
    from insr_contract c
    join insr_prod p
        ON c.insr_prod_id = p.insr_prod_id
    join insr_payment_history h
    on c.insr_contract_id = h.insinsr_payment_historyr_contract_id
    and h.insr_payment_seq = 10
    WHERE c.insr_contract_num = 'IC20251206263294'
      AND p.part_id = (SELECT part_id from partner where part_code = 'HANHWA_LIFE');

explain
  SELECT
    c.cust_id,
    COUNT(DISTINCT c.insr_contract_id)                         AS contract_cnt,
    SUM(h.insr_expected_amt)                                   AS total_expected_amt,
    SUM(h.insr_paid_amt)                                       AS total_paid_amt,
    SUM(CASE WHEN h.insr_od_yn = 'Y' THEN 1 ELSE 0 END)        AS total_od_cnt,
    SUM(CASE WHEN h.insr_paid_yn = 'N' THEN 1 ELSE 0 END)      AS total_unpaid_cnt,
    MAX(h.insr_payment_dt)                                     AS last_pay_dt,
    MIN(c.insr_contract_dt)                                    AS first_contract_dt
FROM insr_contract c
JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
LEFT JOIN insr_term t
  ON c.insr_contract_id = t.insr_contract_id
WHERE c.insr_contract_dt >= '2018-01-01'
  AND (t.insr_term_tp IS NULL OR t.insr_term_tp != 'CANCEL')   -- 해지/만기 조건 애매
  AND (h.insr_paid_yn = 'N'
       OR (h.insr_od_yn = 'Y' AND h.insr_payment_dt < DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)))
GROUP BY
    c.cust_id
HAVING
    SUM(h.insr_expected_amt) >= 1000000                        -- 고액만
    AND SUM(CASE WHEN h.insr_paid_yn = 'N' THEN 1 ELSE 0 END) >= 3
ORDER BY
    total_unpaid_cnt DESC,
    total_od_cnt DESC;


    SELECT
    pa.part_id,
    pa.part_nm,
    pa.part_tp,
    p.insr_prod_id,
    p.insr_prod_nm,
    DATE_FORMAT(c.insr_contract_dt, '%Y-%m')      AS ym,          -- 월별
    COUNT(DISTINCT c.insr_contract_id)            AS contract_cnt,
    COUNT(h.insr_payment_seq)                     AS payment_cnt,
    SUM(h.insr_expected_amt)                      AS total_expected_amt,
    SUM(h.insr_paid_amt)                          AS total_paid_amt,
    SUM(CASE WHEN h.insr_od_yn = 'Y' THEN 1 ELSE 0 END) AS od_cnt,
    SUM(CASE WHEN h.insr_paid_yn = 'N' THEN 1 ELSE 0 END) AS unpaid_cnt,
    MIN(c.insr_contract_dt)                       AS first_contract_dt,
    MAX(c.insr_contract_dt)                       AS last_contract_dt
FROM insr_contract c
JOIN insr_prod p
  ON c.insr_prod_id = p.insr_prod_id
JOIN partner pa
  ON c.part_id = pa.part_id
LEFT JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
 AND YEAR(h.insr_payment_dt) BETWEEN 2020 AND 2025              -- 넓은 범위
LEFT JOIN part_contract pc
  ON pa.part_id = pc.part_id
 AND c.insr_contract_dt BETWEEN pc.part_start_dt AND pc.part_end_dt
WHERE pa.part_use_yn = 'Y'
  AND p.insr_sale_yn = 'Y'
  AND YEAR(c.insr_contract_dt) BETWEEN 2020 AND 2025            -- YEAR() 함수
  AND (c.insr_active_cd != 'IC004' OR c.insr_active_cd IS NULL) -- 해지 제외
GROUP BY
    pa.part_id,
    pa.part_nm,
    pa.part_tp,
    p.insr_prod_id,
    p.insr_prod_nm,
    DATE_FORMAT(c.insr_contract_dt, '%Y-%m')
HAVING SUM(h.insr_expected_amt) > 0
ORDER BY
    ym ASC,
    pa.part_nm,
    p.insr_prod_nm;


SELECT
c.insr_contract_id,
c.insr_contract_num,
c.cust_id,
c.insr_maturity_dt,
c.insr_renewable_yn,
c.insr_active_cd,
COUNT(*)                           AS unpaid_cnt,
MAX(h.insr_payment_dt)             AS last_unpaid_dt
FROM insr_contract c
JOIN insr_payment_history h
ON c.insr_contract_id = h.insr_contract_id
WHERE c.insr_renewable_yn = 'Y'                        -- 갱신 가능 계약
AND c.insr_maturity_dt BETWEEN CURRENT_DATE()
                         AND DATE_ADD(CURRENT_DATE(), INTERVAL 60 DAY)
                                                      -- 60일 내 만기 예정
AND h.insr_paid_yn = 'N'                               -- 미납
AND YEAR(h.insr_payment_dt) >= 2025                    -- 넓은 기간, 함수
AND c.insr_active_cd = 'CS001'           -- 진행/만기대기 정도만
GROUP BY
c.insr_contract_id,
c.insr_contract_num,
c.cust_id,
c.insr_maturity_dt,
c.insr_renewable_yn,
c.insr_active_cd
HAVING COUNT(*) >= 1
ORDER BY last_unpaid_dt DESC;

SELECT
    c.insr_contract_id,
    c.cust_id,
    h.insr_payment_dt,
    h.insr_expected_amt,
    h.insr_paid_amt
FROM insr_contract c
JOIN partner pa
  ON c.part_id = pa.part_id
JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
WHERE pa.part_code = 'HANHWA_LIFE'
  AND h.insr_paid_yn = 'N'
ORDER BY h.insr_payment_dt;


SELECT
    c.cust_id,
    c.insr_contract_id,
    COUNT(*) AS unpaid_seq_cnt
FROM insr_contract c
JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
WHERE h.insr_paid_yn = 'N'
AND c.insr_active_cd = 'CS001'
GROUP BY c.cust_id, c.insr_contract_id;


SELECT
    c.insr_contract_id,
    c.cust_id,
    COUNT(*) AS remaining_seq_cnt,
    SUM(h.insr_expected_amt) AS remaining_expected_amt
FROM insr_contract c
JOIN insr_payment_history h FORCE INDEX (idx_insr_pay_contract_dt)
  ON c.insr_contract_id = h.insr_contract_id
WHERE h.insr_payment_dt > CURRENT_DATE()
  AND c.insr_active_cd = 'CS001'
GROUP BY c.insr_contract_id, c.cust_id
HAVING remaining_seq_cnt > 0
ORDER BY remaining_expected_amt;

SHOW INDEX FROM insr_payment_history;

ALTER TABLE insr_payment_history
DROP INDEX idx_insr_pay_contract_dt;

ALTER TABLE insr_payment_history
  DROP INDEX idx_insr_pay_dt_contract,
  ADD INDEX idx_insr_pay_contract_dt
    (insr_contract_id, insr_payment_dt);
CREATE INDEX idx_insr_pay_dt_contract
ON insr_payment_history (insr_payment_dt, insr_contract_id);

CREATE INDEX idx_insr_contract_active
ON insr_contract (insr_active_cd, insr_contract_id, cust_id);


ALTER TABLE insr_payment_history
PARTITION BY RANGE COLUMNS (insr_payment_dt) (
    PARTITION p2020 VALUES LESS THAN ('2021-01-01'),
    PARTITION p2021 VALUES LESS THAN ('2022-01-01'),
    PARTITION p2022 VALUES LESS THAN ('2023-01-01'),
    PARTITION p2023 VALUES LESS THAN ('2024-01-01'),
    PARTITION p2024 VALUES LESS THAN ('2025-01-01'),
    PARTITION p2025 VALUES LESS THAN ('2026-01-01'),
    PARTITION pmax  VALUES LESS THAN (MAXVALUE)
);

ALTER TABLE insr_contract
  DROP INDEX idx_insr_contract_active;

  SELECT
    c.insr_contract_id,
    c.cust_id,
    h.insr_payment_seq,
    h.insr_payment_dt,
    h.insr_expected_amt
FROM insr_contract c
JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
WHERE h.insr_payment_dt = (
          SELECT MIN(h2.insr_payment_dt)
          FROM insr_payment_history h2
          WHERE h2.insr_contract_id = c.insr_contract_id
            AND h2.insr_payment_dt >= CURRENT_DATE()
      )
  AND c.insr_active_cd = 'CS001';




SELECT
    c.part_id,
    c.insr_prod_id,
    DATE_FORMAT(h.insr_payment_dt, '%Y-%m') AS pay_month,
    COUNT(*)            AS payment_cnt,
    SUM(h.insr_expected_amt) AS total_expected_amt
FROM insr_contract c
JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
WHERE h.insr_payment_dt BETWEEN '2025-01-01' AND '2025-12-31'
  AND c.insr_active_cd = 'CS001'  -- 활성 계약만
GROUP BY
    c.part_id,
    c.insr_prod_id,
    pay_month
ORDER BY
    c.part_id,
    c.insr_prod_id,
    pay_month;

    SELECT
    c.part_id,
    c.insr_prod_id,
    t.insr_term_tp,                -- 해지/만기 구분
    DATE_FORMAT(t.insr_term_dt, '%Y-%m') AS term_month,
    COUNT(*) AS term_cnt
FROM insr_contract c
JOIN insr_term t
  ON c.insr_contract_id = t.insr_contract_id
WHERE t.insr_term_dt BETWEEN '2025-01-01' AND '2025-12-31'
GROUP BY
    c.part_id,
    c.insr_prod_id,
    t.insr_term_tp,
    term_month
ORDER BY
    c.part_id,
    c.insr_prod_id,
    term_month;


    SELECT
    c.part_id,
    c.insr_prod_id,
    COUNT(*) AS total_contract_cnt,
    SUM(CASE WHEN c.insr_active_cd = 'CS003' THEN 1 ELSE 0 END) AS terminated_cnt,
    SUM(CASE WHEN c.insr_active_cd = 'CS002' THEN 1 ELSE 0 END) AS matured_cnt
FROM insr_contract c
WHERE c.insr_contract_dt BETWEEN '2020-01-01' AND '2025-12-31'
GROUP BY c.part_id, c.insr_prod_id
ORDER BY c.part_id, c.insr_prod_id;


SELECT
  c.insr_contract_id,
  c.cust_id,
  c.part_id,
  c.insr_contract_dt,
  MIN(h.insr_payment_dt) AS first_schedule_dt
FROM insr_contract c
JOIN insr_payment_history h
ON c.insr_contract_id = h.insr_contract_id
WHERE c.insr_contract_dt >= '2025-01-01'
AND c.insr_active_cd = 'CS001'
AND h.insr_payment_dt < CURRENT_DATE()
AND c.part_id = 1
GROUP BY
  c.insr_contract_id,
  c.cust_id,
  c.part_id,
  c.insr_contract_dt
HAVING SUM(CASE WHEN h.insr_paid_yn = 'Y' THEN 1 ELSE 0 END) = 0
ORDER BY c.insr_contract_dt;

ALTER TABLE insr_payment_history
DROP INDEX idx_insr_pay_contract_dt_paid;

-- 계약: 상태 + 계약일 + 조인키
CREATE INDEX idx_insr_contract_active_dt
ON insr_contract (
    insr_active_cd,
    insr_contract_dt,
    insr_contract_id
);

-- 스케줄: 조인키 + 납입일 + 납입여부
CREATE INDEX idx_insr_pay_contract_dt_paid
ON insr_payment_history (
    insr_contract_id,
    insr_payment_dt,
    insr_paid_yn
);


SELECT
  r.fx_currency_id,
  c.fx_currency_nm,
  e.fx_trns_tp,
  DATE_FORMAT(e.fx_trns_dt, '%Y-%m') AS trns_month,
  COUNT(*) AS trns_cnt,
  SUM(e.fx_from_amt) AS total_from_amt,
  SUM(e.fx_to_amt)   AS total_to_amt
FROM fx_currency_exchange e
JOIN fx_rt_history r
ON e.fx_rt_id = r.fx_rt_id
JOIN fx_currency c
ON r.fx_currency_id = c.fx_currency_id
WHERE e.fx_trns_dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
GROUP BY
  r.fx_currency_id,
  c.fx_currency_nm,
  e.fx_trns_tp,
  trns_month
ORDER BY
  r.fx_currency_id,
  trns_month,
  e.fx_trns_tp;

explain
SELECT
s.fx_currency_id,
c.fx_currency_nm,
s.fx_trns_tp,
s.trns_month,
SUM(s.trns_cnt)        AS trns_cnt,
SUM(s.total_from_amt)  AS total_from_amt,
SUM(s.total_to_amt)    AS total_to_amt
FROM (
SELECT
  r.fx_currency_id,
  e.fx_trns_tp,
  DATE_FORMAT(e.fx_trns_dt, '%Y-%m') AS trns_month,
  COUNT(*)          AS trns_cnt,
  SUM(e.fx_from_amt) AS total_from_amt,
  SUM(e.fx_to_amt)   AS total_to_amt
FROM fx_currency_exchange e
JOIN fx_rt_history r
ON e.fx_rt_id = r.fx_rt_id
WHERE e.fx_trns_dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR)
GROUP BY
  r.fx_currency_id,
  e.fx_trns_tp,
  trns_month
) s
JOIN fx_currency c
ON s.fx_currency_id = c.fx_currency_id
GROUP BY
s.fx_currency_id,
c.fx_currency_nm,
s.fx_trns_tp,
s.trns_month
ORDER BY
s.fx_currency_id,
s.trns_month,
s.fx_trns_tp;

ALTER TABLE fx_currency_exchange
DROP INDEX idx_fx_exch_dt_rt_tp;
CREATE INDEX idx_fx_exch_dt_rt_tp_amt
ON fx_currency_exchange (
    fx_trns_dt,      -- WHERE 범위 조건
    fx_rt_id,        -- 조인 키
    fx_trns_tp,      -- GROUP BY
    fx_from_amt,     -- SUM 집계에서 커버링
    fx_to_amt        -- SUM 집계에서 커버링
);


SELECT
    r.fx_currency_id,
    c.fx_currency_nm,
    e.fx_trns_tp,
    YEAR(e.fx_trns_dt)  AS trns_year,
    MONTH(e.fx_trns_dt) AS trns_month,
    COUNT(*) AS trns_cnt,
    SUM(e.fx_from_amt) AS total_from_amt,
    SUM(e.fx_to_amt)   AS total_to_amt
FROM fx_currency_exchange e
JOIN fx_rt_history r
  ON e.fx_rt_id = r.fx_rt_id
JOIN fx_currency c
  ON r.fx_currency_id = c.fx_currency_id
WHERE e.fx_trns_dt >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 month)
GROUP BY
    r.fx_currency_id,
    c.fx_currency_nm,
    e.fx_trns_tp,
    trns_year,
    trns_month
ORDER BY
    r.fx_currency_id,
    trns_year,
    trns_month,
    e.fx_trns_tp;

    CREATE INDEX idx_fx_exch_dt_rt_tp
ON fx_currency_exchange (
    fx_trns_dt,
    fx_rt_id,
    fx_trns_tp
);

SELECT
    e.fx_trns_id,
    e.cust_id,
    e.fx_trns_tp,
    r.fx_currency_id,
    c.fx_currency_nm,
    e.fx_from_amt,
    e.fx_to_amt,
    e.fx_req_dt,
    TIMESTAMPDIFF(MINUTE, e.fx_req_dt, NOW()) AS wait_min
FROM fx_currency_exchange e
JOIN fx_rt_history r
  ON e.fx_rt_id = r.fx_rt_id
JOIN fx_currency c
  ON r.fx_currency_id = c.fx_currency_id
WHERE e.fx_trns_cd = 'ST001'                 -- 예: 진행중
  AND e.fx_req_dt < DATE_SUB(NOW(), INTERVAL 30 MINUTE)
ORDER BY e.fx_req_dt ASC;

explain
SELECT
  e.fx_trns_id,
  e.cust_id,
  e.fx_trns_tp,
  e.fx_trns_cd,
  e.fx_trns_dt,
  e.fx_from_amt,
  e.fx_to_amt
FROM fx_currency_exchange e
WHERE DATE(e.fx_trns_dt) = '2025-12-07'
ORDER BY e.fx_trns_dt DESC;


SELECT
  e.fx_trns_id,
  e.cust_id,
  e.fx_trns_tp,
  e.fx_trns_cd,
  e.fx_trns_dt,
  e.fx_from_amt,
  e.fx_to_amt
FROM fx_currency_exchange e
WHERE e.fx_trns_dt >= '2025-12-07'
AND e.fx_trns_dt <  '2025-12-08'
ORDER BY e.fx_trns_dt DESC;

CREATE INDEX idx_fx_exch_trns_dt
ON fx_currency_exchange (fx_trns_dt);
