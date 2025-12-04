-- 예적금 계약 테이블 인서트 트리거(계약서 보관 테이블)
DELIMITER $$

CREATE TRIGGER trg_insert_depo_contract
    AFTER INSERT
    ON depo_contract
    FOR EACH ROW
BEGIN
    DECLARE v_bran_id BIGINT;
    DECLARE v_prod_tp VARCHAR(5);
    DECLARE v_doc_nm VARCHAR(20);

    -- NEW.emp_id 기준으로 직원 테이블에서 지점 ID 조회
    SELECT e.bran_id
    INTO v_bran_id
    FROM employees e
    WHERE e.emp_id = NEW.emp_id;

    -- 상품 타입에 따른 계약 문서 명 저장
    SELECT p.depo_prod_tp
    INTO v_prod_tp
    FROM depo_prod p
    WHERE p.depo_prod_id = NEW.depo_prod_id;

    IF v_prod_tp = 'DO001' THEN
        SET v_doc_nm = '요구불 계약 문서';
    ELSEIF v_prod_tp = 'DO002' THEN
        SET v_doc_nm = '정기 예금 계약 문서';
    ELSEIF v_prod_tp = 'DO003' THEN
        SET v_doc_nm = '정기 적금 계약 문서';
    ELSEIF v_prod_tp = 'DO004' THEN
        SET v_doc_nm = '자유 적금 계약 문서';
    END IF;


    INSERT INTO prod_document (bran_id,
                               doc_prod_tp,
                               doc_prod_id,
                               doc_nm)
    VALUES (v_bran_id,
            'PD006',
            NEW.depo_contract_id,
            v_doc_nm);

END$$

DELIMITER ;

-- 정기예금 예치 테이블 인서트 트리거(입출금 테이블)
DELIMITER $$

CREATE TRIGGER trg_insert_depo_contract_deposit
    AFTER INSERT
    ON depo_contract_deposit
    FOR EACH ROW

BEGIN

    DECLARE v_cash_yn CHAR(1);
    DECLARE v_base_acct_id BIGINT;
    DECLARE v_base_acct_num VARCHAR(20);
    DECLARE v_base_acct_bal BIGINT;
    DECLARE v_contract_acct_id BIGINT;
    DECLARE v_contract_acct_num VARCHAR(20);
    DECLARE v_contract_acct_bal BIGINT;

    -- 현금 납입 여부, 계약한 계좌 pk, 납입 한 계좌 pk 조회
    SELECT depo_paid_cash_yn, acct_id, depo_base_acct_id
    INTO v_cash_yn, v_contract_acct_id, v_base_acct_id
    FROM depo_contract
    WHERE depo_contract_id = NEW.depo_contract_id;

    IF v_cash_yn = 'N' THEN

        -- 예치금 납입 계좌 번호, 잔액 조회
        SELECT acct_num, acct_bal
        INTO v_base_acct_num, v_base_acct_bal
        FROM account
        WHERE acct_id = v_base_acct_id;

        -- 예금 계약 계좌 번호, 잔액 조회
        SELECT acct_num, acct_bal
        INTO v_contract_acct_num, v_contract_acct_bal
        FROM account
        WHERE acct_id = v_contract_acct_id;

        -- 납입 계좌 -> 예금 계좌 출금 내역 넣기
        INSERT INTO transaction(acct_id,
                                trns_fee_id,
                                trns_amt,
                                trns_acct_num,
                                trns_bal,
                                trns_tp,
                                trns_des)
        VALUES (v_base_acct_id,
                1,
                -new.depo_prncp_amt,
                v_contract_acct_num,
                v_base_acct_bal - new.depo_prncp_amt,
                2,
                '예치금 납입');

        -- 예금 계좌 입금 내역 넣기
        INSERT INTO transaction(acct_id,
                                trns_fee_id,
                                trns_amt,
                                trns_acct_num,
                                trns_bal,
                                trns_tp,
                                trns_des)
        VALUES (v_contract_acct_id,
                1,
                new.depo_prncp_amt,
                v_base_acct_num,
                v_contract_acct_bal + new.depo_prncp_amt,
                1,
                '예치금 납입');
    END IF;

END$$

DELIMITER ;

-- 적금 납입(자유) 테이블 인서트 트리거(입출금 테이블)
DELIMITER $$

CREATE TRIGGER trg_insert_depo_savings_payment
    AFTER INSERT
    ON depo_savings_payment
    FOR EACH ROW

BEGIN

    DECLARE v_cash_yn CHAR(1);
    DECLARE v_base_acct_id BIGINT;
    DECLARE v_base_acct_num VARCHAR(20);
    DECLARE v_base_acct_bal BIGINT;
    DECLARE v_contract_acct_id BIGINT;
    DECLARE v_contract_acct_num VARCHAR(20);
    DECLARE v_contract_acct_bal BIGINT;

    -- 현금 납입 여부, 계약한 계좌 pk, 납입 한 계좌 pk 조회
    SELECT depo_paid_cash_yn, acct_id, depo_base_acct_id
    INTO v_cash_yn, v_contract_acct_id, v_base_acct_id
    FROM depo_contract
    WHERE depo_contract_id = NEW.depo_contract_id;

    IF new.depo_payment_yn = 'Y' AND v_cash_yn = 'N' THEN

        -- 예치금 납입 계좌 번호, 잔액 조회
        SELECT acct_num, acct_bal
        INTO v_base_acct_num, v_base_acct_bal
        FROM account
        WHERE acct_id = v_base_acct_id;

        -- 예금 계약 계좌 번호, 잔액 조회
        SELECT acct_num, acct_bal
        INTO v_contract_acct_num, v_contract_acct_bal
        FROM account
        WHERE acct_id = v_contract_acct_id;

        -- 납입 계좌 -> 예금 계좌 출금 내역 넣기
        INSERT INTO transaction(acct_id,
                                trns_fee_id,
                                trns_amt,
                                trns_acct_num,
                                trns_bal,
                                trns_tp,
                                trns_des)
        VALUES (v_base_acct_id,
                1,
                -new.depo_paid_amt,
                v_contract_acct_num,
                v_base_acct_bal - new.depo_paid_amt,
                2,
                '적금 납입');

        -- 예금 계좌 입금 내역 넣기
        INSERT INTO transaction(acct_id,
                                trns_fee_id,
                                trns_amt,
                                trns_acct_num,
                                trns_bal,
                                trns_tp,
                                trns_des)
        VALUES (v_contract_acct_id,
                1,
                new.depo_paid_amt,
                v_base_acct_num,
                v_contract_acct_bal + new.depo_paid_amt,
                1,
                '적금 납입');
    END IF;
END$$

DELIMITER ;

-- 적금 납입(정기) 테이블 업데이트 트리거(입출금 테이블)
DELIMITER $$

CREATE TRIGGER trg_update_depo_savings_payment
    AFTER UPDATE
    ON depo_savings_payment
    FOR EACH ROW

BEGIN

    DECLARE v_cash_yn CHAR(1);
    DECLARE v_base_acct_id BIGINT;
    DECLARE v_base_acct_num VARCHAR(20);
    DECLARE v_base_acct_bal BIGINT;
    DECLARE v_contract_acct_id BIGINT;
    DECLARE v_contract_acct_num VARCHAR(20);
    DECLARE v_contract_acct_bal BIGINT;

    -- 현금 납입 여부, 계약한 계좌 pk, 납입 한 계좌 pk 조회
    SELECT depo_paid_cash_yn, acct_id, depo_base_acct_id
    INTO v_cash_yn, v_contract_acct_id, v_base_acct_id
    FROM depo_contract
    WHERE depo_contract_id = NEW.depo_contract_id;

    IF old.depo_payment_yn != 'Y' AND
       new.depo_payment_yn = 'Y' AND
       v_cash_yn = 'N' THEN

        -- 예치금 납입 계좌 번호, 잔액 조회
        SELECT acct_num, acct_bal
        INTO v_base_acct_num, v_base_acct_bal
        FROM account
        WHERE acct_id = v_base_acct_id;

        -- 예금 계약 계좌 번호, 잔액 조회
        SELECT acct_num, acct_bal
        INTO v_contract_acct_num, v_contract_acct_bal
        FROM account
        WHERE acct_id = v_contract_acct_id;

        -- 납입 계좌 -> 예금 계좌 출금 내역 넣기
        INSERT INTO transaction(acct_id,
                                trns_fee_id,
                                trns_amt,
                                trns_acct_num,
                                trns_bal,
                                trns_tp,
                                trns_des)
        VALUES (v_base_acct_id,
                1,
                -new.depo_paid_amt,
                v_contract_acct_num,
                v_base_acct_bal - new.depo_paid_amt,
                2,
                '적금 납입');

        -- 예금 계좌 입금 내역 넣기
        INSERT INTO transaction(acct_id,
                                trns_fee_id,
                                trns_amt,
                                trns_acct_num,
                                trns_bal,
                                trns_tp,
                                trns_des)
        VALUES (v_contract_acct_id,
                1,
                new.depo_paid_amt,
                v_base_acct_num,
                v_contract_acct_bal + new.depo_paid_amt,
                1,
                '적금 납입');
    END IF;
END$$

DELIMITER ;
