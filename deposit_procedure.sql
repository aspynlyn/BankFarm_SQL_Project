-- 계좌 상태 확인 및 고객 일치 확인 프로시저
CREATE PROCEDURE sp_validate_account_owner (
      IN p_acct_id BIGINT
    , IN p_cust_id BIGINT
)
BEGIN
    DECLARE v_cust_id BIGINT;
    DECLARE v_status  VARCHAR(5);

    SELECT cust_id, acct_sts_cd
      INTO v_cust_id, v_status
      FROM account
     WHERE acct_id = p_acct_id
     FOR UPDATE;

    IF v_status = 'AS002' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌 비활성화 상태';
    END IF;

        IF v_status = 'AS003' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌 휴면 상태';
    END IF;

        IF v_status = 'AS004' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌 법적 동결 상태';
    END IF;

        IF v_status = 'AS005' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '해지된 계좌';
    END IF;

    IF v_cust_id != p_cust_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계약 고객과 계좌 소유자 불일치';
    END IF;

END;

DELIMITER $$

-- 계좌 잔액 확인(출금용) 프로시저
CREATE PROCEDURE sp_account_debit (
      IN  p_acct_id       BIGINT
    , IN  p_amt        BIGINT
)
BEGIN
    DECLARE v_bal BIGINT;

    SELECT acct_bal
      INTO v_bal
      FROM account
     WHERE acct_id = p_acct_id
     FOR UPDATE;

    IF v_bal < p_amt THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '잔액 부족';
    END IF;

END;

-- 입출금 내역 인서트 프로시저
CREATE PROCEDURE sp_insert_tran_history (
      IN p_acct_id   BIGINT
    , IN p_amt    BIGINT
    , in p_acct_num varchar(20)
    , IN p_bal   BIGINT
    , IN p_trns_tp   TINYINT
    , IN p_des       VARCHAR(30)
)
BEGIN
    INSERT INTO transaction (
          acct_id
        , trns_fee_id
        , trns_amt
        , trns_acct_num
        , trns_bal
        , trns_tp
        , trns_crt_at
        , trns_des
    ) VALUES (
          p_acct_id
        , 0
        , p_amt
        , p_acct_num
        , p_bal
        , p_trns_tp
        , NOW()
        , p_des
    );
END;

-- 적금 계약 프로시저
CREATE PROCEDURE sp_open_savings_contract (
      IN  p_cust_id        BIGINT
    , IN  p_depo_prod_id   BIGINT
    , IN  p_acct_num       varchar(20)          -- 생성할 계좌 번호
    , IN  p_base_acct_id   BIGINT          -- 결제 계좌(요구불), 현금이면 NULL
    , IN  p_monthly_amt    BIGINT          -- 월 납입액
    , IN  p_emp_id         BIGINT
    , IN  p_payment_day    TINYINT         -- 1~28
    , OUT p_depo_contract_id BIGINT
)
BEGIN
    DECLARE v_min_amt INT;
    DECLARE v_max_amt INT;
    DECLARE v_depo_rt DECIMAL(6,4);
    DECLARE v_sale_yn CHAR(1);
    DECLARE v_contract_dt DATE;
    DECLARE v_maturity_dt DATE;
    DECLARE v_balance_after BIGINT;
    DECLARE v_prod_tp VARCHAR(5);
    DECLARE v_term_month INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_depo_contract_id = NULL;
    END;

    SET v_contract_dt = CURRENT_DATE();

    START TRANSACTION;

    -- 1. 상품 + 조건 + 기본 금리 조회
    SELECT dp.depo_prod_tp
         , dp.depo_sale_yn
         , dt.depo_min_amt
         , dt.depo_max_amt
         , dt.depo_term_month
         , br.base_rt
      INTO v_prod_tp
         , v_sale_yn
         , v_min_amt
         , v_max_amt
         , v_term_month
         , v_depo_rt
      FROM depo_prod dp
      JOIN depo_prod_term dt
        ON dp.depo_prod_id = dt.depo_prod_id
      JOIN base_rate br
        ON dp.depo_prod_id = br.depo_prod_id
     WHERE dp.depo_prod_id = p_depo_prod_id
     FOR UPDATE;

    -- 2. 판매중 여부
    IF v_sale_yn <> 'Y' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '판매 중지 상품';
    END IF;

    -- 3. 상품 타입이 "정기 적금"인지 체크 (코드는 네가 쓰는 걸로)
    IF v_prod_tp <> 'DO003' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '정기 적금 상품이 아님';
    END IF;

    -- 4. 월 납입액이 최소/최대 범위 안인지
    IF p_monthly_amt < v_min_amt OR p_monthly_amt > v_max_amt THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '월 납입액 범위 초과';
    END IF;

    -- 5. 결제 계좌에서 첫 회차 납입 출금 (현금이면 스킵)
    IF p_base_acct_id IS NOT NULL THEN
        CALL sp_validate_account_owner(
              p_base_acct_id,
              p_cust_id
        );

        CALL sp_account_debit(
              p_base_acct_id,
              p_monthly_amt,
              v_balance_after
        );

        CALL sp_insert_tran_history(
              p_base_acct_id,
              2,  -- 출금
              p_monthly_amt,
              v_balance_after,
              '정기적금 1회차 납입 출금'
        );
    END IF;

    -- 6. 만기일 = 계약일 + 상품 기간(개월)
    SET v_maturity_dt = DATE_ADD(v_contract_dt, INTERVAL v_term_month MONTH);

    -- 7. 예적금 공통 계약(depo_contract) INSERT
    INSERT INTO depo_contract (
          cust_id
        , depo_prod_id
        , acct_id
        , depo_base_acct_id
        , emp_id
        , depo_contract_dt
        , depo_maturity_dt
        , depo_applied_intrst_rt
        , depo_active_cd
    ) VALUES (
          p_cust_id
        , p_depo_prod_id
        , p_acct_id
        , p_base_acct_id
        , p_emp_id
        , v_contract_dt
        , v_maturity_dt
        , v_depo_rt
        , 'CS001'
    );

    SET p_depo_contract_id = LAST_INSERT_ID();

    -- 8. 적금 계약 상세(depo_contract_savings) INSERT
    INSERT INTO depo_contract_savings (
          depo_contract_id
        , depo_missed_cnt
        , depo_payment_day
        , depo_monthly_amt
    ) VALUES (
          p_depo_contract_id
        , 0                -- 미납 횟수 초기값
        , p_payment_day    -- 매달 납입일(1~28)
        , p_monthly_amt
    );

    -- 9. 첫 회차 납입 내역(depo_savings_payment) INSERT
    INSERT INTO depo_savings_payment (
          depo_contract_id
        , depo_pay_dt
        , depo_pay_amt
        , depo_payment_yn
    ) VALUES (
          p_depo_contract_id
        , v_contract_dt
        , p_monthly_amt
        , CASE WHEN p_base_acct_id IS NOT NULL THEN 'Y' ELSE 'Y' END
          -- 지금은 계약 시점에 무조건 납입했다고 가정
    );

    COMMIT;
END $$

DELIMITER ;