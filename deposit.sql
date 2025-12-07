DELETE
FROM depo_prod
WHERE depo_prod_tp != 'DO001';

SELECT rt_id
FROM rate_rule
WHERE rt_tp = 'RT001';

DELETE
FROM prod_rate;
SELECT COUNT(1)
FROM prod_rate
GROUP BY prod_id;

-- # 우대금리 계산
SELECT p.prod_id,
       SUM(r.rt_pct) AS total_pref_rate
FROM rate_rule r
         JOIN prod_rate p
              ON p.prod_rt_id = r.rt_id
WHERE p.prod_id = 400
  AND p.prod_tp = 'RT006'
GROUP BY p.prod_id;

SELECT emp_id
FROM employees
WHERE bran_id > 264;

-- # 384 683
SELECT p.prod_id,
       SUM(r.rt_pct) AS total_pref_rate
FROM rate_rule r
         JOIN prod_rate p
              ON p.prod_rt_id = r.rt_id
WHERE p.prod_id = 444
  AND p.prod_tp = 'RT006'
GROUP BY p.prod_id;

-- # 계좌 아이디 300511
-- # 계약 아이디 300509
-- # 상품 아이디 458
SELECT *
FROM prod_document
WHERE doc_prod_id = 300515
  AND doc_prod_tp = 'PD006';

DELETE
FROM prod_document
WHERE doc_prod_id = 300515
  AND doc_prod_tp = 'PD006';

SELECT *
FROM depo_prod
WHERE depo_prod_id = 402;
SELECT *
FROM depo_contract
WHERE depo_contract_id = 300513;

DELETE
FROM depo_savings_payment;

DELETE
FROM depo_contract_deposit;

DELETE
FROM depo_contract
WHERE depo_contract_id = 300515;

SELECT *
FROM account
WHERE acct_id = 300517;

DELETE
FROM account
WHERE acct_id = 300517;

DELETE
FROM transaction
WHERE acct_id = 300517;

SELECT prod_id
FROM prod_rate
WHERE prod_tp = 'RT006'
GROUP BY prod_id;

SELECT COUNT(depo_prod_id)
FROM depo_prod
WHERE depo_prod_tp = 'DO001';

SELECT *
FROM prod_document
WHERE doc_nm = '정기 적금 계약 문서 제목'
   OR doc_nm = '정기 예금 계약 문서 제목'
   OR doc_nm = '자유 적금 계약 문서 제목';

SELECT *
FROM depo_contract
WHERE depo_contract_id = 301304;

UPDATE depo_contract
SET depo_applied_intrst_rt = 2.1349
WHERE depo_contract_id BETWEEN 301102 AND 301304;

UPDATE depo_contract d JOIN depo_prod p ON p.depo_prod_id = d.depo_prod_id LEFT JOIN (SELECT cust_id, MIN(acct_id) AS base_acct_id
                                                                                      FROM account
                                                                                      WHERE acct_is_ded_yn = 'Y'
                                                                                      GROUP BY cust_id) a ON a.cust_id = d.cust_id
SET d.depo_base_acct_id = a.base_acct_id
WHERE d.depo_base_acct_id IS NULL
  AND p.depo_prod_tp != 'DO001';

UPDATE depo_prod
SET depo_intrst_calc_tp = 'DO026'
WHERE depo_prod_tp = 'DO001';

EXPLAIN
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
  AND DATE(sp.depo_paid_dt) < CURRENT_DATE()
  AND c.depo_active_cd != 'CS002'
  AND c.depo_active_cd != 'CS003'
  AND c.depo_active_cd != 'CS004'
ORDER BY sp.depo_paid_dt;

EXPLAIN
SELECT
    c.depo_contract_id,
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