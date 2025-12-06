DELETE
FROM insr_payment_history
;

SELECT i.insr_contract_id, i.insr_contract_dt, e.bran_id
FROM insr_contract i
         JOIN employees e
              ON i.emp_id = e.emp_id;

SELECT c.insr_contract_id, insr_payment_dt
FROM insr_contract c
         JOIN insr_payment_history p
              ON c.insr_contract_id = p.insr_contract_id
                  AND insr_payment_seq = p_insr_payment_seq
WHERE insr_contract_num = p_insr_constract_num
  AND insr_bank_cd = p_bank_cd;