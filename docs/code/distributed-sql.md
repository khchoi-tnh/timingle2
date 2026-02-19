# 분산 SQL 심층 분석 - PostgreSQL vs CockroachDB vs TiDB

> timingle이 1억 규모에서 왜 분산 SQL을 고려해야 하는지, 각 선택지의 차이는 무엇인지

---

## 왜 PostgreSQL 단독으로는 1억이 안 되는가?

### PostgreSQL의 근본적 한계

PostgreSQL은 **단일 노드 관계형 DB**입니다. 아무리 성능을 끌어올려도 **물리적 한계**가 존재합니다.

```
1억 사용자 시 데이터 규모:

users 테이블:         1억 rows         (~50GB)
events 테이블:        10억 rows        (~200GB)
event_participants:   30억 rows        (~100GB)
refresh_tokens:       2억 rows         (~20GB)
oauth_accounts:       1.5억 rows       (~15GB)
invite_links:         5억 rows         (~30GB)
─────────────────────────────────────────────
합계:                  ~45억 rows       (~415GB)
```

### 구체적으로 무엇이 터지는가

| 한계 | 수치 | 설명 |
|------|------|------|
| **단일 쓰기 노드** | 1대만 | Primary 1대에서만 INSERT/UPDATE 가능 |
| **최대 연결 수** | ~5,000 | PgBouncer로도 실제 동시 쿼리는 수백 개 |
| **쓰기 TPS** | ~50,000 | 복잡한 트랜잭션이면 훨씬 낮음 |
| **디스크 I/O** | 물리적 한계 | 415GB 테이블 풀 스캔 = 수 분 |
| **인덱스 크기** | 수십 GB | 메모리에 안 올라가면 디스크 접근 → 느림 |
| **VACUUM 부하** | 큰 테이블 | MVCC 정리 시 성능 급락 |

### PostgreSQL 확장의 현실적 단계

```
Phase 1: 수직 확장 (1만명)
  ├── 더 좋은 서버 (CPU, RAM, SSD)
  ├── PgBouncer (커넥션 풀링)
  └── 인덱스 + 쿼리 최적화

Phase 2: 읽기 분산 (10만명)
  ├── Read Replica (읽기 전용 복제본)
  ├── 읽기 70% → Replica, 쓰기 30% → Primary
  └── Streaming Replication

Phase 3: 수동 샤딩 (100만명)
  ├── user_id 기반으로 DB 분할
  ├── 애플리케이션에서 라우팅 로직 직접 작성
  └── 크로스 샤드 JOIN 불가 → 코드 복잡도 폭증

Phase 4: ??? (1억명)
  ├── 수동 샤딩 3~10개 관리 = 운영 지옥
  ├── 리밸런싱 = 다운타임 또는 극도로 복잡
  └── 여기서 분산 SQL 도입 고려
```

**핵심:** Phase 3의 수동 샤딩이 **운영 복잡도의 극한**이 되면, 분산 SQL이 이를 자동화해줍니다.

---

## 분산 SQL이란?

**분산 SQL = SQL 인터페이스 + 자동 샤딩 + 분산 합의**

```
기존 PostgreSQL:
  App → 1대의 PostgreSQL (모든 데이터가 여기)

수동 샤딩:
  App → 라우팅 로직 → Shard 1 (user 1~33M)
                     → Shard 2 (user 34~66M)
                     → Shard 3 (user 67~100M)
  (샤드 추가/리밸런싱 = 개발자가 직접)

분산 SQL:
  App → CockroachDB/TiDB (SQL 그대로 사용)
        내부적으로 자동 샤딩, 자동 리밸런싱
        앱 코드 변경 최소화
```

### 분산 SQL의 핵심 특성

| 특성 | 설명 |
|------|------|
| **자동 샤딩** | 데이터를 Range 단위로 자동 분할 |
| **자동 리밸런싱** | 노드 추가 시 데이터 자동 재배치 |
| **분산 트랜잭션** | 여러 노드에 걸친 ACID 보장 |
| **SQL 호환** | 기존 SQL 쿼리 대부분 그대로 사용 |
| **노드 추가 = 용량 추가** | 수평 확장이 선형적 |
| **자동 장애 복구** | 노드 다운 시 자동으로 다른 노드가 대체 |

---

## CockroachDB 상세 분석

### 아키텍처

```
                    ┌─────────────────────────────────┐
                    │        SQL Layer                 │
                    │  (PostgreSQL 호환 프로토콜)        │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
                    │     Distribution Layer           │
                    │  (Range 기반 자동 샤딩)            │
                    │  Range: key 범위별 64MB 단위       │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
                    │      Replication Layer           │
                    │  (Raft 합의 알고리즘)              │
                    │  기본 3-way 복제                   │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────▼─────────────────┐
                    │       Storage Layer              │
                    │  (Pebble - RocksDB 포크)          │
                    │  각 노드의 로컬 키-값 저장소        │
                    └─────────────────────────────────┘
```

### CockroachDB 데이터 분산 방식

```
users 테이블 (1억 rows) 내부 처리:

1. Range로 분할 (각 ~64MB):
   Range 1: user_id 1 ~ 100,000
   Range 2: user_id 100,001 ~ 200,000
   ...
   Range 1000: user_id 99,900,001 ~ 100,000,000

2. Range를 노드에 분배:
   Node 1: Range 1, 4, 7, 10...  (약 333개)
   Node 2: Range 2, 5, 8, 11...  (약 333개)
   Node 3: Range 3, 6, 9, 12...  (약 334개)

3. 각 Range는 3개 노드에 복제 (Raft):
   Range 1: Node 1 (Leader), Node 2 (Follower), Node 3 (Follower)
   → Node 1 다운 → Node 2가 자동으로 Leader 승격
```

### PostgreSQL과의 호환성

| 항목 | 호환 여부 | 비고 |
|------|----------|------|
| **기본 SQL** | ✅ 완벽 | SELECT, INSERT, UPDATE, DELETE |
| **JOIN** | ✅ 지원 | 분산 JOIN (크로스 노드) |
| **트랜잭션** | ✅ Serializable | PostgreSQL보다 강한 기본 격리 수준 |
| **인덱스** | ✅ 지원 | B-Tree, GIN (일부) |
| **JSONB** | ✅ 지원 | timingle의 old_value/new_value 사용 가능 |
| **Stored Procedure** | ⚠️ 제한적 | PL/pgSQL 일부만 지원 |
| **트리거** | ❌ 미지원 | `update_updated_at` 트리거 대체 필요 |
| **시퀀스** | ⚠️ 분산 시퀀스 | BIGSERIAL → UUID 권장 |
| **LISTEN/NOTIFY** | ❌ 미지원 | CDC (Change Data Capture) 사용 |
| **pg_trgm (LIKE)** | ❌ 미지원 | 전문 검색은 별도 솔루션 |

### timingle 마이그레이션 영향

```sql
-- 현재 timingle 코드에서 변경 필요한 부분:

-- 1. BIGSERIAL → UUID (분산 환경에서 시퀀스 충돌 방지)
-- 현재:
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    ...
);

-- CockroachDB 권장:
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ...
);

-- 2. 트리거 대체 (updated_at 자동 갱신)
-- 현재:
CREATE TRIGGER update_events_updated_at
    BEFORE UPDATE ON events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- CockroachDB: 앱 레벨에서 처리
-- Go 코드에서 UPDATE 시 항상 updated_at = NOW() 포함

-- 3. ON CONFLICT 구문 → 호환 (변경 불필요)
INSERT INTO event_participants ... ON CONFLICT DO NOTHING;
-- CockroachDB도 동일 문법 지원 ✅
```

### CockroachDB 핵심 특징 요약

| 특징 | 내용 |
|------|------|
| **개발사** | Cockroach Labs (미국) |
| **언어** | Go |
| **프로토콜** | PostgreSQL 호환 |
| **합의** | Raft |
| **격리 수준** | Serializable (기본) |
| **라이선스** | BSL (Business Source License) → 3년 후 Apache 2.0 |
| **관리형 서비스** | CockroachDB Cloud |
| **멀티 리전** | 네이티브 지원 (Global Tables, Regional Tables) |
| **적합 사례** | 금융, 글로벌 서비스, 강한 일관성 필요 |

---

## TiDB 상세 분석

### 아키텍처

```
                    ┌─────────────────────────────────┐
                    │         TiDB Server              │
                    │  (MySQL 호환 프로토콜)              │
                    │  SQL 파싱, 최적화, 실행             │
                    └───────┬─────────────┬───────────┘
                            │             │
              ┌─────────────▼───┐  ┌──────▼──────────┐
              │   TiKV Cluster  │  │    TiFlash       │
              │  (행 기반 저장)   │  │  (열 기반 저장)   │
              │  트랜잭션 처리    │  │  분석 쿼리 가속    │
              └───────┬─────────┘  └─────────────────┘
                      │
              ┌───────▼─────────┐
              │   PD (Placement │
              │   Driver)       │
              │  메타데이터,      │
              │  스케줄링, TSO    │
              └─────────────────┘
```

### TiDB의 구조적 차이

**TiDB는 3개 컴포넌트로 분리:**

| 컴포넌트 | 역할 | 특징 |
|---------|------|------|
| **TiDB Server** | SQL 처리 (Stateless) | 수평 확장 가능, MySQL 프로토콜 |
| **TiKV** | 분산 KV 저장소 | Raft 복제, Region 기반 샤딩 |
| **PD** | 클러스터 관리자 | 타임스탬프 발급, 스케줄링 |
| **TiFlash** (선택) | 열 기반 저장소 | OLAP 분석 쿼리 가속 |

### MySQL 호환성 (PostgreSQL이 아님!)

```
⚠️ 중요: TiDB는 MySQL 호환이지 PostgreSQL 호환이 아닙니다!

현재 timingle:
  Go App → database/sql + lib/pq → PostgreSQL

TiDB로 전환 시:
  Go App → database/sql + go-sql-driver/mysql → TiDB

→ 드라이버 교체 + SQL 문법 일부 변경 필요
```

| 항목 | PostgreSQL (현재) | TiDB (MySQL 호환) | 변경 필요 |
|------|------------------|------------------|----------|
| **드라이버** | `lib/pq` | `go-sql-driver/mysql` | ✅ 교체 |
| **JSONB** | `JSONB` | `JSON` | ⚠️ 일부 함수 차이 |
| **BOOLEAN** | `BOOLEAN` | `TINYINT(1)` | ⚠️ 타입 맵핑 |
| **TIMESTAMPTZ** | 지원 | `TIMESTAMP` (UTC) | ⚠️ 타임존 처리 |
| **SERIAL** | `BIGSERIAL` | `AUTO_INCREMENT` | ✅ 변경 |
| **INET 타입** | 지원 | 미지원 | ✅ VARCHAR로 변경 |
| **배열 타입** | 지원 | 미지원 | ✅ JSON으로 변경 |
| **ON CONFLICT** | `ON CONFLICT DO NOTHING` | `INSERT IGNORE` | ✅ 변경 |
| **UPSERT** | `ON CONFLICT DO UPDATE` | `ON DUPLICATE KEY UPDATE` | ✅ 변경 |

### TiDB의 강점

| 강점 | 설명 |
|------|------|
| **HTAP** | TiKV (OLTP) + TiFlash (OLAP) 동시 지원 |
| **MySQL 생태계** | MySQL 도구/드라이버/ORM 그대로 사용 |
| **컴퓨트-스토리지 분리** | TiDB Server와 TiKV 독립 확장 |
| **실시간 분석** | TiFlash로 대시보드/분석 쿼리 가속 |
| **개발사** | PingCAP (중국, 미국 지사) |
| **오픈소스** | Apache 2.0 (완전 오픈소스) |

---

## 3자 비교: PostgreSQL vs CockroachDB vs TiDB

### 핵심 비교

| 기준 | PostgreSQL | CockroachDB | TiDB |
|------|-----------|-------------|------|
| **호환 프로토콜** | PostgreSQL | PostgreSQL | MySQL |
| **확장 방식** | 수직 + 수동 샤딩 | 자동 분산 | 자동 분산 |
| **최대 규모** | ~수천만 (단독) | 수억+ | 수억+ |
| **합의 알고리즘** | 없음 (단일 노드) | Raft | Raft |
| **기본 격리 수준** | Read Committed | Serializable | Snapshot Isolation |
| **ACID** | ✅ | ✅ 분산 ACID | ✅ 분산 ACID |
| **멀티 리전** | 수동 구성 | 네이티브 지원 | 지원 |
| **운영 난이도** | 낮음 | 중간 | 중~고 (3 컴포넌트) |
| **비용** | 낮음 | 높음 | 중간 |
| **라이선스** | PostgreSQL License | BSL → Apache 2.0 | Apache 2.0 |

### 성능 비교

| 시나리오 | PostgreSQL | CockroachDB | TiDB |
|---------|-----------|-------------|------|
| **단일 행 읽기** | ⚡ 0.1ms | 1~2ms | 1~3ms |
| **단일 행 쓰기** | ⚡ 0.5ms | 3~5ms | 2~4ms |
| **복잡한 JOIN** | ⚡ 빠름 | 느림 (분산 JOIN) | 중간 |
| **대량 쓰기 (TPS)** | ~50K | ~200K+ (3노드) | ~300K+ (3노드) |
| **수평 확장** | ❌ 불가 | ✅ 선형 | ✅ 선형 |
| **분석 쿼리 (OLAP)** | 느림 | 느림 | ⚡ TiFlash |

**중요:** 단일 노드 성능은 PostgreSQL이 압도적으로 빠릅니다. 분산 SQL은 **노드 수 증가로 전체 처리량을 올리는 것**이 목적입니다.

```
PostgreSQL 1대:  쓰기 50,000 TPS (한계)
CockroachDB 3대: 쓰기 200,000 TPS
CockroachDB 9대: 쓰기 600,000 TPS  ← 노드 추가 = 성능 증가
TiDB 3 TiKV:    쓰기 300,000 TPS
TiDB 9 TiKV:    쓰기 900,000 TPS  ← 노드 추가 = 성능 증가
```

---

## timingle에 적용한다면?

### 추천: CockroachDB

**이유:**

| 이유 | 설명 |
|------|------|
| **PostgreSQL 호환** | 현재 timingle이 PostgreSQL 사용 → 마이그레이션 비용 최소화 |
| **Go 드라이버 호환** | `lib/pq` 또는 `pgx` 그대로 사용 가능 |
| **SQL 문법 90%+ 동일** | 대부분의 쿼리 수정 없이 동작 |
| **분산 ACID** | 이벤트 참가자 추가 등 트랜잭션이 중요한 timingle에 적합 |
| **멀티 리전 네이티브** | 한국 → 일본/미국 확장 시 최적 |
| **Go로 작성** | timingle 백엔드와 같은 언어 → 디버깅 용이 |

### TiDB를 선택하지 않는 이유

```
timingle은 PostgreSQL → TiDB 전환 시:

1. 드라이버 교체 (lib/pq → go-sql-driver/mysql)
2. SQL 문법 변경:
   - ON CONFLICT DO NOTHING → INSERT IGNORE
   - ON CONFLICT DO UPDATE → ON DUPLICATE KEY UPDATE
   - TIMESTAMPTZ → TIMESTAMP
   - INET → VARCHAR
   - BIGSERIAL → BIGINT AUTO_INCREMENT
3. JSONB 함수 → JSON 함수 (jsonb_set → JSON_SET 등)
4. 테스트 전체 재검증

vs CockroachDB 전환 시:

1. 드라이버 동일 (lib/pq 그대로)
2. SQL 문법 95% 동일
3. 트리거 제거 + 앱 코드에서 updated_at 처리
4. BIGSERIAL → UUID 권장 (선택)
```

### 마이그레이션 시나리오

```
현재 (MVP ~ 100만):
  PostgreSQL 유지

100만 → 1억 전환 시:
  Step 1: CockroachDB 클러스터 구축 (3노드)
  Step 2: MOLT (Migration Tool) 사용하여 데이터 이전
  Step 3: 트리거 제거, UUID 전환 (선택)
  Step 4: 앱의 DSN만 변경 (접속 주소 변경)
  Step 5: 듀얼 라이트 → 검증 → 전환 완료

MOLT (Migrate Off Legacy Technology):
  CockroachDB가 제공하는 공식 마이그레이션 도구
  PostgreSQL → CockroachDB 자동 스키마 변환 + 데이터 이전
```

---

## 결론: 수동 샤딩 vs 분산 SQL

| 기준 | 수동 샤딩 | 분산 SQL |
|------|---------|---------|
| **개발 복잡도** | 극도로 높음 | 낮음 (SQL 그대로) |
| **라우팅 로직** | 앱에서 직접 구현 | DB가 자동 처리 |
| **크로스 샤드 JOIN** | 불가 → 앱에서 merge | DB가 자동 처리 |
| **리밸런싱** | 수동 (다운타임 가능) | 자동 (온라인) |
| **노드 추가** | 복잡한 작업 | 노드 추가만 하면 됨 |
| **운영 비용** | 인력 집약적 | 인프라 비용 |
| **비용** | 서버 비용 낮음 | 라이선스/서버 비용 높음 |

```
결론:
  - 10만명까지: PostgreSQL + Read Replica로 충분
  - 100만명까지: PostgreSQL + PgBouncer + 읽기 분산으로 버팀
  - 1억명: 수동 샤딩의 운영 지옥 vs CockroachDB 자동화
         → 대부분의 회사가 분산 SQL을 선택

  timingle 추천 경로:
  PostgreSQL → Read Replica → CockroachDB (1억 돌파 시)
```

---

## 관련 문서

- [확장성 전략](scalability.md) - 전체 확장 로드맵
- [DB 스키마](database.md) - 현재 PostgreSQL 스키마
- [메시지 큐 비교](message-queue.md) - NATS vs Kafka vs Pulsar

---

**작성일:** 2026-02-19
