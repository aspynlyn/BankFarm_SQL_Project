INSERT INTO partner (part_nm, part_tp, part_use_yn)
VALUES
    ('삼성생명', 'PA003', 'Y'),
    ('한화생명', 'PA003', 'Y'),
    ('교보생명', 'PA003', 'Y'),
    ('DB손해보험', 'PA003', 'Y'),
    ('메리츠화재', 'PA003', 'Y'),
    ('현대해상', 'PA003', 'Y'),
    ('농협손보', 'PA003', 'Y'),
    ('흥국생명', 'PA003', 'Y'),
    ('라이나생명', 'PA003', 'N'),
    ('푸본현대생명', 'PA003', 'N');

INSERT INTO part_contract (part_id, part_start_dt, part_end_dt, part_active_yn)
VALUES
-- 1 삼성생명: 현재 살아있는 계약(Y)
(1, '2023-01-01', '2026-12-31', 'Y'),

-- 2 한화생명: 현재 살아있는 계약(Y)
(2, '2024-03-01', '2027-02-28', 'Y'),

-- 3 교보생명: 종료된 계약(N)
(3, '2020-05-01', '2022-05-01', 'N'),
-- 3 교보생명: 새로 다시 계약(Y)
(3, '2023-06-01', '2026-06-01', 'Y'),

-- 4 DB손해보험: 현재 살아있는 계약(Y)
(4, '2022-10-01', '2025-10-01', 'Y'),

-- 5 현대해상: 종료된 계약(N)
(5, '2019-08-15', '2021-08-15', 'N'),

-- 6 메리츠화재: 현재 살아있는 계약(Y)
(6, '2023-04-01', '2026-04-01', 'Y'),

-- 7 흥국생명: 종료된 계약(N)
(7, '2021-01-10', '2023-01-10', 'N'),

-- 8 농협손해보험: 현재 살아있는 계약(Y)
(8, '2024-01-01', '2027-01-01', 'Y'),

-- 9 롯데손해보험: 종료(N)
(9, '2020-09-01', '2022-09-01', 'N'),

-- 10 케이비손해보험: 현재 살아있는 계약(Y)
(10, '2023-11-01', '2026-11-01', 'Y');

UPDATE partner
SET part_code = CASE part_nm
    WHEN '삼성생명'     THEN 'SAMSUNG_LIFE'
    WHEN '한화생명'     THEN 'HANHWA_LIFE'
    WHEN '교보생명'     THEN 'KYOBO_LIFE'
    WHEN 'DB손해보험'   THEN 'DB_SGI'
    WHEN '메리츠화재'   THEN 'MERITZ_FIRE'
    WHEN '현대해상'     THEN 'HYUNDAI_MARINE'
    WHEN '농협손보'     THEN 'NH_FARM_INS'
    WHEN '흥국생명'     THEN 'HEUNGKUK_LIFE'
    WHEN '라이나생명'   THEN 'LINA_LIFE'
    WHEN '푸본현대생명' THEN 'FUBON_HYUNDAI_LIFE'
    ELSE part_code  -- 혹시 다른 제휴사 있을 때 기존 값 유지
END
WHERE part_code IS NULL;