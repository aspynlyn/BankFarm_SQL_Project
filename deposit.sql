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
SELECT *
FROM prod_document
where doc_prod_id = 300515
and doc_prod_tp = 'PD006';

DELETE
FROM prod_document
where doc_prod_id = 300515
and doc_prod_tp = 'PD006';

SELECT *
from depo_prod
where depo_prod_id = 402;
SELECT *
FROM depo_contract
where depo_contract_id = 300513;

DELETE from depo_savings_payment;

DELETE from depo_contract_deposit;

DELETE
FROM depo_contract
where depo_contract_id = 300515;

SELECT *
from account
where acct_id = 300517;

DELETE
from account
where acct_id = 300517;

delete
from transaction
where acct_id = 300517;

SELECT prod_id
from prod_rate
where prod_tp = 'RT006'
GROUP BY prod_id;

        SELECT count(depo_prod_id)
        FROM depo_prod
        WHERE depo_prod_tp = 'DO001';

SELECT *
from prod_document
where doc_nm = '정기 적금 계약 문서 제목'
or doc_nm = '정기 예금 계약 문서 제목'
or doc_nm = '자유 적금 계약 문서 제목';

# 301304

SELECT *
from depo_contract
where depo_contract_id = 301304;

UPDATE depo_contract
set depo_applied_intrst_rt = 2.1349
where depo_contract_id BETWEEN 301102 and 301304;
# 301102
# 363861

# 377761