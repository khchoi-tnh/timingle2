-- 친구 관계 테이블
-- 친구 요청은 단방향, 수락 시 양방향 레코드 생성
CREATE TABLE IF NOT EXISTS friendships (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',  -- 'PENDING', 'ACCEPTED', 'BLOCKED'
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, friend_id),
  CONSTRAINT chk_not_self_friend CHECK (user_id != friend_id)
);

-- 인덱스
CREATE INDEX idx_friendships_user ON friendships(user_id);
CREATE INDEX idx_friendships_friend ON friendships(friend_id);
CREATE INDEX idx_friendships_status ON friendships(status);
CREATE INDEX idx_friendships_user_status ON friendships(user_id, status);

COMMENT ON TABLE friendships IS '친구 관계 테이블';
COMMENT ON COLUMN friendships.status IS 'PENDING: 요청중, ACCEPTED: 수락됨, BLOCKED: 차단됨';
