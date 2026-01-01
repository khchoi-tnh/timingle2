-- 이벤트 참여자 테이블
CREATE TABLE IF NOT EXISTS event_participants (
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  confirmed BOOLEAN DEFAULT FALSE,
  confirmed_at TIMESTAMPTZ,
  PRIMARY KEY (event_id, user_id)
);

-- 인덱스
CREATE INDEX idx_event_participants_user_id ON event_participants(user_id);
CREATE INDEX idx_event_participants_event_confirmed ON event_participants(event_id, confirmed);
