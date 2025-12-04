-- 계좌 상태 확인 및 고객 일치 확인 프로시저
CREATE PROCEDURE proc_depo_account_owner(
    IN p_acct_id BIGINT
, IN p_cust_id BIGINT
)
BEGIN
    DECLARE v_cust_id BIGINT;
    DECLARE v_status VARCHAR(5);

    SELECT cust_id, acct_sts_cd
    INTO v_cust_id, v_status
    FROM account
    WHERE acct_id = p_acct_id
        FOR
    UPDATE;

    IF v_status = 'AS002' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌가 비활성화 상태입니다.';
    END IF;

    IF v_status = 'AS003' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌가 휴면 상태입니다.';
    END IF;

    IF v_status = 'AS004' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌가 법적 동결 상태입니다.';
    END IF;

    IF v_status = 'AS005' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '해지된 계좌입니다.';
    END IF;

    IF v_cust_id != p_cust_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계약 고객과 계좌 소유자가 일치하지 않습니다.';
    END IF;

END;

DELIMITER $$

-- 계좌 잔액 확인(출금용) 프로시저
CREATE PROCEDURE proc_depo_account_debit(
    IN p_acct_id BIGINT
, IN p_amt BIGINT
)
BEGIN
    DECLARE v_bal BIGINT;

    SELECT acct_bal
    INTO v_bal
    FROM account
    WHERE acct_id = p_acct_id
        FOR
    UPDATE;

    IF v_bal < p_amt THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '잔액이 부족합니다.';
    END IF;

END;

-- 에적금 계약 메인 엔트리(예적금/요구불 계약 + 계좌 생성 공통 처리)

DELIMITER $$

CREATE PROCEDURE proc_depo_open_contract(
    IN p_cust_id BIGINT, -- 계약 고객 ID
    IN p_depo_prod_id BIGINT, -- 예적금/요구불 상품 ID
    IN p_emp_id BIGINT, -- 담당 직원 ID
    IN p_acct_pw VARCHAR(64), -- 계좌 비밀번호(암호화 후)
    IN p_acct_day_limit BIGINT, -- 일일 출금 한도
    IN p_depo_prncp_amt BIGINT, -- 예치/납입 금
    IN p_depo_paid_cash_yn CHAR(1), -- 현금 납입 계약 여부(Y/N)
    IN p_base_acct_id BIGINT, -- 출금 계좌 ID (현금이면 NULL 허용)
    in p_intrst_rt DECIMAL(6,4), -- 적용 금리(고객마다 다름 백에서 계산 한 값)
    in p_payment_day TINYINT, -- 납입일(정기 적금만 해당)
    OUT o_depo_contract_id BIGINT, -- 생성된 계약 ID
    OUT o_contract_acct_id BIGINT, -- 생성된 계좌 ID
    OUT o_contract_acct_num VARCHAR(20) -- 생성된 계약 계좌번호
)
BEGIN
    DECLARE v_sale_yn CHAR(1);
    DECLARE v_prod_tp VARCHAR(5);
    DECLARE v_min_amt BIGINT;
    DECLARE v_max_amt BIGINT;
    DECLARE v_contract_acct_id BIGINT;
    DECLARE v_contract_acct_num VARCHAR(20);
    DECLARE v_contract_acct_tp VARCHAR(5);
    DECLARE v_contract_ded_yn CHAR(1);
    DECLARE v_term_month int;
    DECLARE v_maturity_dt date;
    DECLARE v_payout_tp VARCHAR(5);
    DECLARE v_exists_cnt INT DEFAULT 0;
    DECLARE v_prefix7 VARCHAR(7);
    DECLARE v_mid2 VARCHAR(2);
    DECLARE v_suffix5 VARCHAR(5);

    -- 1. 상품 활성화 여부 조회
    SELECT depo_sale_yn, depo_prod_tp
    INTO v_sale_yn, v_prod_tp
    FROM depo_prod
    WHERE depo_prod_id = p_depo_prod_id;

    -- 상품 존재 여부 체크
    IF v_sale_yn = 'N' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '판매하지 않는 예적금/요구불 상품입니다.';
    END IF;

    -- 현금 납입 여부 값 체크
    IF p_depo_paid_cash_yn NOT IN ('Y', 'N') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '현금 납입 여부 값이 잘못되었습니다. (Y/N)';
    END IF;

    -- 계좌에서 출금하는 계약인데 출금 계좌가 없으면 에러
    IF p_depo_paid_cash_yn = 'N' AND p_base_acct_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '계좌 납입인데 출금 계좌 ID가 없습니다.';
    END IF;

    -- 예치/납입 금액 기본 검증
    IF p_depo_prncp_amt <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = '예치/납입 금액이 잘못되었습니다.';
    END IF;

    -- 최대, 최소 예치 금액 검증(요구불 제외)
    IF v_prod_tp IN ('DO002', 'DO003', 'DO004') THEN

        -- 상품 상세 테이블에서 min/max만 세부 조회
        SELECT depo_min_amt, depo_max_amt
          INTO v_min_amt, v_max_amt
          FROM depo_prod_term
         WHERE depo_prod_id = p_depo_prod_id;

        IF v_min_amt IS NULL AND v_max_amt IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = '해당 상품에 대한 금액 제한 정보가 없습니다';
        END IF;

        IF p_depo_prncp_amt < v_min_amt THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = '상품 최소 가입 금액을 미달했습니다.';
        END IF;

        -- 최대 금액 초과 체크 (최대 금액이 NULL이면 “상한 없음” → 체크 스킵)
        IF v_max_amt IS NOT NULL
           AND p_depo_prncp_amt > v_max_amt THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = '상품 최대 가입 금액을 초과했습니다.';
        END IF;

END IF;

    -- 2. 출금 계좌 검증 (현금 납입이 아닐 때만)
    IF p_depo_paid_cash_yn = 'N' THEN
        -- 계좌 상태/소유자 확인
        CALL proc_depo_account_owner(p_base_acct_id, p_cust_id);
        -- 잔액 확인 (최초 예치/납입 금액 기준)
        CALL proc_depo_account_debit(p_base_acct_id, p_depo_prncp_amt);
    END IF;

    -- 3. 계약 계좌(account)생성
    -- 3-1. 계좌번호 생성
    account_num_loop:
    WHILE TRUE
        DO
            SET v_prefix7 = LPAD(FLOOR(RAND() * 10000000), 7, '0'); -- 0000000 ~ 9999999
            SET v_mid2 = LPAD(FLOOR(RAND() * 100), 2, '0'); -- 00 ~ 99
            SET v_suffix5 = LPAD(FLOOR(RAND() * 100000), 5, '0'); -- 00000 ~ 99999

            SET v_contract_acct_num = CONCAT(v_prefix7, '-', v_mid2, '-', v_suffix5);

            -- 중복 체크
            SELECT COUNT(*)
            INTO v_exists_cnt
            FROM account
            WHERE acct_num = v_contract_acct_num;

            IF v_exists_cnt = 0 THEN
                LEAVE account_num_loop;
            END IF;
        END WHILE account_num_loop;

    -- 3-2. 계약 상품 타입에 따른 이체 타입, 요구불 여부, 만기일, 지급 방식 지정
    IF v_prod_tp = 'DO001' THEN
        SET v_contract_acct_tp = 'AC001';
        SET v_contract_ded_yn = 'Y';
        set v_maturity_dt = null;
        set v_payout_tp = null;
    ELSE
        SET v_contract_acct_tp = 'AC002';
        SET v_contract_ded_yn = 'N';

        SELECT depo_term_month
        into v_term_month
        from depo_prod_term
        where depo_prod_id = p_depo_prod_id;

        SET v_maturity_dt = DATE_ADD(current_date, INTERVAL v_term_month MONTH);

        if p_depo_paid_cash_yn = 'Y' then
            set v_payout_tp = 'DO031';
        elseif p_depo_paid_cash_yn = 'N' then
            set v_payout_tp = 'DO032';
        END IF;

    END IF;

    -- 3-3. 계좌 테이블 인서트
    INSERT INTO account ( cust_id
                        , acct_sav_tp
                        , acct_num
                        , acct_pw
                        , acct_day_limit
                        , acct_sts_cd
                        , acct_is_ded_yn)
    VALUES ( p_cust_id
           , v_contract_acct_tp
           , v_contract_acct_num
           , p_acct_pw
           , p_acct_day_limit
           , 'AS001'
           , v_contract_ded_yn
           );

    SET v_contract_acct_id = LAST_INSERT_ID();

    -- 5. 예적금/요구불 계약 INSERT
    INSERT INTO depo_contract ( cust_id
                              , depo_prod_id
                              , acct_id
                              , depo_base_acct_id
                              , emp_id
                              , depo_maturity_dt
                              , depo_applied_intrst_rt
                              , depo_payout_tp
                              , depo_paid_cash_yn)
    VALUES (p_cust_id
           , p_depo_prod_id
           , v_contract_acct_id
           , p_base_acct_id
           , p_emp_id
           , v_maturity_dt
           , p_intrst_rt
           , v_payout_tp
           , p_depo_paid_cash_yn);

    SET o_depo_contract_id = LAST_INSERT_ID();
    SET o_contract_acct_id = v_contract_acct_id;
    SET o_contract_acct_num = v_contract_acct_num;

    -- 6. 상품 타입별 후속 처리: 서브 프로시저로 분리

    IF v_prod_tp = 'DO002' THEN
        INSERT INTO depo_contract_deposit (
            depo_contract_id
            , depo_prncp_amt
        )
        VALUES (
            o_depo_contract_id
            , p_depo_prncp_amt
        );
    ELSEIF v_prod_tp in ('DO003', 'DO004') THEN
        if v_prod_tp = 'DO004' then
            INSERT INTO depo_contract_savings (
                depo_contract_id
                , depo_payment_day
                , depo_monthly_amt
            )
            VALUES (
                o_depo_contract_id
                , p_payment_day
                , p_depo_prncp_amt
            );
        end if;

    END IF;

END$$

DELIMITER ;

-- 적금 납입 내역 프로시저
DELIMITER $$

CREATE PROCEDURE proc_depo_savings_payment(

)