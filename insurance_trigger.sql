-- 보험 계약 테이블 업데이트(보험사 승인 후) 트리거(계약서 보관 테이블)
DELIMITER $$

CREATE TRIGGER trg_insert_insr_contract
    AFTER UPDATE
    ON insr_contract
    FOR EACH ROW
BEGIN
    DECLARE v_bran_id BIGINT;

    IF OLD.insr_approval_cd != 'AP002'
        AND NEW.insr_approval_cd = 'AP002' THEN

        -- NEW.emp_id 기준으로 직원 테이블에서 지점 ID 조회
        SELECT e.bran_id
        INTO v_bran_id
        FROM employees e
        WHERE e.emp_id = NEW.emp_id;

        INSERT INTO prod_document (bran_id,
                                   doc_prod_tp,
                                   doc_prod_id,
                                   doc_nm)
        VALUES (v_bran_id,
                'PD009',
                NEW.insr_contract_id,
                '보험 계약 문서');

    END IF;

END$$

DELIMITER ;