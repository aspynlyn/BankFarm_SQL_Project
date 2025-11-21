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
create table depo_contract_deposit
(
    depo_contract_id BIGINT PRIMARY KEY COMMENT '계약 ID',
    depo_prncp_amt   BIGINT NOT NULL COMMENT '예치금',
    FOREIGN KEY (depo_contract_id) REFERENCES depo_contract (depo_prod_id)
);
