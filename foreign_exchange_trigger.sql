-- 환전 거래기록 생성 시 입출금 내역 저장
DELIMITER $$

CREATE TRIGGER trg_insert_currency_exchange
    AFTER INSERT
    ON fx_currency_exchange
    FOR EACH ROW
BEGIN
    DECLARE v_bal BIGINT;

    -- FX001: 계좌 -> 외화(원화 출금)
    IF NEW.fx_trns_tp = 'FX001' AND NEW.fx_from_acct_id IS NOT NULL THEN

        SELECT acct_bal
        INTO v_bal
        FROM account
        WHERE acct_id = NEW.fx_from_acct_id
            FOR
        UPDATE;

        SET v_bal = v_bal - NEW.fx_from_amt;


        INSERT INTO transaction (acct_id,
                                 trns_fee_id,
                                 trns_amt,
                                 trns_bal,
                                 trns_tp,
                                 trns_des)
        VALUES (NEW.fx_from_acct_id,
                1,
                -NEW.fx_from_amt,
                v_bal,
                2,
                '환전 신청 출금');

        -- FX002: 외화 -> 계좌(원화 입금)
    ELSEIF NEW.fx_trns_tp = 'FX002' AND NEW.fx_to_acct_id IS NOT NULL THEN

        SELECT acct_bal
        INTO v_bal
        FROM account
        WHERE acct_id = NEW.fx_to_acct_id
            FOR
        UPDATE;

        SET v_bal = v_bal + NEW.fx_to_amt;

        UPDATE account
        SET acct_bal = v_bal
        WHERE acct_id = NEW.fx_to_acct_id;

        INSERT INTO transaction (acct_id,
                                 trns_fee_id,
                                 trns_amt,
                                 trns_bal,
                                 trns_tp,
                                 trns_des)
        VALUES (NEW.fx_to_acct_id,
                1,
                NEW.fx_to_amt,
                v_bal,
                1, -- 입금
                '환전 신청 입금');

    END IF;

END$$

DELIMITER ;
