# 상위 코드 테이블
create table super_code (
    sc_cd_id CHAR(2) PRIMARY KEY COMMENT '상위 코드 아이디',
    sc_cd_nm VARCHAR(100) NOT NULL COMMENT '상위 코드 이름',
    sc_cd_des VARCHAR(100) not NULL COMMENT '상위 코드 설명',
    sc_created_at DATETIME NOT NULL DEFAULT current_timestamp COMMENT '생성 일시'
    );

# 공통 코드 데이블
create table common_code (
    sc_cd_id CHAR(2) COMMENT '상위 코드 아이디',
    cc_cd_id CHAR(3) COMMENT '하위 코드 아이디',
    cc_cd_nm VARCHAR(100) NOT NULL COMMENT '공통 코드 이름',
    cc_cd_des VARCHAR(100) not NULL COMMENT '공통 코드 설명',
    cc_category_nm VARCHAR(100) NULL COMMENT '코드 카테고리 이름',
    cc_created_at DATETIME NOT NULL DEFAULT current_timestamp COMMENT '생성 일시',
    FOREIGN KEY (sc_cd_id) REFERENCES super_code(sc_cd_id),
    PRIMARY KEY (sc_cd_id, cc_cd_id)
    );

drop table super_code;
drop table common_code;



