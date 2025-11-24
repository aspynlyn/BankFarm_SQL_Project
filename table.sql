# 상위 코드 테이블
CREATE TABLE cd_super_code
(
    sc_cd_id  CHAR(2) PRIMARY KEY COMMENT '상위 코드 ID',
    sc_cd_nm  VARCHAR(100) NOT NULL COMMENT '상위 코드 이름',
    sc_cd_des VARCHAR(100) NOT NULL COMMENT '상위 코드 설명',
    sc_crt_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시'
);

# 공통 코드 데이블
CREATE TABLE cd_common_code
(
    sc_cd_id       CHAR(2) COMMENT '상위 코드 ID',
    cc_cd_id       CHAR(5) COMMENT '공통 코드 ID',
    cc_cd_nm       VARCHAR(100) NOT NULL COMMENT '공통 코드 이름',
    cc_cd_des      VARCHAR(100) NOT NULL COMMENT '공통 코드 설명',
    cc_category_nm VARCHAR(100) NULL COMMENT '코드 카테고리 이름',
    cc_crt_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시',
    FOREIGN KEY (sc_cd_id) REFERENCES cd_super_code (sc_cd_id),
    PRIMARY KEY (sc_cd_id, cc_cd_id)
);

# DROP TABLE super_code;
# DROP TABLE common_code;

# 예적금 상품 공통 테이블
CREATE TABLE depo_prod
(
    depo_prod_id          BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '상품 ID',
    depo_prod_nm          VARCHAR(50)  NOT NULL COMMENT '상품명',
    depo_start_dt         DATE         NOT NULL COMMENT '판매 시작일',
    depo_end_dt           DATE COMMENT '판매 종료일',
    depo_prod_tp          VARCHAR(5)   NOT NULL COMMENT '상품 타입',
    depo_prod_des         VARCHAR(255) NOT NULL COMMENT '상품 설명',
    depo_intrst_calc_unit VARCHAR(5)   NOT NULL COMMENT '이자 계산 단위',
    depo_intrst_pay_cycle VARCHAR(5)   NOT NULL COMMENT '이자 지급 주기',
    depo_intrst_calc_tp   VARCHAR(5)   NOT NULL COMMENT '이자 계산 방식',
    depo_sale_yn          CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '상품 판매 여부' CHECK ( depo_sale_yn IN ('Y', 'N') )
);

# 예적금 상품 조건 테이블
CREATE TABLE depo_prod_term
(
    depo_prod_id    BIGINT PRIMARY KEY COMMENT '상품 ID',
    depo_term_month INT COMMENT '만기 개월',
    depo_min_amt    INT NOT NULL COMMENT '최소 납입/예치 금액',
    depo_max_amt    INT COMMENT '최대 납입/예치 금액',
    FOREIGN KEY (depo_prod_id) REFERENCES depo_prod (depo_prod_id)
);
# ALTER TABLE depo_prod_term
#     ADD PRIMARY KEY (depo_prod_id);

# 예적금 계약 공통 테이블
CREATE TABLE depo_contract
(
    depo_contract_id       BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '계약 ID',
    cust_id                BIGINT     NOT NULL COMMENT '계약한 고객 ID',
    depo_prod_id           BIGINT     NOT NULL COMMENT '계약한 상품 ID',
    acct_id                BIGINT     NOT NULL COMMENT '생성된 계좌 ID',
    emp_id                 BIGINT     NOT NULL COMMENT '담당 직원 ID',
    depo_prod_tp           VARCHAR(5) NOT NULL COMMENT '계약 상품 타입',
    depo_contract_dt       DATE       NOT NULL COMMENT '가입 일자',
    depo_maturity_dt       DATE COMMENT '만기 일자',
    depo_applied_intrst_rt DECIMAL(6, 4) COMMENT '적용 금리',
    depo_active_cd         VARCHAR(5) NOT NULL DEFAULT 'CS001' COMMENT '계약 상태 코드',
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id),
    FOREIGN KEY (depo_prod_id) REFERENCES depo_prod (depo_prod_id),
    FOREIGN KEY (acct_id) REFERENCES account (acct_id),
    FOREIGN KEY (emp_id) REFERENCES employees (emp_id)
);
# DROP TABLE depo_contract;

# 예금 계약 상세 테이블
CREATE TABLE depo_contract_deposit
(
    depo_contract_id BIGINT PRIMARY KEY COMMENT '계약 ID',
    depo_prncp_amt   BIGINT NOT NULL COMMENT '예치금',
    FOREIGN KEY (depo_contract_id) REFERENCES depo_contract (depo_prod_id)
);

# 적금 계약 상세 테이블
CREATE TABLE depo_contract_savings
(
    depo_contract_id BIGINT PRIMARY KEY COMMENT '계약 ID',
    depo_missed_cnt  INT     NOT NULL DEFAULT '0' COMMENT '미납 횟수',
    depo_payment_day TINYINT NOT NULL COMMENT '월 납입 설정 일' CHECK ( depo_payment_day BETWEEN 1 AND 28),
    depo_monthly_amt BIGINT  NOT NULL COMMENT '월 납입 예정 액',
    FOREIGN KEY (depo_contract_id) REFERENCES depo_contract (depo_prod_id)
);

# 적금 납입 내역 테이블
CREATE TABLE depo_savings_payment
(
    depo_payment_id  BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '납입 ID',
    depo_contract_id BIGINT  NOT NULL COMMENT '계약 ID',
    depo_paid_dt     DATE    NOT NULL COMMENT '납입 일',
    depo_paid_amt    BIGINT COMMENT '납입 액',
    depo_payment_yn  CHAR(1) NOT NULL COMMENT '납입 여부' CHECK ( depo_payment_yn IN ('Y', 'N') ),
    FOREIGN KEY (depo_contract_id) REFERENCES depo_contract (depo_contract_id)
);

# 통화 테이블
CREATE TABLE fx_currency
(
    fx_currency_id     CHAR(3) PRIMARY KEY COMMENT '통화 국제 표준 코드',
    fx_nation          VARCHAR(50) NOT NULL COMMENT '국가 명',
    fx_min_limit       INT         NOT NULL COMMENT '정수 변환에 필요한 보정 단위',
    fx_currency_symbol VARCHAR(5) COMMENT '통화 기호',
    fx_currency_nm     VARCHAR(20) COMMENT '통화 명칭',
    fx_active_yn       CHAR(1)     NOT NULL DEFAULT 'Y' COMMENT '통화 활성화 여부' CHECK ( fx_active_yn IN ('Y', 'N') ),
    fx_apply_start_dt  DATE        NOT NULL COMMENT '통화 적용 시작일'
);

# 환전 기준 기록 테이블
CREATE TABLE fx_rt_history
(
    fx_rt_id       BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '환전 기준 ID',
    fx_currency_id CHAR(3)        NOT NULL COMMENT '통화 국제 표준 코드',
    fx_charge_rt   DECIMAL(20, 4) NOT NULL COMMENT '매매 기준율',
    fx_commission  DECIMAL(20, 4) NOT NULL COMMENT '수수료',
    fx_crt_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록 일시',
    FOREIGN KEY (fx_currency_id) REFERENCES fx_currency (fx_currency_id)
);

# 환전 기준 감사 기록 테이블
CREATE TABLE fx_rt_audit_history
(
    fx_audit_id            BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '감사 ID',
    fx_rt_id               BIGINT       NOT NULL COMMENT '환전 기준 ID',
    emp_id                 BIGINT       NOT NULL COMMENT '수정한 직원 ID',
    fx_exchanged_attribute VARCHAR(30)  NOT NULL COMMENT '정정 속성',
    fx_old_value           VARCHAR(30)  NOT NULL COMMENT '정정 전 값',
    fx_new_value           VARCHAR(30)  NOT NULL COMMENT '정정 후 값',
    fx_audit_reason        VARCHAR(100) NOT NULL COMMENT '정정 사유',
    fx_audited_at          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '감사 일시'
);

# 환전 거래 기록 테이블
CREATE TABLE fx_currency_exchange
(
    fx_trns_id          BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '환전 기록 ID',
    fx_rt_id            BIGINT         NOT NULL COMMENT '환전 기준 ID',
    emp_id              BIGINT         NOT NULL COMMENT '직원 ID',
    fx_from_acct_id     BIGINT COMMENT '출금 계좌 ID',
    fx_to_acct_id       BIGINT COMMENT '입금 계좌 ID',
    fx_from_amt         DECIMAL(18, 4) NOT NULL COMMENT '지불 금액',
    fx_to_amt           DECIMAL(18, 4) NOT NULL COMMENT '환전 금액',
    fx_trns_tp          VARCHAR(5)     NOT NULL COMMENT '거래 타입',
    fx_exchange_purpose VARCHAR(5)     NOT NULL COMMENT '거래 유형/성격',
    fx_trns_dt          DATE           NOT NULL COMMENT '거래 일',
    fx_trns_cd          VARCHAR(5)     NOT NULL COMMENT '거래 진행 상태',
    FOREIGN KEY (fx_rt_id) REFERENCES fx_rt_history (fx_rt_id),
    FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    FOREIGN KEY (fx_from_acct_id) REFERENCES account (acct_id),
    FOREIGN KEY (fx_to_acct_id) REFERENCES account (acct_id)
);

# 제휴사 테이블
CREATE TABLE partner
(
    part_id     BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '제휴사 ID',
    part_nm     VARCHAR(100) NOT NULL UNIQUE COMMENT '제휴사명',
    part_tp     VARCHAR(50)  NOT NULL COMMENT '제휴사 타입',
    part_use_yn CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '사용 여부' CHECK ( part_use_yn IN ('Y', 'N'))
);

# 제휴사 계약 테이블
CREATE TABLE part_contract
(
    part_contract_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '제휴사 계약 ID',
    part_id          BIGINT     NOT NULL COMMENT '제휴사 ID',
    part_start_dt    DATE       NOT NULL COMMENT '계약 시작일',
    part_end_dt      DATE       NOT NULL COMMENT '계약 종료일',
    part_active_yn   VARCHAR(5) NOT NULL DEFAULT 'Y' COMMENT '계약 상태 여부' CHECK ( part_active_yn IN ('Y', 'N')),
    FOREIGN KEY (part_id) REFERENCES partner (part_id)
);

# 보험 상품 테이블
CREATE TABLE insr_prod
(
    insr_prod_id    BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '보험 상품 ID',
    part_id         BIGINT         NOT NULL COMMENT '제휴사 ID',
    insr_prod_cd    VARCHAR(30)    NOT NULL UNIQUE COMMENT '상품 코드',
    insr_prod_nm    VARCHAR(100)   NOT NULL COMMENT '상품명',
    insr_prod_tp    VARCHAR(10)    NOT NULL COMMENT '상품 타입',
    insr_open_dt    DATE           NOT NULL COMMENT '판매 시작일',
    insr_close_dt   DATE           NULL COMMENT '판매 종료일',
    insr_commission DECIMAL(15, 2) NOT NULL COMMENT '수수료',
    insr_sale_yn    CHAR(1)        NOT NULL DEFAULT 'Y' COMMENT '판매 여부' CHECK ( insr_sale_yn IN ('Y', 'N')),
    FOREIGN KEY (part_id) REFERENCES partner (part_id)
);

# 보험 계약 테이블
CREATE TABLE insr_contract
(
    insr_contract_id    BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '보험 계약 ID',
    insr_prod_id        BIGINT     NOT NULL COMMENT '보험 상품 ID',
    cust_id             BIGINT     NOT NULL COMMENT '고객 ID',
    emp_id              BIGINT     NOT NULL COMMENT '직원 ID',
    insr_contract_num   VARCHAR(20) COMMENT '계약 번호',
    insr_bank_cd        CHAR(5) COMMENT '계약 은행 코드',
    insr_acct_num       VARCHAR(20) COMMENT '계약 계좌 번호',
    insr_contract_dt    DATETIME COMMENT '계약 일시',
    insr_payment_end_dt DATE COMMENT '납입 종료일',
    insr_maturity_dt    DATE COMMENT '만기일',
    insr_approval_cd    VARCHAR(5) NOT NULL COMMENT '승인 상태 코드',
    insr_active_cd      VARCHAR(5) NOT NULL DEFAULT 'CS001' COMMENT '계약 상태 코드',
    insr_renewable_yn   CHAR(1)    NOT NULL COMMENT '갱신 가능 여부',
    insr_refund_amt     BIGINT     NULL COMMENT '환급금',
    insr_payment_day    TINYINT    NOT NULL COMMENT '납입일(1~28)' CHECK ( insr_payment_day BETWEEN 1 AND 28),
    FOREIGN KEY (insr_prod_id) REFERENCES insr_prod (insr_prod_id),
    FOREIGN KEY (emp_id) REFERENCES employees (emp_id),
    FOREIGN KEY (cust_id) REFERENCES customer (cust_id)
);

# 보험 납입 내역 테이블
CREATE TABLE insr_payment_history
(
    insr_payment_seq  INT COMMENT '납입 회차',
    insr_contract_id  BIGINT COMMENT '보험 계약 ID',
    insr_payment_dt   DATE    NOT NULL COMMENT '납입 예정일',
    insr_expected_amt BIGINT  NOT NULL COMMENT '예정 납입 금액',
    insr_paid_dt      DATE    NULL COMMENT '실제 납입 일자',
    insr_paid_amt     BIGINT  NULL COMMENT '실제 납입 금액',
    insr_paid_yn      CHAR(1) NOT NULL DEFAULT 'N' COMMENT '납입 여부',
    insr_od_yn        CHAR(1) NOT NULL DEFAULT 'N' COMMENT '연체 여부',
    PRIMARY KEY (insr_payment_seq, insr_contract_id),
    FOREIGN KEY (insr_contract_id) REFERENCES insr_contract (insr_contract_id)
);

# 보험 해지/만기 정보 테이블
CREATE TABLE insr_term
(
    insr_contract_id BIGINT PRIMARY KEY COMMENT '보험 계약 ID',
    insr_term_tp     VARCHAR(5) NOT NULL COMMENT '해지/만기 타입',
    insr_term_dt     DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '해지/만기 일',
    insr_term_reason VARCHAR(200) COMMENT '해지/만기 사유',
    FOREIGN KEY (insr_contract_id) REFERENCES insr_contract (insr_contract_id)
);

ALTER TABLE customer
    ADD COLUMN cust_withdrawn_yn CHAR(1) NOT NULL DEFAULT 'N' COMMENT '탈퇴 여부' CHECK ( cust_withdrawn_yn IN ('Y', 'N'));

SELECT * FROM performance_schema.data_locks;
SELECT * FROM performance_schema.data_lock_waits;