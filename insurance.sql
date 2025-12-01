DELETE
FROM insr_payment_history
;

SELECT i.insr_contract_id, i.insr_contract_dt, e.bran_id
FROM insr_contract i
         JOIN employees e
              ON i.emp_id = e.emp_id;
