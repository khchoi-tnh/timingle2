-- Google Calendar 연동을 위한 OAuth 토큰 저장 필드 추가
-- access_token: Google API 호출용 토큰
-- refresh_token: access_token 갱신용 토큰
-- token_expiry: access_token 만료 시간
-- scopes: 부여된 권한 목록

ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS access_token TEXT;
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS refresh_token TEXT;
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS token_expiry TIMESTAMPTZ;
ALTER TABLE oauth_accounts ADD COLUMN IF NOT EXISTS scopes TEXT[];

-- 토큰 만료 시간 인덱스 (갱신 대상 조회용)
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_token_expiry ON oauth_accounts(token_expiry);

COMMENT ON COLUMN oauth_accounts.access_token IS 'Google API 호출용 Access Token';
COMMENT ON COLUMN oauth_accounts.refresh_token IS 'Access Token 갱신용 Refresh Token';
COMMENT ON COLUMN oauth_accounts.token_expiry IS 'Access Token 만료 시간';
COMMENT ON COLUMN oauth_accounts.scopes IS '부여된 OAuth Scope 목록 (예: calendar, email)';
