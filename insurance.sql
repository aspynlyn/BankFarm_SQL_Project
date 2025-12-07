DELETE
FROM insr_payment_history
;

SELECT i.insr_contract_id, i.insr_contract_dt, e.bran_id
FROM insr_contract i
         JOIN employees e
              ON i.emp_id = e.emp_id;

SELECT *
from insr_contract
where insr_contract_id = 251126;
select *
from insr_payment_history
where insr_contract_id = 251126;

SELECT *
FROM insr_contract
WHERE insr_contract_num = 'IC20251206263294'
  AND part_id = 1;

    SELECT c.insr_contract_id, p.insr_payment_dt
    FROM insr_contract c
             JOIN insr_payment_history p
                  ON c.insr_contract_id = p.insr_contract_id
                      AND p.insr_payment_seq = 1
    WHERE c.insr_contract_num = 'IC20251206263294'
      AND c.part_id = 1;

    select c.insr_contract_id, h.insr_payment_dt
    from insr_contract c
    join insr_prod p
        ON c.insr_prod_id = p.insr_prod_id
    join insr_payment_history h
    on c.insr_contract_id = h.insr_contract_id
    and h.insr_payment_seq = 10
    WHERE c.insr_contract_num = 'IC20251206263294'
      AND p.part_id = (SELECT part_id from partner where part_code = 'HANHWA_LIFE');

Explain ANALYZE
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
JOIN insr_payment_history h
  ON c.insr_contract_id = h.insr_contract_id
WHERE h.insr_payment_dt > CURRENT_DATE()
  AND c.insr_active_cd = 'CS001'
GROUP BY c.insr_contract_id, c.cust_id
HAVING remaining_seq_cnt > 0
ORDER BY remaining_expected_amt DESC;