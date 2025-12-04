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
    IN p_intrst_rt DECIMAL(6, 4), -- 적용 금리(고객마다 다름 백에서 계산 한 값)
    IN p_payment_day TINYINT, -- 납입일(정기 적금만 해당)
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
    DECLARE v_term_month INT;
    DECLARE v_contract_dt DATE;
    DECLARE v_maturity_dt DATE;
    DECLARE v_payout_tp VARCHAR(5);
    DECLARE v_exists_cnt INT DEFAULT 0;
    DECLARE v_prefix7 VARCHAR(7);
    DECLARE v_mid2 VARCHAR(2);
    DECLARE v_suffix5 VARCHAR(5);

    SET v_contract_dt = CURRENT_DATE;

    -- 1. 상품 활성화 여부 조회
    SELECT depo_sale_yn, depo_prod_tp
    INTO v_sale_yn, v_prod_tp
    FROM depo_prod
    WHERE depo_prod_id = p_depo_prod_id;

    -- 상품 존재 여부 체크
    IF v_sale_yn = 'N' OR v_sale_yn IS NULL THEN
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

        -- 상품 상세 테이블에서 min/max 세부 조회
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
        SET v_maturity_dt = NULL;
        SET v_payout_tp = NULL;
    ELSE
        SET v_contract_acct_tp = 'AC002';
        SET v_contract_ded_yn = 'N';

        SELECT depo_term_month
        INTO v_term_month
        FROM depo_prod_term
        WHERE depo_prod_id = p_depo_prod_id;

        SET v_maturity_dt = DATE_ADD(CURRENT_DATE, INTERVAL v_term_month MONTH);

        IF p_depo_paid_cash_yn = 'Y' THEN
            SET v_payout_tp = 'DO031';
        ELSEIF p_depo_paid_cash_yn = 'N' THEN
            SET v_payout_tp = 'DO032';
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
           , v_contract_ded_yn);

    SET v_contract_acct_id = LAST_INSERT_ID();

    -- 5. 예적금/요구불 계약 INSERT
    INSERT INTO depo_contract ( cust_id
                              , depo_prod_id
                              , acct_id
                              , depo_base_acct_id
                              , emp_id
                              , depo_contract_dt
                              , depo_maturity_dt
                              , depo_applied_intrst_rt
                              , depo_payout_tp
                              , depo_paid_cash_yn)
    VALUES ( p_cust_id
           , p_depo_prod_id
           , v_contract_acct_id
           , p_base_acct_id
           , p_emp_id
           ,
           , v_maturity_dt
           , p_intrst_rt
           , v_payout_tp
           , p_depo_paid_cash_yn);

    SET o_depo_contract_id = LAST_INSERT_ID();
    SET o_contract_acct_id = v_contract_acct_id;
    SET o_contract_acct_num = v_contract_acct_num;

    -- 6. 상품 타입별 후속 처리: 서브 프로시저로 분리

    IF v_prod_tp = 'DO002' THEN
        INSERT INTO depo_contract_deposit ( depo_contract_id
                                          , depo_prncp_amt)
        VALUES ( o_depo_contract_id
               , p_depo_prncp_amt);
    ELSEIF v_prod_tp IN ('DO003', 'DO004') THEN
        IF v_prod_tp = 'DO003' THEN
            INSERT INTO depo_contract_savings ( depo_contract_id
                                              , depo_payment_day
                                              , depo_monthly_amt)
            VALUES ( o_depo_contract_id
                   , p_payment_day
                   , p_depo_prncp_amt);
        END IF;
        CALL proc_depo_savings_payment(o_depo_contract_id
            , p_depo_prncp_amt
            , 'Y');
    END IF;

END$$

DELIMITER ;

-- 적금 납입 내역 프로시저
DELIMITER $$

CREATE PROCEDURE proc_depo_savings_payment(
    IN p_depo_contract_id BIGINT
, IN p_depo_paid_amt BIGINT
, IN p_depo_payment_yn CHAR(1)
)
BEGIN
    DECLARE v_prod_tp VARCHAR(5);
    DECLARE v_paid_dt DATE;

    SET v_paid_dt = CURRENT_DATE;

    -- 1. 계약 타입 확인 (적금 계약인지 체크)
    SELECT p.depo_prod_tp
    INTO v_prod_tp
    FROM depo_contract c
             JOIN depo_prod p ON p.depo_prod_id = c.depo_prod_id
    WHERE c.depo_contract_id = p_depo_contract_id;

    IF v_prod_tp NOT IN ('DO003', 'DO004') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '적금 납입 내역은 적금 상품만 넣을 수 있습니다.';
    END IF;

    IF p_depo_paid_amt IS NULL OR p_depo_paid_amt <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '납입 금액이 잘못되었습니다.';
    END IF;

    INSERT INTO depo_savings_payment( depo_contract_id
                                    , depo_paid_amt
                                    , depo_payment_yn
                                    , depo_paid_dt)
    VALUES ( p_depo_contract_id
           , p_depo_paid_amt
           , p_depo_payment_yn
           , v_paid_dt);


END$$

DELIMITER ;

-- 예/적금 해지, 만기 이자 계산 프로시저
DELIMITER $$

CREATE PROCEDURE proc_depo_calc_interest(
    IN p_depo_contract_id BIGINT
, IN p_settle_tp CHAR(1) -- 'M'=만기, 'E'=해지
, OUT o_principal BIGINT -- 원금합
, OUT o_interest BIGINT -- 이자
)
BEGIN
    DECLARE v_prod_tp VARCHAR(5); -- 상품 타입
    DECLARE v_applied_rate DECIMAL(6, 4); -- 계약 시 적용 금리(우대 포함)
    DECLARE v_base_rate DECIMAL(6, 4); -- 상품 기본 금리
    DECLARE v_rate DECIMAL(6, 4); -- 최종 사용할 금리
    DECLARE v_start_dt DATE; -- 계약 시작일
    DECLARE v_maturity_dt DATE; -- 계약 만기일

    DECLARE v_settle_dt DATE;
    DECLARE v_days INT;
    DECLARE v_principal BIGINT;
    DECLARE v_sum_principal BIGINT;
    DECLARE v_sum_interest BIGINT;

    SET v_settle_dt = CURRENT_DATE;

    -- 계약 정보 조회
    IF p_depo_contract_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '존재하지 않는 계약입니다.';
    END IF;

    SELECT p.depo_prod_tp
         , c.depo_applied_intrst_rt
         , c.depo_maturity_dt
         , c.depo_contract_dt
    INTO v_prod_tp
        , v_applied_rate
        , v_maturity_dt
        , v_start_dt
    FROM depo_contract c
             JOIN depo_prod p
                  ON p.depo_prod_id = c.depo_prod_id
    WHERE c.depo_contract_id = p_depo_contract_id;

    -- 상품 기본 금리 조회 (해지용)
    SELECT base_rt
    INTO v_base_rate
    FROM base_rate
    ORDER BY base_st_dt DESC
    LIMIT 1;


    -- 정산 타입별 금리 선택
    IF p_settle_tp = 'M' THEN
        -- 만기 → 계약 시 적용 금리 사용
        SET v_rate = v_applied_rate;

    ELSEIF p_settle_tp = 'E' THEN
        -- 해지 → 기본 금리 사용
        IF v_base_rate IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = '기본 금리가 없습니다.';
        END IF;
        SET v_rate = v_base_rate;

    ELSE
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '정산 타입은 M/E만 가능합니다.';
    END IF;

    -- 상품 타입별 이자 계산
    IF v_prod_tp = 'DO002' THEN
        -- 정기예금: 단리 (계약일~정산일)

        SELECT depo_prncp_amt
        INTO v_principal
        FROM depo_contract_deposit
        WHERE depo_contract_id = p_depo_contract_id;

        SET v_days = DATEDIFF(v_settle_dt, v_start_dt);
        IF v_days < 0 THEN SET v_days = 0; END IF;

        SET o_principal = v_principal;
        SET o_interest = FLOOR(v_principal * v_rate * (v_days / 365));


    ELSEIF v_prod_tp IN ('DO003', 'DO004') THEN
        -- 정기/자유 적금: 각 납입건 단리 합산

        -- 지금까지 넣은 원금 합계
        SELECT COALESCE(SUM(depo_paid_amt), 0)
        INTO v_sum_principal
        FROM depo_savings_payment
        WHERE depo_contract_id = p_depo_contract_id
          AND depo_payment_yn = 'Y';

        SELECT COALESCE(
                       SUM(
                               depo_paid_amt
                                   * v_rate
                                   * (GREATEST(DATEDIFF(v_settle_dt, depo_paid_dt), 0)
                                   / 365)
                       )
                   , 0)
        INTO v_sum_interest
        FROM depo_savings_payment
        WHERE depo_contract_id = p_depo_contract_id
          AND depo_payment_yn = 'Y';

        SET o_principal = v_sum_principal;
        SET o_interest = FLOOR(v_sum_interest);

    ELSE
        -- 요구불은 여기서 계산 안 함
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '요구불 이자는 별도 배치에서 처리해야 합니다.';
    END IF;
END$$

DELIMITER ;

-- 입금 내역 찍는 프로시저
DELIMITER $$

CREATE PROCEDURE proc_depo_acct_transfer(
    IN p_from_acct_id BIGINT -- 출금 계좌
, IN p_to_acct_id BIGINT -- 입금 계좌
, IN p_amt BIGINT -- 출금 액
, IN p_total_amt BIGINT -- 총 이체 금액(양수, 원 단위)
, IN p_cust_id BIGINT -- 계약 고객
)
BEGIN
    DECLARE v_from_bal BIGINT;
    DECLARE v_to_bal BIGINT;
    DECLARE v_from_num VARCHAR(20);
    DECLARE v_to_num VARCHAR(20);

    IF p_amt IS NULL OR p_amt <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '이체 금액이 잘못되었습니다.';
    END IF;

    -- 출금 계좌 조회 (잔액, 계좌번호) + 잠금
    SELECT acct_bal
         , acct_num
    INTO v_from_bal
        , v_from_num
    FROM account
    WHERE acct_id = p_from_acct_id
        FOR
    UPDATE;

    -- 출금 계좌 조회, 고객 일치 여부 파악
    CALL proc_depo_account_owner(p_from_acct_id, p_cust_id);

    -- 입금 계좌 조회, 고객 일치 여부 파악(있을 때만)
    IF p_to_acct_id IS NOT NULL THEN
        CALL proc_depo_account_owner(p_to_acct_id, p_cust_id);

        -- 입금 계좌 잔액, 번호 조회
        SELECT acct_bal, acct_num
        INTO v_to_bal, v_to_num
        FROM account
        WHERE acct_id = p_to_acct_id
            FOR
        UPDATE;
    END IF;

    -- 출금 계좌 잔액 체크
    CALL proc_depo_account_debit(p_from_acct_id, p_amt);

    -- 출금 계좌 잔액, 번호 조회
    SELECT acct_bal, acct_num
    INTO v_from_bal, v_from_num
    FROM account
    WHERE acct_id = p_from_acct_id
        FOR
    UPDATE;

    -- 예적금 계좌 ->  지급 계좌 출금 내역 넣기
    INSERT INTO transaction ( acct_id
                            , trns_fee_id
                            , trns_amt
                            , trns_acct_num
                            , trns_bal
                            , trns_tp
                            , trns_des)
    VALUES ( p_from_acct_id
           , 1
           , -p_amt
           , v_to_num
           , v_from_bal - p_amt
           , 2
           , '예적금 원금 출금');

    -- 입금 계좌가 있는 경우만 처리
    IF p_to_acct_id IS NOT NULL THEN

        -- 지급 계좌 입금 내역 넣기
        INSERT INTO transaction ( acct_id
                                , trns_fee_id
                                , trns_amt
                                , trns_acct_num
                                , trns_bal
                                , trns_tp
                                , trns_des)
        VALUES ( p_to_acct_id
               , 1
               , p_total_amt
               , v_from_num
               , v_to_bal + p_total_amt
               , 1
               , '예적금 원금, 이자 입금');
    END IF;
END$$

DELIMITER ;

-- 만기/해지시 스케줄러로 호출할 정산 메인 프로시저
DELIMITER $$

CREATE PROCEDURE proc_depo_daily_maturity_settle(
    IN p_call_tp CHAR(1)
)
BEGIN
    DECLARE v_settle_dt DATE;

    DECLARE v_contract_id BIGINT;
    DECLARE v_prod_tp VARCHAR(5);
    DECLARE v_paid_cash_yn CHAR(1);
    DECLARE v_contract_acct_id BIGINT;
    DECLARE v_base_acct_id BIGINT;
    DECLARE v_cust_id BIGINT;

    DECLARE v_principal BIGINT;
    DECLARE v_interest BIGINT;
    DECLARE v_rate_used DECIMAL(6, 4);
    DECLARE v_total_pay BIGINT;

    DECLARE done INT DEFAULT 0;

    SET v_settle_dt = CURRENT_DATE();

    IF p_call_tp = 'M' THEN
        -- 오늘 만기이면서 활성 상태인 계약 커서
        DECLARE cur_maturity CURSOR FOR
        SELECT c.depo_contract_id
             , p.depo_prod_tp
             , c.depo_paid_cash_yn
             , c.acct_id
             , c.depo_base_acct_id
             , c.cust_id
        FROM depo_contract c
                 JOIN depo_prod p
                      ON p.depo_prod_id = c.depo_prod_id
        WHERE c.depo_maturity_dt = v_settle_dt
          AND c.depo_active_cd = 'CS001';

        DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

        OPEN cur_maturity;

        read_loop:
        LOOP
            FETCH cur_maturity
                INTO v_contract_id
                    , v_prod_tp
                    , v_paid_cash_yn
                    , v_contract_acct_id
                    , v_base_acct_id
                    , v_cust_id;

            IF done = 1 THEN
                LEAVE read_loop;
            END IF;

            -- 정기예금/정기적금/자유적금만 처리
            IF v_prod_tp NOT IN ('DO002', 'DO003', 'DO004') THEN
                ITERATE read_loop;
            END IF;

            -- 이자 계산 (만기 정산: p_settle_tp = 'M')
            CALL proc_depo_calc_interest(
                    v_contract_id
                , 'M'
                , v_principal
                , v_interest
                 );

            SET v_total_pay = v_principal + v_interest;

            -- 계좌 지급: 계약 계좌 → 기준 계좌(base_acct_id)로 원리금 이체
            CALL proc_depo_acct_transfer(
                    v_contract_acct_id
                , v_base_acct_id
                , v_principal
                , v_total_pay
                , v_cust_id
                 );

            -- 계약 상태/정산 정보 업데이트
            UPDATE depo_contract
            SET depo_active_cd = 'CS002'
            WHERE depo_contract_id = v_contract_id;

            -- 만기 테이블에 인서트
            INSERT INTO depo_contract_term(
                  depo_contract_id
                    , depo_term_tp
                                          , depo_term_dt
                )
                VALUES (
                        v_contract_id
                    ,
                       )

        END LOOP;

        CLOSE cur_maturity;
    ELSEIF p_call_tp = 'E' THEN

    END IF;

END$$

DELIMITER ;

-- 이자 지급하는 내부 계좌는 일단 없다고 치고 상품 계좌에서 지급 계좌로 돈 넣는 입출금 로직 찍기 그리고 계좌 상태, 계약 상태 바꾸고 만기해지 테이블에 데이터 찍기
