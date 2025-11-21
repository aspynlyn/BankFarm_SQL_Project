# 상위 코드 테이블
CREATE TABLE super_code
(
    sc_cd_id      CHAR(2) PRIMARY KEY COMMENT '상위 코드 ID',
    sc_cd_nm      VARCHAR(100) NOT NULL COMMENT '상위 코드 이름',
    sc_cd_des     VARCHAR(100) NOT NULL COMMENT '상위 코드 설명',
    sc_created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시'
);

# 공통 코드 데이블
CREATE TABLE common_code
(
    sc_cd_id       CHAR(2) COMMENT '상위 코드 ID',
    cc_cd_id       CHAR(5) COMMENT '공통 코드 ID',
    cc_cd_nm       VARCHAR(100) NOT NULL COMMENT '공통 코드 이름',
    cc_cd_des      VARCHAR(100) NOT NULL COMMENT '공통 코드 설명',
    cc_category_nm VARCHAR(100) NULL COMMENT '코드 카테고리 이름',
    cc_created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시',
    FOREIGN KEY (sc_cd_id) REFERENCES super_code (sc_cd_id),
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
    depo_active_cd         VARCHAR(5) NOT NULL DEFAULT 'CS001',
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
CREATE TABLE depo_prod_savings
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
    fx_active_yn       CHAR(1)     NOT NULL DEFAULT 'Y' COMMENT '통화 활성화 여부' CHECK ( fx_active_yn IN ('Y', 'N') )
);

# 환전 기준 기록 테이블
CREATE TABLE fx_rt_history
(
    fx_rt_id       BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '환전 기준 ID',
    fx_currency_id CHAR(3)        NOT NULL COMMENT '통화 국제 표준 코드',
    fx_charge_rt   DECIMAL(20, 4) NOT NULL COMMENT '매매 기준율',
    fx_commission  DECIMAL(20, 4) NOT NULL COMMENT '수수료',
    fx_crt_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fx_currency_id) REFERENCES fx_currency (fx_currency_id)
);

ALTER TABLE fx_rt_history
    MODIFY COLUMN fx_crt_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 일시';

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
create table fx_currency_exchange(
    fx_trns_id BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT '환전 기록 ID',
    fx_rt_id BIGINT NOT NULL COMMENT '환전 기준 ID',
    emp_id BIGINT NOT NULL COMMENT '직원 ID',
    acct_id BIGINT NOT NULL COMMENT '계좌 ID',
    fx_from_amt DECIMAL(18, 4) not null COMMENT '지불 금액',
    fx_to_amt DECIMAL(18,4) not NULL COMMENT '환전 금액'
);