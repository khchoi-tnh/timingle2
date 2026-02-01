-- Admin 역할 추가
-- 기존 CHECK 제약조건을 수정하여 ADMIN, SUPER_ADMIN 역할 추가

-- 기존 CHECK 제약조건 삭제
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- 새로운 CHECK 제약조건 추가 (ADMIN, SUPER_ADMIN 포함)
ALTER TABLE users ADD CONSTRAINT users_role_check
  CHECK (role IN ('USER', 'BUSINESS', 'ADMIN', 'SUPER_ADMIN'));

-- 사용자 상태 컬럼 추가 (활성/정지)
ALTER TABLE users ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'ACTIVE'
  CHECK (status IN ('ACTIVE', 'SUSPENDED', 'DELETED'));

-- 상태 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
