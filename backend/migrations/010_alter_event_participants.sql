-- event_participants 테이블 확장
-- 초대 관련 컬럼 추가

-- 초대 상태 (기존 confirmed 컬럼 대체)
ALTER TABLE event_participants
ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'PENDING';
-- 'PENDING': 초대됨, 'ACCEPTED': 수락, 'DECLINED': 거절

-- 초대한 사람
ALTER TABLE event_participants
ADD COLUMN IF NOT EXISTS invited_by BIGINT REFERENCES users(id) ON DELETE SET NULL;

-- 초대 시간
ALTER TABLE event_participants
ADD COLUMN IF NOT EXISTS invited_at TIMESTAMPTZ DEFAULT NOW();

-- 응답 시간
ALTER TABLE event_participants
ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ;

-- 초대 방식
ALTER TABLE event_participants
ADD COLUMN IF NOT EXISTS invite_method VARCHAR(20);
-- 'FRIEND': 친구 목록에서 초대, 'LINK': 초대 링크, 'QR': QR 코드, 'CREATOR': 생성자

-- 기존 데이터 마이그레이션: confirmed=true → status='ACCEPTED'
UPDATE event_participants
SET status = CASE WHEN confirmed = true THEN 'ACCEPTED' ELSE 'PENDING' END,
    responded_at = CASE WHEN confirmed = true THEN confirmed_at ELSE NULL END
WHERE status = 'PENDING' AND confirmed IS NOT NULL;

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_event_participants_status ON event_participants(status);
CREATE INDEX IF NOT EXISTS idx_event_participants_invited_by ON event_participants(invited_by);

COMMENT ON COLUMN event_participants.status IS 'PENDING: 초대됨, ACCEPTED: 수락, DECLINED: 거절';
COMMENT ON COLUMN event_participants.invite_method IS 'FRIEND: 친구목록, LINK: 초대링크, QR: QR코드, CREATOR: 생성자';
