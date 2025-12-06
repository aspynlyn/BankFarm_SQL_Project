-- 환전거래 취소시 입출금내역 롤백 프로시저
DELIMITER $$

CREATE PROCEDURE proc_fx_currency_exchange_cancel_one (
    IN p_fx_id BIGINT,
    IN p_cancel_cd VARCHAR(5)  -- FX024(고객/직원 취소), FX025(기한만료), FX026(시스템 오류)
)
BEGIN
    DECLARE v_fx_trns_tp   VARCHAR(5);
    DECLARE v_from_acct_id BIGINT;
    DECLARE v_to_acct_id   BIGINT;
    DECLARE v_from_amt     DECIMAL(18,4);
    DECLARE v_to_amt       DECIMAL(18,4);
    DECLARE v_trns_cd      VARCHAR(5);
    DECLARE v_req_dt       DATETIME;
    DECLARE v_bal          DECIMAL(18,4);

    SELECT fx_trns_tp,
           fx_from_acct_id,
           fx_to_acct_id,
           fx_from_amt,
           fx_to_amt,
           fx_trns_cd,
           fx_req_dt
    INTO   v_fx_trns_tp,
           v_from_acct_id,
           v_to_acct_id,
           v_from_amt,
           v_to_amt,
           v_trns_cd,
           v_req_dt
    FROM fx_currency_exchange
    WHERE fx_trns_id = p_fx_id
    FOR UPDATE;

    IF v_fx_trns_tp IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '존재하지 않는 환전 거래입니다.';
    END IF;

    -- 이미 취소된 건 막기 (원하면 여기서 조용히 RETURN 해도 됨)
    IF v_trns_cd IN ('FX024', 'FX025', 'FX026') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '이미 취소된 환전 거래입니다.';
    END IF;

    -- 1) FX001: 계좌 -> 외화
    --    → 처음에 출금했으니 취소 시 다시 입금
    IF v_fx_trns_tp = 'FX001' AND v_from_acct_id IS NOT NULL THEN

        SELECT acct_bal
        INTO v_bal
        FROM account
        WHERE acct_id = v_from_acct_id
        FOR UPDATE;

        SET v_bal = v_bal + v_from_amt;

        UPDATE account
        SET acct_bal = v_bal
        WHERE acct_id = v_from_acct_id;

        INSERT INTO transaction (
            acct_id,
            trns_tp,
            trns_amt,
            trns_bal,
            trns_des
        ) VALUES (
            v_from_acct_id,
            1,  -- 입금
            v_from_amt,
            v_bal,
            '환전 취소'
        );

    -- 2) FX002: 외화 -> 계좌
    --    → 처음에 입금했으니 취소 시 출금
    ELSEIF v_fx_trns_tp = 'FX002' AND v_to_acct_id IS NOT NULL THEN

        SELECT acct_bal
        INTO v_bal
        FROM account
        WHERE acct_id = v_to_acct_id
        FOR UPDATE;

        SET v_bal = v_bal - v_to_amt;

        UPDATE account
        SET acct_bal = v_bal
        WHERE acct_id = v_to_acct_id;

        INSERT INTO transaction (
            acct_id,
            trns_tp,
            trns_amt,
            trns_bal,
            trns_des
        ) VALUES (
            v_to_acct_id,
            0,  -- 출금
            v_to_amt,
            v_bal,
            '환전 취소'
        );

    END IF;

    -- 환전 상태 변경
    UPDATE fx_currency_exchange
    SET fx_trns_cd = p_cancel_cd
    WHERE fx_trns_id = p_fx_id;
END$$

DELIMITER ;

-- 수령 기간 만료 거래 자동 취소 프로시저
DELIMITER $$

CREATE PROCEDURE proc_fx_currency_exchange_auto_cancel_batch ()
BEGIN
    DECLARE v_fx_id BIGINT;
    DECLARE done INT DEFAULT 0;

    DECLARE cur CURSOR FOR
        SELECT fx_trns_id
        FROM fx_currency_exchange
        WHERE fx_trns_cd = 'FX021'
          or fx_trns_cd = 'FX022'
          AND fx_req_dt < DATE_SUB(NOW(), INTERVAL 7 DAY);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur;

    read_loop: LOOP
        FETCH cur INTO v_fx_id;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        CALL proc_fx_currency_exchange_cancel_one(v_fx_id, 'FX025');
    END LOOP;

    CLOSE cur;
END$$

DELIMITER ;

