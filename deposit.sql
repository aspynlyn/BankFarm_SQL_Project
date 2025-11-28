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

# 우대금리 계산
SELECT p.prod_id,
       SUM(r.rt_pct) AS total_pref_rate
FROM rate_rule r
         JOIN prod_rate p
              ON p.prod_rt_id = r.rt_id
WHERE p.prod_id = 400
  AND p.prod_tp = 'RT006'
GROUP BY p.prod_id;

select emp_id
from employees
where bran_id > 264;

# 384 683
        SELECT p.prod_id,
            SUM(r.rt_pct) AS total_pref_rate
        FROM rate_rule r
        JOIN prod_rate p
        ON p.prod_rt_id = r.rt_id
        WHERE p.prod_id = 444
        AND p.prod_tp = 'RT006'
        GROUP BY p.prod_id;

# 계좌 아이디 300511
# 계약 아이디 300509
# 상품 아이디 458
DELETE
FROM prod_document
where doc_prod_id = 458
and doc_prod_tp = 'PD006'
and doc_nm like '%자유%';

DELETE
FROM depo_contract
where depo_contract_id = 300509;