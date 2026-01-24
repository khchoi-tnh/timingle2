-- 이벤트 초대 링크 테이블
CREATE TABLE IF NOT EXISTS event_invite_links (
  id BIGSERIAL PRIMARY KEY,
  event_id BIGINT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  code VARCHAR(20) NOT NULL UNIQUE,  -- 짧은 고유 코드 (예: abc123xy)
  created_by BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ,            -- NULL이면 만료 없음
  max_uses INT NOT NULL DEFAULT 0,   -- 0 = 무제한
  use_count INT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_invite_links_code ON event_invite_links(code);
CREATE INDEX idx_invite_links_event ON event_invite_links(event_id);
CREATE INDEX idx_invite_links_active ON event_invite_links(is_active) WHERE is_active = true;

COMMENT ON TABLE event_invite_links IS '이벤트 초대 링크';
COMMENT ON COLUMN event_invite_links.code IS '짧은 고유 코드 (URL에 사용)';
COMMENT ON COLUMN event_invite_links.max_uses IS '최대 사용 횟수 (0=무제한)';
COMMENT ON COLUMN event_invite_links.use_count IS '현재 사용 횟수';
