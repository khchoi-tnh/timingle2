-- timingle Keyspace (Discord-level 확장성)
-- 개발 환경: SimpleStrategy 사용
CREATE KEYSPACE IF NOT EXISTS timingle
  WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
  }
  AND durable_writes = true;

USE timingle;

-- 1. 채팅 메시지 (이벤트별)
CREATE TABLE IF NOT EXISTS chat_messages_by_event (
  event_id BIGINT,              -- Partition Key
  created_at TIMESTAMP,         -- Clustering Key 1
  message_id UUID,              -- Clustering Key 2
  sender_id BIGINT,
  sender_name TEXT,
  sender_profile_url TEXT,
  message TEXT,
  message_type TEXT,            -- 'text', 'system', 'image'
  attachments LIST<TEXT>,
  reply_to UUID,
  edited_at TIMESTAMP,
  is_deleted BOOLEAN,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY ((event_id), created_at, message_id)
) WITH CLUSTERING ORDER BY (created_at ASC, message_id ASC)
  AND compaction = {
    'class': 'TimeWindowCompactionStrategy',
    'compaction_window_size': 1,
    'compaction_window_unit': 'DAYS'
  }
  AND gc_grace_seconds = 86400
  AND caching = {'keys': 'ALL', 'rows_per_partition': '100'};

-- 2. 이벤트 히스토리 (변경 로그)
CREATE TABLE IF NOT EXISTS event_history (
  event_id BIGINT,
  changed_at TIMESTAMP,
  change_id UUID,
  actor_id BIGINT,
  actor_name TEXT,
  change_type TEXT,             -- 'CREATED', 'UPDATED', 'CONFIRMED', 'CANCELED'
  field_name TEXT,              -- 변경된 필드
  old_value TEXT,
  new_value TEXT,
  metadata MAP<TEXT, TEXT>,
  PRIMARY KEY ((event_id), changed_at, change_id)
) WITH CLUSTERING ORDER BY (changed_at DESC, change_id DESC)
  AND compaction = {'class': 'SizeTieredCompactionStrategy'}
  AND gc_grace_seconds = 864000; -- 10일 (노쇼 증거 보관)

-- 3. 읽지 않은 메시지 카운터
CREATE TABLE IF NOT EXISTS unread_message_counts (
  event_id BIGINT,
  user_id BIGINT,
  count COUNTER,
  PRIMARY KEY ((event_id, user_id))
);

-- 4. 타이핑 인디케이터 (TTL 10초)
CREATE TABLE IF NOT EXISTS typing_indicators (
  event_id BIGINT,
  user_id BIGINT,
  user_name TEXT,
  started_at TIMESTAMP,
  PRIMARY KEY ((event_id), user_id)
) WITH default_time_to_live = 10;

-- 5. 메시지 반응 (좋아요, 이모지)
CREATE TABLE IF NOT EXISTS message_reactions (
  message_id UUID,
  user_id BIGINT,
  reaction TEXT,                -- '👍', '❤️', '😂', etc.
  created_at TIMESTAMP,
  PRIMARY KEY ((message_id), user_id)
);

-- 6. 사용자별 채팅 메시지 인덱스 (선택적, 사용자 활동 추적)
CREATE TABLE IF NOT EXISTS chat_messages_by_user (
  user_id BIGINT,
  created_at TIMESTAMP,
  event_id BIGINT,
  message_id UUID,
  PRIMARY KEY ((user_id), created_at, event_id)
) WITH CLUSTERING ORDER BY (created_at DESC, event_id ASC);
