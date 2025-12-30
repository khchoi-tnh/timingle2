-- timingle PostgreSQL 초기화 스크립트

-- UUID 확장 활성화
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 타임존 설정
SET timezone = 'Asia/Seoul';

-- 기본 사용자 확인 (이미 생성됨)
-- timingle / timingle_dev_password

-- 데이터베이스 버전 확인
SELECT version();
