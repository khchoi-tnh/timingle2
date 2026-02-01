-- 감사 로그 테이블
-- 관리자의 모든 액션을 기록

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    admin_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action VARCHAR(100) NOT NULL,           -- 'USER_SUSPENDED', 'EVENT_DELETED', 'ROLE_CHANGED' 등
    target_type VARCHAR(50) NOT NULL,       -- 'user', 'event', 'setting'
    target_id BIGINT,                       -- 대상 엔티티 ID
    old_value JSONB,                        -- 변경 전 값
    new_value JSONB,                        -- 변경 후 값
    ip_address INET,                        -- 관리자 IP
    user_agent TEXT,                        -- 브라우저/클라이언트 정보
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_audit_logs_admin_id ON audit_logs(admin_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_target ON audit_logs(target_type, target_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- 파티셔닝을 위한 코멘트 (향후 데이터 증가 시 고려)
COMMENT ON TABLE audit_logs IS '관리자 액션 감사 로그 - 모든 관리자 작업을 기록';
