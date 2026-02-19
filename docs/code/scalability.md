# 확장성 분석 - timingle 스케일링 전략

> 50명 → 1만 → 10만 → 100만 → 1억 단계별 확장 가이드

---

## 개요

timingle 백엔드의 **단계별 확장 전략**을 정리합니다.

**핵심 원칙:**
- 지금은 MVP 완성에 집중
- 사용자 증가에 따라 단계적으로 진화
- 프레임워크 교체가 아닌 아키텍처 변경이 핵심
- 과도한 사전 설계는 MVP를 늦출 뿐

---

## 현재 아키텍처 (50명 MVP)

```
┌───────────────────────────────────────────────┐
│               Flutter App                      │
└──────────┬───────────────────┬────────────────┘
           │ REST API          │ WebSocket
           ▼                   ▼
┌──────────────────────────────────────────────┐
│          단일 Go 서버 (Gin)                    │
│                                               │
│  Auth + Event + Chat + Calendar + Invite      │
│  (하나의 바이너리, 하나의 프로세스)               │
└──────┬──────────┬──────────┬─────────────────┘
       │          │          │
       ▼          ▼          ▼
  PostgreSQL   ScyllaDB    Redis
   (1대)        (1대)      (1대)
```

| 구성요소 | 현재 상태 | 비고 |
|---------|----------|------|
| 서버 | 단일 Go 바이너리 | Gin 프레임워크 |
| DB | PostgreSQL 1대 | 관계형 데이터 |
| 채팅 DB | ScyllaDB 1대 | 시계열 데이터 |
| 캐시 | Redis 1대 | 세션, 캐시 |
| 메시지 큐 | NATS JetStream | 채팅 영속화 |
| WebSocket | Hub (서버 메모리) | Room 기반 |

**이 구조로 충분한 규모:** ~1,000명

---

## 프레임워크 선택 근거

| 목적 | 추천 프레임워크 | 비고 |
|------|--------------|------|
| 빠른 REST API | **Gin** / Echo | timingle 선택 |
| Node.js 스타일 | Fiber | net/http 비호환 |
| 풀스택 | Beego | 과도한 기능 |
| 대규모 마이크로서비스 | Go kit | 현재 불필요 |
| 최소 의존성 | net/http | 보일러플레이트 많음 |

### timingle에 Gin이 최적인 이유

| 기준 | timingle 요구사항 | Gin 적합도 |
|------|------------------|-----------|
| REST API | 25+ 엔드포인트, CRUD 중심 | Gin의 핵심 강점 |
| WebSocket | gorilla/websocket 직접 사용 | 프레임워크 무관 |
| Middleware | JWT, CORS, Logger | Gin 미들웨어 체인 |
| 성능 | MVP 50명 → 스케일업 | 충분 |
| 생태계 | OAuth, NATS 연동 | 풍부한 예제 |
| 학습 곡선 | MVP 4주 목표 | 가장 낮음 |

### 프레임워크는 병목이 아니다

1억 규모 서비스들의 Go 프레임워크:

| 서비스 | 사용자 수 | 프레임워크 |
|--------|----------|-----------|
| Uber | 1.3억+ | Go net/http |
| Twitch | 1.4억+ | Go 자체 |
| Discord | 2억+ | Rust + Go net/http |
| Bilibili | 수억+ | Go Gin |

**결론:** 프레임워크 교체 없이 아키텍처 변경으로 확장

---

## 단계별 확장 로드맵

### Phase 1: 1만명 - DB 최적화

```
변경 사항:
┌──────────────────┐
│  Go 서버 (Gin)   │
└──────┬───────────┘
       │
       ▼
┌──────────────┐      ← 추가
│  PgBouncer   │
│  (커넥션 풀)  │
└──────┬───────┘
       │
       ▼
  PostgreSQL
  + 인덱스 최적화
  + 슬로우 쿼리 모니터링
```

| 작업 | 내용 | 이유 |
|------|------|------|
| **PgBouncer 도입** | DB 커넥션 풀링 | Go 서버 커넥션 고갈 방지 |
| **인덱스 최적화** | 느린 쿼리 분석 + 인덱스 추가 | 응답 시간 개선 |
| **Redis 캐시 적극 활용** | 자주 조회되는 데이터 캐싱 | DB 부하 감소 |
| **모니터링 도입** | Prometheus + Grafana | 병목 지점 가시화 |

**예상 병목:** DB 커넥션 수 부족, 반복적인 동일 쿼리

---

### Phase 2: 10만명 - 수평 확장

```
                    ┌──────────────────┐
                    │  Load Balancer   │
                    │  (Nginx/HAProxy) │
                    └────────┬─────────┘
                             │
                ┌────────────┼────────────┐
                ▼            ▼            ▼
          ┌──────────┐ ┌──────────┐ ┌──────────┐
          │ Server 1 │ │ Server 2 │ │ Server 3 │
          │ (Gin)    │ │ (Gin)    │ │ (Gin)    │
          └────┬─────┘ └────┬─────┘ └────┬─────┘
               │            │            │
               └────────────┼────────────┘
                            │
                   ┌────────┴────────┐
                   ▼                 ▼
             ┌──────────┐     ┌──────────────┐
             │ PgBouncer│     │ Redis Pub/Sub│  ← WebSocket 분산
             └────┬─────┘     └──────────────┘
                  │
          ┌───────┼───────┐
          ▼               ▼
    ┌──────────┐   ┌──────────────┐
    │ PG       │   │ PG Read      │  ← Read Replica 추가
    │ Primary  │   │ Replica      │
    └──────────┘   └──────────────┘
```

| 작업 | 내용 | 이유 |
|------|------|------|
| **서버 다중화** | 동일 서버 2~3대 | CPU/메모리 분산 |
| **Load Balancer** | Nginx 또는 HAProxy | 트래픽 분배 |
| **WebSocket 분산** | Redis Pub/Sub | 서버 간 메시지 브릿지 |
| **DB Read Replica** | PostgreSQL 읽기 전용 복제 | 읽기 부하 분산 |
| **세션 공유** | Redis 기반 세션 | 서버 간 상태 공유 |

**WebSocket 분산이 가장 큰 과제:**

```
문제:
  Server A의 유저와 Server B의 유저가 같은 채팅방
  → Server A의 Hub에만 메시지 전달됨

해결 (Redis Pub/Sub):
  Server A: 메시지 수신 → Redis Publish("chat:event:10", msg)
  Server B: Redis Subscribe("chat:event:10") → 자기 Hub에 Broadcast
```

---

### Phase 3: 100만명 - 서비스 분리 시작

```
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│ Auth     │ │ Event    │ │ Chat     │ │ Calendar │
│ Service  │ │ Service  │ │ Service  │ │ Service  │
│ (Gin)    │ │ (Gin)    │ │ (Gin)    │ │ (Gin)    │
└────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │            │
     └────────────┴────────────┴────────────┘
                         │
               ┌─────────┴──────────┐
               │    API Gateway     │
               │  (Kong / Envoy)    │
               └────────────────────┘
                         │
               ┌─────────┴──────────┐
               │   Load Balancer    │
               └────────────────────┘
```

| 작업 | 내용 | 이유 |
|------|------|------|
| **API Gateway** | Kong 또는 Envoy | 라우팅, Rate Limiting, 인증 통합 |
| **서비스 분리** | 도메인별 독립 배포 | 독립 확장, 장애 격리 |
| **Kubernetes** | 컨테이너 오케스트레이션 | Auto Scaling, 롤링 배포 |
| **ScyllaDB 클러스터** | 3+ 노드 | 채팅 쓰기 부하 분산 |
| **CDN** | CloudFront 등 | 정적 자원, 이미지 |
| **Rate Limiting** | API 호출 제한 | 악용 방지 |

**서비스 분리 기준 (현재 코드 기준):**

| 서비스 | 현재 파일 | 독립 DB |
|--------|----------|---------|
| Auth Service | auth_handler + auth_service + auth_repo | PostgreSQL (users, tokens) |
| Event Service | event_handler + event_service + event_repo | PostgreSQL (events, participants) |
| Chat Service | websocket_handler + chat_service + chat_repo | ScyllaDB + NATS |
| Calendar Service | calendar_handler + calendar_service | Google API (외부) |
| Invite Service | invite_handler + invite_service + invite_repo | PostgreSQL (invite_links) |

현재 Clean Architecture (Handler → Service → Repository) 덕분에 분리가 비교적 수월합니다.

---

### Phase 4: 1억명 - 완전 분산 시스템

```
          한국 (Primary)           일본            미국 서부
     ┌─────────────────┐    ┌──────────┐    ┌──────────┐
     │ K8s Cluster     │    │ K8s      │    │ K8s      │
     │ DB Primary      │    │ DB Replica│    │ DB Replica│
     │ Redis Primary   │    │ Redis    │    │ Redis    │
     └─────────────────┘    └──────────┘    └──────────┘
              │                   │               │
              └───── Global Load Balancer ────────┘
                     (Cloudflare / AWS)
```

#### DB 샤딩

```
1억 사용자 × 평균 10개 이벤트 = 10억 rows (events)
1억 사용자 × 하루 50개 메시지 = 50억 messages/day

PostgreSQL 단일 인스턴스로는 불가능

해결: user_id 기반 샤딩
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│  Shard 0     │ │  Shard 1     │ │  Shard 2     │
│  user 1~33M  │ │  user 34~66M │ │  user 67~100M│
│  PostgreSQL  │ │  PostgreSQL  │ │  PostgreSQL  │
└──────────────┘ └──────────────┘ └──────────────┘

또는 PostgreSQL → CockroachDB / TiDB (분산 SQL)로 교체
```

#### 채팅 시스템 재설계

```
현재:
  Client → WebSocket → Hub (메모리) → Broadcast

1억:
  Client → WebSocket Gateway (수백 대)
              │
              ▼
         Kafka / Pulsar (메시지 버스)
              │
       ┌──────┼──────┐
       ▼      ▼      ▼
    Chat    Chat    Chat
    Worker  Worker  Worker
       │      │      │
       └──────┼──────┘
              ▼
         ScyllaDB 클러스터 (9+ 노드)
```

| 변경 | 현재 | 1억 규모 | 이유 |
|------|------|---------|------|
| 메시지 버스 | NATS JetStream | Kafka / Pulsar | 하루 50억 메시지, 파티션 기반 확장 |
| WebSocket | 서버 내장 Hub | 전용 Gateway 서비스 | 연결 관리 전담 |
| 저장 | ScyllaDB 1대 | ScyllaDB 클러스터 9+ | 쓰기 부하 분산 |
| 파티션 키 | `(event_id)` | `(event_id, bucket)` | 핫 파티션 방지 |

#### ScyllaDB 핫 파티션 방지

```sql
-- 현재: 인기 이벤트에 메시지 집중 → 단일 파티션 과부하
PRIMARY KEY (event_id, created_at, message_id)

-- 1억: 일(day) 단위 버킷으로 분산
PRIMARY KEY ((event_id, bucket), created_at, message_id)
-- bucket = created_at을 일 단위로 나눈 값
-- 예: 2026-02-19 → bucket = 20260219
```

#### 추가 인프라

| 시스템 | 용도 | 기술 |
|--------|------|------|
| API Gateway | 라우팅, Rate Limit, 인증 | Kong / Envoy |
| Service Mesh | 서비스 간 통신 관리 | Istio / Linkerd |
| 분산 추적 | 요청 흐름 추적 | Jaeger / Zipkin |
| 중앙 로깅 | 수천 대 서버 로그 수집 | ELK / Loki |
| 메트릭 | 실시간 모니터링 | Prometheus + Grafana |
| Feature Flag | 점진적 배포 | LaunchDarkly |
| CDN | 정적 자원 | CloudFront |
| 푸시 알림 | 대규모 알림 발송 | FCM + 자체 큐 |

---

## 병목 발생 순서 예측

```
사용자 증가에 따라 가장 먼저 터지는 곳:

50명 → 1만명:
  1. DB 커넥션 고갈 ← PgBouncer
  2. 반복 쿼리 부하 ← Redis 캐시

1만명 → 10만명:
  3. 단일 서버 CPU/메모리 ← 수평 확장 (다중 서버)
  4. WebSocket 서버 간 동기화 ← Redis Pub/Sub
  5. DB 읽기 부하 ← Read Replica

10만명 → 100만명:
  6. 모놀리식 배포 한계 ← 마이크로서비스 분리
  7. 채팅 쓰기 폭주 ← ScyllaDB 클러스터
  8. API 악용 ← Rate Limiting

100만명 → 1억명:
  9. 단일 리전 한계 ← 멀티 리전
  10. PostgreSQL 단일 한계 ← 샤딩 또는 분산 DB
  11. NATS 처리량 한계 ← Kafka/Pulsar
  12. WebSocket 연결 수 한계 ← 전용 Gateway
```

---

## 현재 코드의 확장 준비도

### 잘 되어 있는 것

| 항목 | 현재 상태 | 확장 시 이점 |
|------|----------|------------|
| **Clean Architecture** | Handler → Service → Repository | 서비스 분리 시 레이어별 독립 가능 |
| **DI 패턴** | main.go에서 모든 의존성 주입 | 구현체 교체 용이 |
| **도메인 분리** | 기능별 파일 분리 | 마이크로서비스 추출 단위 명확 |
| **ScyllaDB 채팅** | 시계열 DB 사용 | 대규모 채팅에 적합한 선택 |
| **NATS 메시지 큐** | 비동기 메시지 처리 | Kafka로 교체 시 패턴 유지 |
| **JWT Stateless** | 서버에 세션 없음 | 수평 확장에 유리 |

### 확장 시 변경 필요한 것

| 항목 | 현재 | 변경 필요 시점 | 변경 내용 |
|------|------|-------------|---------|
| **Hub 메모리 저장** | `map[int64]map[*Client]bool` | 10만명 (다중 서버) | Redis Pub/Sub 기반 분산 Hub |
| **DB 직접 연결** | `sql.DB` 직접 사용 | 1만명 | PgBouncer 경유 |
| **단일 서버 배포** | 1대 프로세스 | 10만명 | K8s + Load Balancer |
| **모놀리식** | 전체 기능 1 바이너리 | 100만명 | 마이크로서비스 분리 |
| **ScyllaDB 파티션** | `event_id` 단일 키 | 1억명 | `(event_id, bucket)` 복합 키 |

---

## 비용 예측 (AWS 기준 월 추정)

| 규모 | 서버 | DB | 기타 | 월 비용 |
|------|------|-----|------|--------|
| 50명 (MVP) | t3.small 1대 | RDS db.t3.micro | Redis t3.micro | ~$50 |
| 1만명 | t3.medium 1대 | RDS db.t3.medium + PgBouncer | Redis t3.small | ~$200 |
| 10만명 | c5.large 3대 + LB | RDS db.r5.large (Primary + Replica) | Redis r5.large | ~$1,500 |
| 100만명 | K8s 10+ 노드 | RDS Multi-AZ + ScyllaDB 3노드 | Redis Cluster | ~$10,000 |
| 1억명 | K8s 멀티리전 100+ 노드 | 분산 DB 클러스터 | 풀 인프라 | ~$100,000+ |

---

## 요약: 지금 해야 할 것 vs 나중에 할 것

```
✅ 지금 (MVP, 50명):
   현재 구조 유지, 기능 완성에 집중

⏳ 1만명 도달 시:
   PgBouncer, Redis 캐시, 모니터링

⏳ 10만명 도달 시:
   서버 수평 확장, WebSocket Redis Pub/Sub, DB Read Replica

⏳ 100만명 도달 시:
   마이크로서비스 분리, K8s, API Gateway

⏳ 1억명 도달 시:
   멀티 리전, DB 샤딩, Kafka, 전용 WebSocket Gateway

❌ 지금 하면 안 되는 것:
   1억을 설계하면 MVP가 영원히 안 나옴
```

---

## 관련 문서

- [채팅 시스템](chat.md) - WebSocket Hub, NATS (확장 대상)
- [DB 스키마](database.md) - PostgreSQL + ScyllaDB (샤딩 대상)
- [전체 인덱스](README.md)

---

**작성일:** 2026-02-19
