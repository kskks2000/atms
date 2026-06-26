-- ====================================================================
-- Enterprise Transportation Management System (TMS) DDL Script
-- Target Database: PostgreSQL 11
-- Target Schema: atms
-- Multi-Tenancy Architecture Enabled
-- ====================================================================

CREATE SCHEMA IF NOT EXISTS atms;
SET search_path TO atms;

-- 1. DROP EXISTING TABLES (If any, to avoid dependency conflicts)
DROP TABLE IF EXISTS tb_settlement_payment CASCADE;
DROP TABLE IF EXISTS tb_settlement_billing CASCADE;
DROP TABLE IF EXISTS tb_settlement CASCADE; -- Legacy table cleanup
DROP TABLE IF EXISTS tb_execution CASCADE;
DROP TABLE IF EXISTS tb_tracking_log CASCADE;
DROP TABLE IF EXISTS tb_dispatch_detail CASCADE;
DROP TABLE IF EXISTS tb_group_detail CASCADE; -- Legacy table cleanup
DROP TABLE IF EXISTS tb_dispatch_group CASCADE;
DROP TABLE IF EXISTS tb_group CASCADE; -- Legacy table cleanup
DROP TABLE IF EXISTS tb_order_detail CASCADE;
DROP TABLE IF EXISTS tb_order CASCADE;
DROP TABLE IF EXISTS tb_tariff CASCADE;
DROP TABLE IF EXISTS tb_vehicle CASCADE;
DROP TABLE IF EXISTS tb_driver CASCADE;
DROP TABLE IF EXISTS tb_node CASCADE;
DROP TABLE IF EXISTS tb_role_permission CASCADE;
DROP TABLE IF EXISTS tb_user_role CASCADE;
DROP TABLE IF EXISTS tb_permission CASCADE;
DROP TABLE IF EXISTS tb_role CASCADE;
DROP TABLE IF EXISTS tb_user CASCADE;
DROP TABLE IF EXISTS tb_partner CASCADE;
DROP TABLE IF EXISTS tb_shipper CASCADE; -- Legacy table cleanup
DROP TABLE IF EXISTS tb_carrier CASCADE; -- Legacy table cleanup
DROP TABLE IF EXISTS tb_common_code CASCADE;
DROP TABLE IF EXISTS tb_tenant CASCADE;


-- ====================================================================
-- 2. TABLE CREATIONS (Tenant first, then standard tables with tenant FK)
-- ====================================================================

-- --------------------------------------------------------------------
-- [tb_tenant] 테넌트 마스터 (계열사, 사업부, 고객사 등 시스템 격리 마스터)
-- --------------------------------------------------------------------
CREATE TABLE tb_tenant (
    tenant_id VARCHAR(50) NOT NULL,
    tenant_nm VARCHAR(100) NOT NULL,
    biz_no VARCHAR(20),
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_tenant PRIMARY KEY (tenant_id)
);

COMMENT ON TABLE tb_tenant IS '테넌트 마스터 (독립적 시스템 데이터 격리 단위)';
COMMENT ON COLUMN tb_tenant.tenant_id IS '테넌트 ID (그룹사 코드 혹은 법인 식별자)';
COMMENT ON COLUMN tb_tenant.tenant_nm IS '테넌트(법인)명';
COMMENT ON COLUMN tb_tenant.biz_no IS '사업자등록번호';
COMMENT ON COLUMN tb_tenant.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_common_code] 공통 코드 마스터
-- --------------------------------------------------------------------
CREATE TABLE tb_common_code (
    code_grp VARCHAR(50) NOT NULL,
    code VARCHAR(50) NOT NULL,
    code_nm VARCHAR(100) NOT NULL,
    code_desc VARCHAR(255),
    sort_seq INTEGER DEFAULT 0 NOT NULL,
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_common_code PRIMARY KEY (code_grp, code)
);

COMMENT ON TABLE tb_common_code IS '공통 코드 마스터';
COMMENT ON COLUMN tb_common_code.code_grp IS '코드 그룹 ID';
COMMENT ON COLUMN tb_common_code.code IS '코드 값';
COMMENT ON COLUMN tb_common_code.code_nm IS '코드 이름';
COMMENT ON COLUMN tb_common_code.code_desc IS '코드 상세 설명';
COMMENT ON COLUMN tb_common_code.sort_seq IS '정렬 순서';
COMMENT ON COLUMN tb_common_code.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_partner] 거래처 마스터 (화주, 운송사, 3PL 등)
-- --------------------------------------------------------------------
CREATE TABLE tb_partner (
    tenant_id VARCHAR(50) NOT NULL,
    partner_id VARCHAR(50) NOT NULL,
    partner_nm VARCHAR(100) NOT NULL,
    partner_type VARCHAR(20) NOT NULL, -- 'SHIPPER', 'CARRIER', '3PL'
    biz_no VARCHAR(20),
    rep_nm VARCHAR(50),
    tel_no VARCHAR(50),
    zip_code VARCHAR(10),
    address VARCHAR(255),
    detail_address VARCHAR(255),
    settle_cycle VARCHAR(20), -- 'MONTHLY', 'BIWEEKLY', 'WEEKLY'
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_partner PRIMARY KEY (partner_id),
    CONSTRAINT fk_tb_partner_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_partner IS '거래처(파트너) 마스터 정보';
COMMENT ON COLUMN tb_partner.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_partner.partner_id IS '거래처 ID';
COMMENT ON COLUMN tb_partner.partner_nm IS '거래처명';
COMMENT ON COLUMN tb_partner.partner_type IS '거래처 유형 (SHIPPER: 화주, CARRIER: 운송사, 3PL: 3자물류)';
COMMENT ON COLUMN tb_partner.biz_no IS '사업자등록번호';
COMMENT ON COLUMN tb_partner.rep_nm IS '대표자명';
COMMENT ON COLUMN tb_partner.tel_no IS '대표 연락처';
COMMENT ON COLUMN tb_partner.zip_code IS '우편번호';
COMMENT ON COLUMN tb_partner.address IS '기본 주소';
COMMENT ON COLUMN tb_partner.detail_address IS '상세 주소';
COMMENT ON COLUMN tb_partner.settle_cycle IS '정산 주기';
COMMENT ON COLUMN tb_partner.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_user] 사용자 마스터 (계정 및 로그인 관리)
-- --------------------------------------------------------------------
CREATE TABLE tb_user (
    tenant_id VARCHAR(50) NOT NULL,
    user_id VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_nm VARCHAR(50) NOT NULL,
    email VARCHAR(100),
    phone_no VARCHAR(20),
    partner_id VARCHAR(50), -- 소속 거래처 ID (자사 직원은 NULL)
    user_status VARCHAR(20) DEFAULT 'ACTIVE' NOT NULL, -- 'ACTIVE', 'INACTIVE', 'LOCKED'
    password_changed_at TIMESTAMP WITHOUT TIME ZONE,
    login_fail_cnt INTEGER DEFAULT 0 NOT NULL,
    last_login_at TIMESTAMP WITHOUT TIME ZONE,
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_user PRIMARY KEY (user_id),
    CONSTRAINT fk_tb_user_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_user_partner FOREIGN KEY (partner_id)
        REFERENCES tb_partner(partner_id) ON DELETE SET NULL
);

COMMENT ON TABLE tb_user IS '사용자 마스터 정보';
COMMENT ON COLUMN tb_user.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_user.user_id IS '사용자 로그인 ID';
COMMENT ON COLUMN tb_user.password_hash IS '단방향 암호화 비밀번호 해시';
COMMENT ON COLUMN tb_user.user_nm IS '사용자 이름';
COMMENT ON COLUMN tb_user.email IS '이메일 주소';
COMMENT ON COLUMN tb_user.phone_no IS '휴대폰 번호';
COMMENT ON COLUMN tb_user.partner_id IS '소속 파트너사 ID (본사 관리자는 NULL)';
COMMENT ON COLUMN tb_user.user_status IS '사용자 상태 (ACTIVE: 활성, INACTIVE: 비활성, LOCKED: 계정잠금)';
COMMENT ON COLUMN tb_user.password_changed_at IS '최근 비밀번호 변경 일시';
COMMENT ON COLUMN tb_user.login_fail_cnt IS '연속 로그인 실패 횟수';
COMMENT ON COLUMN tb_user.last_login_at IS '마지막 로그인 성공 일시';
COMMENT ON COLUMN tb_user.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_role] 권한 역할 마스터 (Role)
-- --------------------------------------------------------------------
CREATE TABLE tb_role (
    tenant_id VARCHAR(50) NOT NULL,
    role_id VARCHAR(50) NOT NULL,
    role_nm VARCHAR(100) NOT NULL,
    role_desc VARCHAR(255),
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_role PRIMARY KEY (role_id),
    CONSTRAINT fk_tb_role_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_role IS '권한 역할 마스터';
COMMENT ON COLUMN tb_role.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_role.role_id IS '역할 ID';
COMMENT ON COLUMN tb_role.role_nm IS '역할 명칭';
COMMENT ON COLUMN tb_role.role_desc IS '역할 상세 설명';
COMMENT ON COLUMN tb_role.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_permission] 기능/접근 권한 마스터 (Permission)
-- --------------------------------------------------------------------
CREATE TABLE tb_permission (
    tenant_id VARCHAR(50) NOT NULL,
    permission_id VARCHAR(50) NOT NULL,
    permission_nm VARCHAR(100) NOT NULL,
    permission_desc VARCHAR(255),
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_permission PRIMARY KEY (permission_id),
    CONSTRAINT fk_tb_permission_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_permission IS '세부 권한 마스터';
COMMENT ON COLUMN tb_permission.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_permission.permission_id IS '세부 권한 ID';
COMMENT ON COLUMN tb_permission.permission_nm IS '권한 명칭';
COMMENT ON COLUMN tb_permission.permission_desc IS '권한 상세 설명';
COMMENT ON COLUMN tb_permission.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_user_role] 사용자별 역할 매핑 (N:M 관계)
-- --------------------------------------------------------------------
CREATE TABLE tb_user_role (
    user_id VARCHAR(50) NOT NULL,
    role_id VARCHAR(50) NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_user_role PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_tb_user_role_user FOREIGN KEY (user_id)
        REFERENCES tb_user(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_user_role_role FOREIGN KEY (role_id)
        REFERENCES tb_role(role_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_user_role IS '사용자별 권한 역할 매핑 관계';
COMMENT ON COLUMN tb_user_role.user_id IS '사용자 ID';
COMMENT ON COLUMN tb_user_role.role_id IS '역할 ID';


-- --------------------------------------------------------------------
-- [tb_role_permission] 역할별 세부 권한 매핑 (N:M 관계)
-- --------------------------------------------------------------------
CREATE TABLE tb_role_permission (
    role_id VARCHAR(50) NOT NULL,
    permission_id VARCHAR(50) NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_role_permission PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_tb_role_permission_role FOREIGN KEY (role_id)
        REFERENCES tb_role(role_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_role_permission_permission FOREIGN KEY (permission_id)
        REFERENCES tb_permission(permission_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_role_permission IS '역할별 세부 기능 권한 매핑 관계';
COMMENT ON COLUMN tb_role_permission.role_id IS '역할 ID';
COMMENT ON COLUMN tb_role_permission.permission_id IS '세부 권한 ID';


-- --------------------------------------------------------------------
-- [tb_node] 물류 거점 마스터 (물류센터, 대리점, 고객사 하역처 등)
-- --------------------------------------------------------------------
CREATE TABLE tb_node (
    tenant_id VARCHAR(50) NOT NULL,
    node_id VARCHAR(50) NOT NULL,
    node_nm VARCHAR(100) NOT NULL,
    node_type VARCHAR(20) NOT NULL, -- 'CENTER', 'PLANT', 'STORE', 'CUSTOMER'
    zip_code VARCHAR(10),
    address VARCHAR(255) NOT NULL,
    detail_address VARCHAR(255),
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    limit_tonnage NUMERIC(5, 2), -- 진입 가능한 최대 차량 톤수
    dock_cnt INTEGER DEFAULT 1 NOT NULL,
    operating_hours VARCHAR(100), -- 예: '08:00 - 18:00'
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_node PRIMARY KEY (node_id),
    CONSTRAINT fk_tb_node_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_node IS '물류 거점 마스터 정보';
COMMENT ON COLUMN tb_node.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_node.node_id IS '거점 ID';
COMMENT ON COLUMN tb_node.node_nm IS '거점명';
COMMENT ON COLUMN tb_node.node_type IS '거점 유형 (CENTER: 물류센터, PLANT: 공장, STORE: 대리점, CUSTOMER: 납품처)';
COMMENT ON COLUMN tb_node.zip_code IS '우편번호';
COMMENT ON COLUMN tb_node.address IS '거점 기본 주소';
COMMENT ON COLUMN tb_node.detail_address IS '거점 상세 주소';
COMMENT ON COLUMN tb_node.latitude IS '거점 위도 (네이버 지도 연동)';
COMMENT ON COLUMN tb_node.longitude IS '거점 경도 (네이버 지도 연동)';
COMMENT ON COLUMN tb_node.limit_tonnage IS '진입 제한 차량 톤수';
COMMENT ON COLUMN tb_node.dock_cnt IS '접안 가능한 도크(Dock) 수';
COMMENT ON COLUMN tb_node.operating_hours IS '표준 영업시간';
COMMENT ON COLUMN tb_node.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_driver] 운전기사 마스터
-- --------------------------------------------------------------------
CREATE TABLE tb_driver (
    tenant_id VARCHAR(50) NOT NULL,
    driver_id VARCHAR(50) NOT NULL,
    driver_nm VARCHAR(50) NOT NULL,
    phone_no VARCHAR(20) NOT NULL,
    carrier_id VARCHAR(50), -- 소속 운송사 (용차의 경우 null 가능)
    user_id VARCHAR(50), -- 로그인 연동 사용자 계정 ID
    license_type VARCHAR(50), -- 면허 종류
    license_no VARCHAR(50), -- 면허 번호
    license_expiry_dt DATE, -- 면허 만료일
    bank_nm VARCHAR(50), -- 지급 거래 은행
    account_no VARCHAR(50), -- 지급 계좌 번호
    account_holder VARCHAR(50), -- 예금주
    device_os VARCHAR(20), -- 모바일 단말 OS (ANDROID, IOS)
    push_token VARCHAR(255), -- FCM 푸시 토큰 (배차 지시용)
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_driver PRIMARY KEY (driver_id),
    CONSTRAINT fk_tb_driver_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_driver_carrier FOREIGN KEY (carrier_id)
        REFERENCES tb_partner(partner_id) ON DELETE SET NULL,
    CONSTRAINT fk_tb_driver_user FOREIGN KEY (user_id)
        REFERENCES tb_user(user_id) ON DELETE SET NULL
);

COMMENT ON TABLE tb_driver IS '운전기사 마스터 정보';
COMMENT ON COLUMN tb_driver.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_driver.driver_id IS '기사 고유 ID';
COMMENT ON COLUMN tb_driver.driver_nm IS '기사명';
COMMENT ON COLUMN tb_driver.phone_no IS '기사 휴대폰번호';
COMMENT ON COLUMN tb_driver.carrier_id IS '소속 운송사 ID (용차/개인은 NULL 가능)';
COMMENT ON COLUMN tb_driver.user_id IS '연동된 로그인 사용자 계정 ID';
COMMENT ON COLUMN tb_driver.license_type IS '보유 운전면허 유형';
COMMENT ON COLUMN tb_driver.license_no IS '운전면허번호';
COMMENT ON COLUMN tb_driver.license_expiry_dt IS '면허 만료일자';
COMMENT ON COLUMN tb_driver.bank_nm IS '용차료 지급 은행명';
COMMENT ON COLUMN tb_driver.account_no IS '지급 계좌 번호';
COMMENT ON COLUMN tb_driver.account_holder IS '예금주';
COMMENT ON COLUMN tb_driver.device_os IS '모바일 OS';
COMMENT ON COLUMN tb_driver.push_token IS '푸시 메시지 발송용 토큰';
COMMENT ON COLUMN tb_driver.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_vehicle] 차량 마스터
-- --------------------------------------------------------------------
CREATE TABLE tb_vehicle (
    tenant_id VARCHAR(50) NOT NULL,
    vehicle_id VARCHAR(50) NOT NULL,
    vehicle_no VARCHAR(20) NOT NULL,
    truck_type VARCHAR(20) NOT NULL, -- 'CARGO', 'WINGBODY', 'TOP', 'FREEZER' 등
    tonnage NUMERIC(5, 2) NOT NULL, -- 1.0, 2.5, 5.0, 11.0, 25.0 등
    ownership_type VARCHAR(20) NOT NULL, -- 'OWNED'(직영), 'CONTRACTED'(지입), 'SPARE'(용차)
    is_refrigerated CHAR(1) DEFAULT 'N' NOT NULL,
    carrier_id VARCHAR(50), -- 소속 운송사
    default_driver_id VARCHAR(50), -- 고정 매핑 기사 ID
    length_mm INTEGER, -- 적재함 길이 (mm)
    width_mm INTEGER, -- 적재함 너비 (mm)
    height_mm INTEGER, -- 적재함 높이 (mm)
    max_cbm NUMERIC(8, 2), -- 최대 적재 용적(CBM)
    gps_device_id VARCHAR(50), -- 차량 장착 GPS 단말 ID
    subsidy_yn CHAR(1) DEFAULT 'N' NOT NULL, -- 유가보조금 수급 여부
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_vehicle PRIMARY KEY (vehicle_id),
    CONSTRAINT fk_tb_vehicle_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_vehicle_carrier FOREIGN KEY (carrier_id)
        REFERENCES tb_partner(partner_id) ON DELETE SET NULL,
    CONSTRAINT fk_tb_vehicle_driver FOREIGN KEY (default_driver_id)
        REFERENCES tb_driver(driver_id) ON DELETE SET NULL
);

COMMENT ON TABLE tb_vehicle IS '차량 마스터 정보';
COMMENT ON COLUMN tb_vehicle.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_vehicle.vehicle_id IS '차량 고유 ID';
COMMENT ON COLUMN tb_vehicle.vehicle_no IS '차량 번호 (예: 서울12가3456)';
COMMENT ON COLUMN tb_vehicle.truck_type IS '차량 형태 (카고, 윙바디, 탑차, 냉동탑차 등)';
COMMENT ON COLUMN tb_vehicle.tonnage IS '차량 적재 톤수';
COMMENT ON COLUMN tb_vehicle.ownership_type IS '차량 소속 구분 (OWNED: 직영, CONTRACTED: 지입, SPARE: 용차)';
COMMENT ON COLUMN tb_vehicle.is_refrigerated IS '냉장/냉동 여부 (Y/N)';
COMMENT ON COLUMN tb_vehicle.carrier_id IS '소속 운송사 ID';
COMMENT ON COLUMN tb_vehicle.default_driver_id IS '지정/고정 운전기사 ID';
COMMENT ON COLUMN tb_vehicle.length_mm IS '적재함 가로 길이 (mm)';
COMMENT ON COLUMN tb_vehicle.width_mm IS '적재함 세로 너비 (mm)';
COMMENT ON COLUMN tb_vehicle.height_mm IS '적재함 높이 (mm)';
COMMENT ON COLUMN tb_vehicle.max_cbm IS '최대 적재 용적 (CBM)';
COMMENT ON COLUMN tb_vehicle.gps_device_id IS '실시간 관제용 GPS 모듈 ID';
COMMENT ON COLUMN tb_vehicle.subsidy_yn IS '유가보조금 대상 여부 (Y/N)';
COMMENT ON COLUMN tb_vehicle.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_tariff] 운송 계약 단가표
-- --------------------------------------------------------------------
CREATE TABLE tb_tariff (
    tenant_id VARCHAR(50) NOT NULL,
    tariff_id INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    contract_type VARCHAR(20) NOT NULL, -- 'SALES'(매출단가), 'PURCHASE'(매입단가)
    partner_id VARCHAR(50) NOT NULL, -- 계약 화주 ID 또는 계약 운송사 ID
    start_node_id VARCHAR(50) NOT NULL,
    end_node_id VARCHAR(50) NOT NULL,
    truck_type VARCHAR(20) NOT NULL,
    tonnage NUMERIC(5, 2) NOT NULL,
    base_fee NUMERIC(15, 2) NOT NULL DEFAULT 0,
    waiting_fee_per_hour NUMERIC(15, 2) NOT NULL DEFAULT 0,
    return_fee_rate NUMERIC(5, 2) NOT NULL DEFAULT 0, -- 회차 시 기본료 대비 청구/지급 비율 (%)
    extra_node_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 추가 경유지 요금
    start_date DATE NOT NULL, -- 계약 적용 시작일
    end_date DATE NOT NULL, -- 계약 적용 종료일
    use_yn CHAR(1) DEFAULT 'Y' NOT NULL,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_tariff PRIMARY KEY (tariff_id),
    CONSTRAINT fk_tb_tariff_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_tariff_partner FOREIGN KEY (partner_id)
        REFERENCES tb_partner(partner_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_tariff_start_node FOREIGN KEY (start_node_id)
        REFERENCES tb_node(node_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_tariff_end_node FOREIGN KEY (end_node_id)
        REFERENCES tb_node(node_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_tariff IS '계약별 운송 단가표';
COMMENT ON COLUMN tb_tariff.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_tariff.tariff_id IS '단가 ID';
COMMENT ON COLUMN tb_tariff.contract_type IS '계약 구분 (SALES: 매출/화주계약, PURCHASE: 매입/운송사계약)';
COMMENT ON COLUMN tb_tariff.partner_id IS '거래처 ID (화주 혹은 운송사)';
COMMENT ON COLUMN tb_tariff.start_node_id IS '출발지 노드 ID';
COMMENT ON COLUMN tb_tariff.end_node_id IS '도착지 노드 ID';
COMMENT ON COLUMN tb_tariff.truck_type IS '차량 차종 조건';
COMMENT ON COLUMN tb_tariff.tonnage IS '차량 톤수 조건';
COMMENT ON COLUMN tb_tariff.base_fee IS '기본 운송료';
COMMENT ON COLUMN tb_tariff.waiting_fee_per_hour IS '시간당 대기료 요율';
COMMENT ON COLUMN tb_tariff.return_fee_rate IS '회차료 요율 (%)';
COMMENT ON COLUMN tb_tariff.extra_node_fee IS '추가 경유지 요금';
COMMENT ON COLUMN tb_tariff.start_date IS '단가 적용 시작일';
COMMENT ON COLUMN tb_tariff.end_date IS '단가 적용 종료일';
COMMENT ON COLUMN tb_tariff.use_yn IS '사용 여부 (Y/N)';


-- --------------------------------------------------------------------
-- [tb_order] 운송 오더 마스터
-- --------------------------------------------------------------------
CREATE TABLE tb_order (
    tenant_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    erp_ref_no VARCHAR(50), -- ERP 주문 및 출하 고유번호
    shipper_id VARCHAR(50) NOT NULL, -- 화주 (FK)
    start_node_id VARCHAR(50) NOT NULL, -- 출발지 (FK)
    end_node_id VARCHAR(50) NOT NULL, -- 도착지 (FK)
    req_loading_dt TIMESTAMP WITHOUT TIME ZONE NOT NULL, -- 희망 상차일시
    req_unloading_dt TIMESTAMP WITHOUT TIME ZONE NOT NULL, -- 희망 하차일시
    temp_condition VARCHAR(20) DEFAULT 'AMBIENT' NOT NULL, -- 'AMBIENT', 'CHILLED', 'FROZEN'
    is_hazardous CHAR(1) DEFAULT 'N' NOT NULL, -- 위험물 여부
    total_weight_kg NUMERIC(12, 3) NOT NULL DEFAULT 0,
    total_cbm NUMERIC(10, 3) NOT NULL DEFAULT 0,
    order_status VARCHAR(20) DEFAULT 'RECEIVED' NOT NULL, -- RECEIVED, VALIDATED, PLANNED, DISPATCHED, IN_TRANSIT, DELIVERED, SETTLED, CANCELLED
    cancel_reason VARCHAR(255),
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_order PRIMARY KEY (order_id),
    CONSTRAINT fk_tb_order_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_order_shipper FOREIGN KEY (shipper_id)
        REFERENCES tb_partner(partner_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_order_start_node FOREIGN KEY (start_node_id)
        REFERENCES tb_node(node_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_order_end_node FOREIGN KEY (end_node_id)
        REFERENCES tb_node(node_id) ON DELETE RESTRICT
);

COMMENT ON TABLE tb_order IS '운송 오더 마스터';
COMMENT ON COLUMN tb_order.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_order.order_id IS '오더 고유 ID';
COMMENT ON COLUMN tb_order.erp_ref_no IS 'ERP 연동 참조 번호';
COMMENT ON COLUMN tb_order.shipper_id IS '화주사 ID';
COMMENT ON COLUMN tb_order.start_node_id IS '상차지 거점 ID';
COMMENT ON COLUMN tb_order.end_node_id IS '하차지 거점 ID';
COMMENT ON COLUMN tb_order.req_loading_dt IS '희망 상차일시';
COMMENT ON COLUMN tb_order.req_unloading_dt IS '희망 하차일시';
COMMENT ON COLUMN tb_order.temp_condition IS '보관 온도 기준 (AMBIENT: 상온, CHILLED: 냉장, FROZEN: 냉동)';
COMMENT ON COLUMN tb_order.is_hazardous IS '위험물 취급 여부 (Y/N)';
COMMENT ON COLUMN tb_order.total_weight_kg IS '오더 총 중량 (kg)';
COMMENT ON COLUMN tb_order.total_cbm IS '오더 총 용적 (CBM)';
COMMENT ON COLUMN tb_order.order_status IS '오더 상태 코드';
COMMENT ON COLUMN tb_order.cancel_reason IS '오더 취소 사유';


-- --------------------------------------------------------------------
-- [tb_order_detail] 오더 품목 상세 내역
-- --------------------------------------------------------------------
CREATE TABLE tb_order_detail (
    order_detail_id INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    item_code VARCHAR(50) NOT NULL,
    item_nm VARCHAR(150) NOT NULL,
    qty INTEGER NOT NULL DEFAULT 0,
    qty_unit VARCHAR(20) NOT NULL DEFAULT 'BOX', -- BOX, PLT, EA 등
    weight_kg NUMERIC(12, 3) NOT NULL DEFAULT 0,
    cbm NUMERIC(10, 3) NOT NULL DEFAULT 0,
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_order_detail PRIMARY KEY (order_detail_id),
    CONSTRAINT fk_tb_order_detail_order FOREIGN KEY (order_id)
        REFERENCES tb_order(order_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_order_detail IS '오더 품목 상세';
COMMENT ON COLUMN tb_order_detail.order_detail_id IS '상세 고유 일련번호';
COMMENT ON COLUMN tb_order_detail.order_id IS '소속 오더 ID';
COMMENT ON COLUMN tb_order_detail.item_code IS '품목 코드';
COMMENT ON COLUMN tb_order_detail.item_nm IS '품목명';
COMMENT ON COLUMN tb_order_detail.qty IS '수량';
COMMENT ON COLUMN tb_order_detail.qty_unit IS '포장단위 (BOX: 박스, PLT: 파레트, EA: 낱개)';
COMMENT ON COLUMN tb_order_detail.weight_kg IS '품목 중량 합계 (kg)';
COMMENT ON COLUMN tb_order_detail.cbm IS '품목 부피 합계 (CBM)';


-- --------------------------------------------------------------------
-- [tb_dispatch_group] 배차/운송 노선 마스터
-- --------------------------------------------------------------------
CREATE TABLE tb_dispatch_group (
    tenant_id VARCHAR(50) NOT NULL,
    group_id VARCHAR(50) NOT NULL,
    plan_date DATE NOT NULL,
    plan_status VARCHAR(20) DEFAULT 'PLANNED' NOT NULL, -- PLANNED, DISPATCHED, IN_TRANSIT, COMPLETED, CANCELLED
    carrier_id VARCHAR(50), -- 운송사 ID (FK)
    vehicle_id VARCHAR(50), -- 배정 차량 ID (FK)
    driver_id VARCHAR(50), -- 배정 기사 ID (FK)
    planner_id VARCHAR(50) NOT NULL, -- 배차 담당 직원 계정 ID (FK to tb_user)
    total_distance_km NUMERIC(8, 2) DEFAULT 0,
    total_duration_min INTEGER DEFAULT 0,
    limit_weight_kg NUMERIC(12, 3) DEFAULT 0,
    limit_cbm NUMERIC(10, 3) DEFAULT 0,
    total_weight_kg NUMERIC(12, 3) DEFAULT 0,
    total_cbm NUMERIC(10, 3) DEFAULT 0,
    weight_util_rate NUMERIC(5, 2) DEFAULT 0, -- 차량 중량 적재 효율 (%)
    cbm_util_rate NUMERIC(5, 2) DEFAULT 0, -- 차량 용적 적재 효율 (%)
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_dispatch_group PRIMARY KEY (group_id),
    CONSTRAINT fk_tb_dispatch_group_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_dispatch_group_carrier FOREIGN KEY (carrier_id)
        REFERENCES tb_partner(partner_id) ON DELETE SET NULL,
    CONSTRAINT fk_tb_dispatch_group_vehicle FOREIGN KEY (vehicle_id)
        REFERENCES tb_vehicle(vehicle_id) ON DELETE SET NULL,
    CONSTRAINT fk_tb_dispatch_group_driver FOREIGN KEY (driver_id)
        REFERENCES tb_driver(driver_id) ON DELETE SET NULL,
    CONSTRAINT fk_tb_dispatch_group_planner FOREIGN KEY (planner_id)
        REFERENCES tb_user(user_id) ON DELETE RESTRICT
);

COMMENT ON TABLE tb_dispatch_group IS '배차 운송 노선 마스터';
COMMENT ON COLUMN tb_dispatch_group.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_dispatch_group.group_id IS '배차 그룹 고유 ID';
COMMENT ON COLUMN tb_dispatch_group.plan_date IS '운송 계획 일자';
COMMENT ON COLUMN tb_dispatch_group.plan_status IS '배차/운송 진행 상태';
COMMENT ON COLUMN tb_dispatch_group.carrier_id IS '지정 운송사 ID';
COMMENT ON COLUMN tb_dispatch_group.vehicle_id IS '배정 차량 ID';
COMMENT ON COLUMN tb_dispatch_group.driver_id IS '배정 운전기사 ID';
COMMENT ON COLUMN tb_dispatch_group.planner_id IS '배차 담당 직원 계정 ID';
COMMENT ON COLUMN tb_dispatch_group.total_distance_km IS '계획 총 주행거리 (km)';
COMMENT ON COLUMN tb_dispatch_group.total_duration_min IS '계획 총 소요시간 (분)';
COMMENT ON COLUMN tb_dispatch_group.limit_weight_kg IS '차량 최대적재 용량 (중량)';
COMMENT ON COLUMN tb_dispatch_group.limit_cbm IS '차량 최대적재 용량 (부피)';
COMMENT ON COLUMN tb_dispatch_group.total_weight_kg IS '오더 합산 중량 (kg)';
COMMENT ON COLUMN tb_dispatch_group.total_cbm IS '오더 합산 용적 (CBM)';
COMMENT ON COLUMN tb_dispatch_group.weight_util_rate IS '차량 중량 적재 효율 (%)';
COMMENT ON COLUMN tb_dispatch_group.cbm_util_rate IS '차량 용적 적재 효율 (%)';


-- --------------------------------------------------------------------
-- [tb_dispatch_detail] 배차 상세 / 경유지(Stop) 매핑 정보
-- --------------------------------------------------------------------
CREATE TABLE tb_dispatch_detail (
    dispatch_detail_id INT GENERATED ALWAYS AS IDENTITY NOT NULL,
    group_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    stop_seq INTEGER NOT NULL, -- 1st, 2nd stop 등
    stop_type VARCHAR(10) NOT NULL, -- 'LOAD' (상차), 'UNLOAD' (하차)
    node_id VARCHAR(50) NOT NULL, -- 방문 거점 ID (FK)
    eta TIMESTAMP WITHOUT TIME ZONE, -- 도착 예정시각
    ata TIMESTAMP WITHOUT TIME ZONE, -- 실제 도착시각
    stop_status VARCHAR(20) DEFAULT 'WAIT' NOT NULL, -- WAIT, ARRIVED, DEPARTED
    waiting_time_min INTEGER DEFAULT 0, -- 실적에 따른 거점 내 대기시간 (분)
    delay_reason_code VARCHAR(20), -- 대기 지연 시 지연 코드 (tb_common_code 매핑용)
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_dispatch_detail PRIMARY KEY (dispatch_detail_id),
    CONSTRAINT fk_tb_dispatch_detail_group FOREIGN KEY (group_id)
        REFERENCES tb_dispatch_group(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_dispatch_detail_order FOREIGN KEY (order_id)
        REFERENCES tb_order(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_dispatch_detail_node FOREIGN KEY (node_id)
        REFERENCES tb_node(node_id) ON DELETE RESTRICT
);

COMMENT ON TABLE tb_dispatch_detail IS '배차 그룹 상세 경유지 노선 및 오더 매핑';
COMMENT ON COLUMN tb_dispatch_detail.dispatch_detail_id IS '배차 상세 고유 번호';
COMMENT ON COLUMN tb_dispatch_detail.group_id IS '소속 배차 그룹 ID';
COMMENT ON COLUMN tb_dispatch_detail.order_id IS '배정된 운송 오더 ID';
COMMENT ON COLUMN tb_dispatch_detail.stop_seq IS '운송 노선 경유 순서';
COMMENT ON COLUMN tb_dispatch_detail.stop_type IS '경유지 역할 (LOAD: 상차지, UNLOAD: 하차지)';
COMMENT ON COLUMN tb_dispatch_detail.node_id IS '방문 거점 ID';
COMMENT ON COLUMN tb_dispatch_detail.eta IS '계획된 도착 예정 시간';
COMMENT ON COLUMN tb_dispatch_detail.ata IS '실제 도착 시간';
COMMENT ON COLUMN tb_dispatch_detail.stop_status IS '경유지 방문 상태';
COMMENT ON COLUMN tb_dispatch_detail.waiting_time_min IS '거점 대기 소요시간 (분)';
COMMENT ON COLUMN tb_dispatch_detail.delay_reason_code IS '대기 발생 사유 코드';


-- --------------------------------------------------------------------
-- [tb_tracking_log] 실시간 GPS 관제 위치 정보 (대용량 로그)
-- --------------------------------------------------------------------
CREATE TABLE tb_tracking_log (
    tracking_id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,
    group_id VARCHAR(50) NOT NULL,
    driver_id VARCHAR(50) NOT NULL,
    latitude NUMERIC(10, 8) NOT NULL,
    longitude NUMERIC(11, 8) NOT NULL,
    speed_kmh NUMERIC(5, 2) DEFAULT 0,
    bearing NUMERIC(5, 2), -- 방위각 (이동 방향)
    battery_pct INTEGER, -- 모바일 배터리 잔량 (%)
    gps_accuracy NUMERIC(5, 2), -- GPS 오차값 (m)
    collected_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_tracking_log PRIMARY KEY (tracking_id),
    CONSTRAINT fk_tb_tracking_log_group FOREIGN KEY (group_id)
        REFERENCES tb_dispatch_group(group_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_tracking_log_driver FOREIGN KEY (driver_id)
        REFERENCES tb_driver(driver_id) ON DELETE CASCADE
);

COMMENT ON TABLE tb_tracking_log IS '운송 차량 실시간 GPS 트래킹 로그';
COMMENT ON COLUMN tb_tracking_log.tracking_id IS '위치 로그 고유 일련번호';
COMMENT ON COLUMN tb_tracking_log.group_id IS '관제 대상 배차 그룹 ID';
COMMENT ON COLUMN tb_tracking_log.driver_id IS '위치 정보 전송 기사 ID';
COMMENT ON COLUMN tb_tracking_log.latitude IS '수집 당시 GPS 위도';
COMMENT ON COLUMN tb_tracking_log.longitude IS '수집 당시 GPS 경도';
COMMENT ON COLUMN tb_tracking_log.speed_kmh IS '차량 속도 (km/h)';
COMMENT ON COLUMN tb_tracking_log.bearing IS '차량 진행 방위각 (0~360도)';
COMMENT ON COLUMN tb_tracking_log.battery_pct IS '기사 스마트폰 배터리 잔여량';
COMMENT ON COLUMN tb_tracking_log.gps_accuracy IS 'GPS 위치 정밀도 오차 반경';
COMMENT ON COLUMN tb_tracking_log.collected_at IS '서버 수집 일시';


-- --------------------------------------------------------------------
-- [tb_execution] 실제 운송 실행 실적
-- --------------------------------------------------------------------
CREATE TABLE tb_execution (
    execution_id VARCHAR(50) NOT NULL,
    group_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    actual_loading_start_dt TIMESTAMP WITHOUT TIME ZONE,
    actual_loading_end_dt TIMESTAMP WITHOUT TIME ZONE,
    actual_unloading_start_dt TIMESTAMP WITHOUT TIME ZONE,
    actual_unloading_end_dt TIMESTAMP WITHOUT TIME ZONE,
    actual_distance_km NUMERIC(8, 2), -- 네비게이션 실주행 거리
    proof_signature VARCHAR(255), -- 인수자 서명 이미지 URI
    proof_photo VARCHAR(255), -- 하역 완료 현장 사진 URI
    is_anomaly CHAR(1) DEFAULT 'N' NOT NULL, -- 이상 여부 (Y/N)
    anomaly_type_code VARCHAR(20), -- 파손, 오배송, 연착 등 코드
    anomaly_desc TEXT, -- 이상 상세 내용
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_execution PRIMARY KEY (execution_id),
    CONSTRAINT fk_tb_execution_group FOREIGN KEY (group_id)
        REFERENCES tb_dispatch_group(group_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_execution_order FOREIGN KEY (order_id)
        REFERENCES tb_order(order_id) ON DELETE RESTRICT
);

COMMENT ON TABLE tb_execution IS '실제 운송 완료 및 실행 결과 실적';
COMMENT ON COLUMN tb_execution.execution_id IS '실적 고유 ID';
COMMENT ON COLUMN tb_execution.group_id IS '운송 수행 배차 그룹 ID';
COMMENT ON COLUMN tb_execution.order_id IS '대상 오더 ID';
COMMENT ON COLUMN tb_execution.actual_loading_start_dt IS '실제 상차 시작 일시';
COMMENT ON COLUMN tb_execution.actual_loading_end_dt IS '실제 상차 완료 일시';
COMMENT ON COLUMN tb_execution.actual_unloading_start_dt IS '실제 하차 시작 일시';
COMMENT ON COLUMN tb_execution.actual_unloading_end_dt IS '실제 하차 완료 및 운송 완료 일시';
COMMENT ON COLUMN tb_execution.actual_distance_km IS '실제 주행 거리 (km)';
COMMENT ON COLUMN tb_execution.proof_signature IS '인수자 서명 파일 주소';
COMMENT ON COLUMN tb_execution.proof_photo IS '인수 사진 파일 주소';
COMMENT ON COLUMN tb_execution.is_anomaly IS '배송 이상 발생 여부 (Y/N)';
COMMENT ON COLUMN tb_execution.anomaly_type_code IS '이상 유형 발생 코드';
COMMENT ON COLUMN tb_execution.anomaly_desc IS '이상 현상 상세 설명';


-- --------------------------------------------------------------------
-- [tb_settlement_billing] 매출 정산 (화주 청구용)
-- --------------------------------------------------------------------
CREATE TABLE tb_settlement_billing (
    tenant_id VARCHAR(50) NOT NULL,
    billing_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    group_id VARCHAR(50) NOT NULL,
    shipper_id VARCHAR(50) NOT NULL, -- 대상 화주사 (FK)
    base_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 계약 기준 기본료
    waiting_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 대기 지연 가산 비용
    return_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 회차비
    extra_node_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 다중 경유 가산비
    adjustment_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 기타 사후 조정비
    adjustment_reason VARCHAR(255),
    supply_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 공급가액 합계
    vat_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 부가세 합계 (10%)
    total_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 총 청구금액
    settle_status VARCHAR(20) DEFAULT 'PENDING' NOT NULL, -- PENDING: 미정산, CONFIRMED: 청구확정, INVOICED: 계산서발행, CLOSED: 수금마감
    closing_ym CHAR(6) NOT NULL, -- 마감 연월 (YYYYMM)
    closed_by VARCHAR(50), -- 마감 담당자 ID
    closed_at TIMESTAMP WITHOUT TIME ZONE, -- 마감 처리 일시
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_settlement_billing PRIMARY KEY (billing_id),
    CONSTRAINT fk_tb_settlement_billing_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_settlement_billing_order FOREIGN KEY (order_id)
        REFERENCES tb_order(order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_settlement_billing_group FOREIGN KEY (group_id)
        REFERENCES tb_dispatch_group(group_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_settlement_billing_shipper FOREIGN KEY (shipper_id)
        REFERENCES tb_partner(partner_id) ON DELETE RESTRICT
);

COMMENT ON TABLE tb_settlement_billing IS '매출 정산 (대고객사/화주 청구 운송료 관리)';
COMMENT ON COLUMN tb_settlement_billing.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_settlement_billing.billing_id IS '매출 정산 ID';
COMMENT ON COLUMN tb_settlement_billing.order_id IS '운송 오더 ID';
COMMENT ON COLUMN tb_settlement_billing.group_id IS '수행 배차 그룹 ID';
COMMENT ON COLUMN tb_settlement_billing.shipper_id IS '청구 대상 화주사 ID';
COMMENT ON COLUMN tb_settlement_billing.base_fee IS '단가표 기준 기본료';
COMMENT ON COLUMN tb_settlement_billing.waiting_fee IS '실적 기반 부과된 대기료';
COMMENT ON COLUMN tb_settlement_billing.return_fee IS '회차에 의해 발생한 회차료';
COMMENT ON COLUMN tb_settlement_billing.extra_node_fee IS '추가 경유지 요금';
COMMENT ON COLUMN tb_settlement_billing.adjustment_fee IS '기타 비용 사후 조정액 (+/-)';
COMMENT ON COLUMN tb_settlement_billing.adjustment_reason IS '조정 발생 사유';
COMMENT ON COLUMN tb_settlement_billing.supply_amt IS '세금 제외 공급 가액';
COMMENT ON COLUMN tb_settlement_billing.vat_amt IS '부가가치세액 (10%)';
COMMENT ON COLUMN tb_settlement_billing.total_amt IS '합계 금액';
COMMENT ON COLUMN tb_settlement_billing.settle_status IS '정산 진행 상태';
COMMENT ON COLUMN tb_settlement_billing.closing_ym IS '마감 대상 연월 (YYYYMM)';
COMMENT ON COLUMN tb_settlement_billing.closed_by IS '마감 처리 담당자';
COMMENT ON COLUMN tb_settlement_billing.closed_at IS '최종 마감 확정 일시';


-- --------------------------------------------------------------------
-- [tb_settlement_payment] 매입 정산 (운송사/기사 지급용)
-- --------------------------------------------------------------------
CREATE TABLE tb_settlement_payment (
    tenant_id VARCHAR(50) NOT NULL,
    payment_id VARCHAR(50) NOT NULL,
    group_id VARCHAR(50) NOT NULL,
    carrier_id VARCHAR(50), -- 협력 운송사 ID (개인용차기사 배차의 경우 NULL)
    driver_id VARCHAR(50) NOT NULL, -- 지급 대상 운전기사 ID
    base_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 지급 기준 기본료
    extra_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 추가 운임 지급액
    deduction_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 사고, 연착 등 지불 공제금액
    deduction_reason VARCHAR(255), -- 공제금액 사유
    adjustment_fee NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 기타 사후 조정 지급액
    adjustment_reason VARCHAR(255),
    supply_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 공급가액 합계
    vat_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 부가세 합계 (10% 또는 개별 세율)
    total_amt NUMERIC(15, 2) NOT NULL DEFAULT 0, -- 최종 지급 합계액
    settle_status VARCHAR(20) DEFAULT 'PENDING' NOT NULL, -- PENDING: 지급미확정, CONFIRMED: 지급확정, PAID: 지급완료, CLOSED: 정산마감
    closing_ym CHAR(6) NOT NULL, -- 마감 연월 (YYYYMM)
    closed_by VARCHAR(50), -- 마감 승인 담당자
    closed_at TIMESTAMP WITHOUT TIME ZONE, -- 지급 마감 일시
    created_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by VARCHAR(50) DEFAULT 'SYSTEM' NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT pk_tb_settlement_payment PRIMARY KEY (payment_id),
    CONSTRAINT fk_tb_settlement_payment_tenant FOREIGN KEY (tenant_id)
        REFERENCES tb_tenant(tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tb_settlement_payment_group FOREIGN KEY (group_id)
        REFERENCES tb_dispatch_group(group_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_settlement_payment_carrier FOREIGN KEY (carrier_id)
        REFERENCES tb_partner(partner_id) ON DELETE RESTRICT,
    CONSTRAINT fk_tb_settlement_payment_driver FOREIGN KEY (driver_id)
        REFERENCES tb_driver(driver_id) ON DELETE RESTRICT
);

COMMENT ON TABLE tb_settlement_payment IS '매입 정산 (협력 운송사 및 용차 기사 지급 운송료 관리)';
COMMENT ON COLUMN tb_settlement_payment.tenant_id IS '테넌트 ID';
COMMENT ON COLUMN tb_settlement_payment.payment_id IS '매입 정산 ID';
COMMENT ON COLUMN tb_settlement_payment.group_id IS '지급 발생 배차 그룹 ID';
COMMENT ON COLUMN tb_settlement_payment.carrier_id IS '지급 대상 운송사 ID (개인 용차의 경우 NULL 가능)';
COMMENT ON COLUMN tb_settlement_payment.driver_id IS '지급 대상 운전기사 ID';
COMMENT ON COLUMN tb_settlement_payment.base_fee IS '지급 계약 기준 기본료';
COMMENT ON COLUMN tb_settlement_payment.extra_fee IS '추가 발생 경유지 및 가산료 지급분';
COMMENT ON COLUMN tb_settlement_payment.deduction_amt IS '패널티 및 파손 등에 의한 공제액';
COMMENT ON COLUMN tb_settlement_payment.deduction_reason IS '공제 사유';
COMMENT ON COLUMN tb_settlement_payment.adjustment_fee IS '기타 비용 사후 조정 지급액 (+/-)';
COMMENT ON COLUMN tb_settlement_payment.adjustment_reason IS '조정 발생 사유';
COMMENT ON COLUMN tb_settlement_payment.supply_amt IS '세금 제외 공급 가액';
COMMENT ON COLUMN tb_settlement_payment.vat_amt IS '부가가치세액';
COMMENT ON COLUMN tb_settlement_payment.total_amt IS '최종 지급 대상 총액';
COMMENT ON COLUMN tb_settlement_payment.settle_status IS '정산 진행 상태';
COMMENT ON COLUMN tb_settlement_payment.closing_ym IS '마감 대상 연월 (YYYYMM)';
COMMENT ON COLUMN tb_settlement_payment.closed_by IS '지급 마감 처리 담당자';
COMMENT ON COLUMN tb_settlement_payment.closed_at IS '지급 마감 처리 일시';


-- ====================================================================
-- 3. INDEXES (Multi-Tenant Optimization for PostgreSQL 11)
-- ====================================================================

-- [tb_partner] 테넌트별 유형 조회 및 사업자등록번호 조회
CREATE INDEX idx_partner_tenant_type ON tb_partner (tenant_id, partner_type, use_yn);
CREATE INDEX idx_partner_biz_no ON tb_partner (biz_no);

-- [tb_user] 테넌트별 상태 조회
CREATE INDEX idx_user_tenant_status ON tb_user (tenant_id, user_status);
CREATE INDEX idx_user_partner ON tb_user (partner_id);

-- [tb_node] 위경도 및 거점유형 인덱스
CREATE INDEX idx_node_coords ON tb_node (latitude, longitude);
CREATE INDEX idx_node_tenant_type ON tb_node (tenant_id, node_type, use_yn);

-- [tb_driver] 테넌트별 소속사 및 로그인계정 검색
CREATE INDEX idx_driver_tenant_carrier ON tb_driver (tenant_id, carrier_id);
CREATE INDEX idx_driver_user ON tb_driver (user_id);
CREATE INDEX idx_driver_phone ON tb_driver (phone_no);

-- [tb_vehicle] 테넌트별 소속 운송사 및 차량번호 조회
CREATE INDEX idx_vehicle_tenant_carrier ON tb_vehicle (tenant_id, carrier_id);
CREATE INDEX idx_vehicle_no ON tb_vehicle (vehicle_no);

-- [tb_tariff] 테넌트별 단가표 조건 검색 최적화
CREATE INDEX idx_tariff_tenant_lookup ON tb_tariff (tenant_id, start_node_id, end_node_id, truck_type, tonnage, use_yn);
CREATE INDEX idx_tariff_dates ON tb_tariff (start_date, end_date);

-- [tb_order] 테넌트별 오더 일자 및 상태 조회 최적화
CREATE INDEX idx_order_tenant_dates ON tb_order (tenant_id, req_loading_dt, req_unloading_dt);
CREATE INDEX idx_order_tenant_status ON tb_order (tenant_id, order_status);
CREATE INDEX idx_order_shipper ON tb_order (shipper_id);
CREATE INDEX idx_order_erp_ref ON tb_order (erp_ref_no);

-- [tb_order_detail] 오더 연동 품목 인덱스
CREATE INDEX idx_order_detail_fk ON tb_order_detail (order_id);

-- [tb_dispatch_group] 테넌트별 계획일자 및 상태 인덱스
CREATE INDEX idx_dispatch_tenant_status ON tb_dispatch_group (tenant_id, plan_status);
CREATE INDEX idx_dispatch_tenant_date ON tb_dispatch_group (tenant_id, plan_date);
CREATE INDEX idx_dispatch_carrier_veh_dri ON tb_dispatch_group (carrier_id, vehicle_id, driver_id);
CREATE INDEX idx_dispatch_planner ON tb_dispatch_group (planner_id);

-- [tb_dispatch_detail] 배차 경유지 순번 및 오더 조회 최적화
CREATE INDEX idx_dispatch_detail_lookup ON tb_dispatch_detail (group_id, stop_seq);
CREATE INDEX idx_dispatch_detail_order ON tb_dispatch_detail (order_id);

-- [tb_tracking_log] 위치 정보 이력 대용량 인덱스
CREATE INDEX idx_tracking_history ON tb_tracking_log (group_id, collected_at DESC);
CREATE INDEX idx_tracking_driver ON tb_tracking_log (driver_id, collected_at DESC);

-- [tb_execution] 오더별 배송 결과/실적 조회 최적화
CREATE INDEX idx_execution_order_id ON tb_execution (order_id);
CREATE INDEX idx_execution_group_id ON tb_execution (group_id);

-- [tb_settlement_billing] 테넌트별 매출 마감연월 및 상태 인덱스
CREATE INDEX idx_billing_tenant_closing ON tb_settlement_billing (tenant_id, closing_ym, settle_status);
CREATE INDEX idx_billing_shipper ON tb_settlement_billing (shipper_id);

-- [tb_settlement_payment] 테넌트별 매입 마감연월 및 상태 인덱스
CREATE INDEX idx_payment_tenant_closing ON tb_settlement_payment (tenant_id, closing_ym, settle_status);
CREATE INDEX idx_payment_driver_carrier ON tb_settlement_payment (driver_id, carrier_id);
