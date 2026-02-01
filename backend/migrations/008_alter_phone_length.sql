-- OAuth 사용자를 위해 phone 컬럼 길이 확장
-- OAuth 사용자는 "oauth_<nanosecond_timestamp>" 형식의 placeholder 사용 (약 25자)
ALTER TABLE users ALTER COLUMN phone TYPE VARCHAR(50);

COMMENT ON COLUMN users.phone IS '전화번호 또는 OAuth placeholder (oauth_xxxxx)';
