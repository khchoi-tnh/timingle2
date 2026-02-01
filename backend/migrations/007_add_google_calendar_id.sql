-- events 테이블에 Google Calendar 연동 ID 컬럼 추가
ALTER TABLE events ADD COLUMN IF NOT EXISTS google_calendar_id VARCHAR(255);

-- Google Calendar ID 인덱스 (연동된 이벤트 조회용)
CREATE INDEX IF NOT EXISTS idx_events_google_calendar_id ON events(google_calendar_id);

COMMENT ON COLUMN events.google_calendar_id IS 'Google Calendar에 동기화된 이벤트 ID';
