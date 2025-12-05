-- 보험 납입 내역 업데이트 프로시저
DELIMITER $$

CREATE PROCEDURE proc_insr_premium_pay (
    IN p_insr_constract_num BIGINT,   -- 보험 계약 번호(보험사 쪽에서 만든 보험 계약 번호)
    IN p_insr_payment_seq  INT,      -- 납입 회차
    IN p_paid_amt          BIGINT,   -- 실제 납입 금액
    IN p_paid_at           DATE,      -- 실제 납입 일자 (NULL이면 오늘로 처리)
    in p_paid_yn char(1) -- 납입 성공 여부
)
BEGIN
    DECLARE v_payment_dt DATE;
    DECLARE v_paid_at    DATE;
    DECLARE v_od_yn      CHAR(1);
    DECLARE v_total_cnt  INT;
    DECLARE v_paid_cnt   INT;

    -- 납입일 파라미터가 NULL이면 오늘 날짜로
    SET v_paid_at = COALESCE(p_paid_at, CURRENT_DATE());

    -- 해당 회차 스케줄 조회 (납입 예정일)
    SELECT insr_payment_dt
    INTO v_payment_dt
    FROM insr_payment_history
    WHERE insr_contract_id = p_insr_constract_id
      AND insr_payment_seq  = p_insr_payment_seq
    FOR UPDATE;

    -- 스케줄이 없으면 에러
    IF v_payment_dt IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = '납입 스케줄이 없습니다.';
    END IF;

    -- 연체 여부 판정: 실제 납입일이 예정일 초과면 Y
    IF v_paid_at > v_payment_dt THEN
        SET v_od_yn = 'Y';
    ELSE
        SET v_od_yn = 'N';
    END IF;

    -- 납입 이력 업데이트
    UPDATE insr_payment_history
    SET insr_paid_dt  = v_paid_at,
        insr_paid_amt = p_paid_amt,
        insr_paid_yn  = 'Y',
        insr_od_yn    = v_od_yn
    WHERE insr_contract_id = p_insr_constract_id
      AND insr_payment_seq  = p_insr_payment_seq;

    -- 모든 회차 납입 완료 여부 체크
    SELECT COUNT(*)
    INTO v_total_cnt
    FROM insr_payment_history
    WHERE insr_contract_id = p_insr_constract_id;

    SELECT COUNT(*)
    INTO v_paid_cnt
    FROM insr_payment_history
    WHERE insr_contract_id = p_insr_constract_id
      AND insr_paid_yn = 'Y';

    -- 전 회차 납입 완료 시 계약 상태 코드 갱신
    IF v_total_cnt = v_paid_cnt THEN
        UPDATE insr_contract
        SET insr_active_cd = 'CS002'  -- 계약코드(만기)
        WHERE insr_contract_id = p_insr_constract_id;
    END IF;
END$$

DELIMITER ;