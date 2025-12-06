-- 보험 제휴사 계약 시 프로시저
CREATE PROCEDURE proc_part_contract_register (
    IN p_part_code   VARCHAR(50),  -- 보험사 통신 코드
    IN p_part_nm     VARCHAR(100), -- 보험사 이름
    IN p_part_tp     VARCHAR(5), -- 제휴사 타입
    IN p_part_start  DATE, -- 계약 시작일
    IN p_part_end    DATE -- 계약 만료일
)
BEGIN
    DECLARE v_part_id BIGINT;

    -- 1. 이미 등록된 제휴사인지 확인 (코드, 이름으로)
    SELECT part_id
      INTO v_part_id
    FROM partner
    WHERE part_code = p_part_code
    or part_nm = p_part_nm;

    -- 2. 없으면 partner에 새로 insert
    IF v_part_id IS NULL THEN
        INSERT INTO partner (part_nm
                            , part_tp
                            , part_use_yn
                            , part_code)
        VALUES (p_part_nm
               , p_part_tp
               , 'Y'
               , p_part_code);

        SET v_part_id = LAST_INSERT_ID();
    END IF;

    -- 3. 제휴사 계약 테이블에 insert
    INSERT INTO part_contract (part_id
                              , part_start_dt
                              , part_end_dt
                              , part_active_yn)
    VALUES (v_part_id
           , p_part_start
           , p_part_end
           , 'Y');
END;