-- OAuth 계정 연동 테이블
-- Google, Apple 등 소셜 로그인 계정 연동 정보 저장
CREATE TABLE IF NOT EXISTS oauth_accounts (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  provider VARCHAR(50) NOT NULL,           -- 'google', 'apple', etc.
  provider_user_id VARCHAR(255) NOT NULL,  -- Provider's unique user ID
  email VARCHAR(255),                      -- Provider's email
  name VARCHAR(100),                       -- Provider's display name
  picture_url TEXT,                        -- Provider's profile picture URL
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(provider, provider_user_id)
);

-- 인덱스
CREATE INDEX idx_oauth_accounts_user_id ON oauth_accounts(user_id);
CREATE INDEX idx_oauth_accounts_provider ON oauth_accounts(provider);
CREATE INDEX idx_oauth_accounts_provider_user_id ON oauth_accounts(provider, provider_user_id);
CREATE INDEX idx_oauth_accounts_email ON oauth_accounts(email);
