# 메시지 큐 심층 분석 - NATS vs Kafka vs Pulsar

> NATS가 실시간에 더 좋은데 왜 1억에서 Kafka/Pulsar로 바꿔야 하는가?

---

## 핵심 요약: 세 줄 정리

```
NATS  = 우체부   → 빠르게 전달, 편지 보관은 선택 (JetStream)
Kafka = 도서관   → 모든 메시지를 영구 보관, 누구든 와서 다시 읽을 수 있음
Pulsar = 우체국  → 빠른 전달 + 보관 + 분류 다 됨, 대신 시스템이 복잡
```

---

## 각각 무엇인가?

### NATS - 경량 실시간 메시지 시스템

```
"가벼운 우체부" - 메시지를 받으면 즉시 전달

NATS Core (기본):
  Publisher → NATS → Subscriber
  - 수신자가 없으면? 메시지 유실 (at-most-once)
  - 수신자가 연결 중이어야 받을 수 있음
  - 극도로 빠름 (마이크로초 단위 지연)

NATS JetStream (확장):
  Publisher → NATS + JetStream(디스크 저장) → Subscriber
  - 메시지를 디스크에 저장
  - 수신자가 나중에 연결해도 밀린 메시지 수신 가능
  - at-least-once, exactly-once(제한적) 보장
```

**timingle이 NATS JetStream을 쓰는 이유:**

```go
// chat_service.go - 현재 timingle 코드
func (s *ChatService) SendMessage(...) {
    // 1. ScyllaDB에 저장 (영속)
    s.chatRepo.SaveMessage(msg)

    // 2. NATS JetStream으로 발행 (실시간 전달)
    s.js.Publish("chat.event."+eventID, msgBytes)

    // 3. WebSocket Hub에 브로드캐스트 (즉시 전달)
    s.hub.BroadcastToRoom(eventID, msg)
}
```

현재 구조에서 NATS는 **메시지 영속화 + 오프라인 유저 재전달**용으로 사용 중입니다.

### Kafka - 분산 이벤트 스트리밍 플랫폼

```
"거대한 도서관" - 모든 메시지를 순서대로 보관, 누구든 와서 읽을 수 있음

Producer → Kafka Topic (파티션 기반) → Consumer Group
           ┌─────────────────────┐
           │ Topic: chat.events  │
           │ ┌─────────────────┐ │
           │ │ Partition 0     │ │  ← event_id % 10 = 0인 이벤트
           │ │ msg1, msg2, ... │ │
           │ ├─────────────────┤ │
           │ │ Partition 1     │ │  ← event_id % 10 = 1인 이벤트
           │ │ msg3, msg4, ... │ │
           │ ├─────────────────┤ │
           │ │ ...             │ │
           │ ├─────────────────┤ │
           │ │ Partition 9     │ │  ← event_id % 10 = 9인 이벤트
           │ │ msg5, msg6, ... │ │
           │ └─────────────────┘ │
           └─────────────────────┘
```

**핵심 개념:**

| 개념 | 설명 |
|------|------|
| **Topic** | 메시지 카테고리 (예: `chat.messages`, `event.history`) |
| **Partition** | Topic을 N개로 분할. 각 파티션 = 순서 보장된 로그 파일 |
| **Offset** | 파티션 내 메시지 위치 번호 (0, 1, 2, 3...) |
| **Consumer Group** | 같은 그룹의 Consumer는 파티션을 나눠 소비 |
| **Retention** | 메시지 보관 기간 (기본 7일, 영구 설정 가능) |

```
Kafka가 "도서관"인 이유:

1. 한 번 저장된 메시지는 삭제되지 않음 (보관 기간 동안)
2. Consumer A가 읽었다고 해서 메시지가 사라지지 않음
3. Consumer B가 나중에 와서 처음부터 다시 읽을 수 있음
4. 어제 메시지를 다시 읽을 수 있음 (offset 조정)

vs NATS JetStream:
  JetStream도 저장하지만, 핵심은 "전달"
  Kafka는 핵심이 "저장 + 재생"
```

### Pulsar - 차세대 통합 메시징 플랫폼

```
"현대식 우체국" - 전달 + 보관 + 구독 + 큐잉 다 됨

Producer → Pulsar Broker (Stateless) → Consumer
                │
                ▼
           BookKeeper (저장)
           ┌──────────────┐
           │ Bookie 1     │
           │ Bookie 2     │  ← 실제 데이터 저장
           │ Bookie 3     │
           └──────────────┘
```

**Pulsar의 핵심 차이:**

| 특징 | 설명 |
|------|------|
| **Broker-Storage 분리** | 브로커(처리)와 BookKeeper(저장)가 독립 |
| **Topic 수 제한 없음** | 100만 Topic도 가능 (Kafka는 수천 개가 한계) |
| **멀티 테넌시** | 하나의 클러스터에서 여러 팀/서비스 격리 |
| **Pub/Sub + Queue** | 둘 다 네이티브 지원 |
| **지리적 복제** | 리전 간 실시간 복제 내장 |
| **계층 저장** | 오래된 데이터 자동으로 S3/HDFS로 이동 |

---

## 왜 NATS가 실시간에 더 좋은가?

**맞습니다. NATS는 실시간 전달에서 Kafka/Pulsar보다 빠릅니다.**

### 지연 시간 (Latency) 비교

```
메시지 1개가 Producer → Consumer까지 걸리는 시간:

NATS Core:      ~0.1ms (100μs)   ⭐ 가장 빠름
NATS JetStream:  ~0.5ms
Pulsar:          ~5ms
Kafka:           ~5-10ms

왜 차이가 나는가?

NATS:
  Publisher → [메모리 라우팅] → Subscriber
  디스크 I/O 없이 메모리에서 바로 전달

Kafka:
  Producer → [디스크 쓰기] → [복제 확인] → Consumer Poll
  반드시 디스크에 기록 후 전달
  Consumer가 "가져가기(Pull)" 방식

Pulsar:
  Producer → [Broker] → [BookKeeper 쓰기] → Consumer Push
  Broker→BookKeeper 네트워크 홉 추가
```

### 그러면 왜 1억에서 NATS를 버리는가?

**버리는 것이 아닙니다. 용도를 나누는 것입니다.**

```
현재 timingle (NATS JetStream 1대):
  채팅 메시지 전달 + 영속화 + 히스토리 → NATS JetStream이 전부 담당

1억 timingle:
  ┌─────────────────────────────────────────────────┐
  │ 실시간 전달: NATS (유지!)                          │
  │   Client → WebSocket → NATS Publish              │
  │   → 같은 서버 Hub에 즉시 전달                       │
  │   (지연: ~0.1ms)                                  │
  │                                                   │
  │ 영속화 + 분석 + 재생: Kafka                         │
  │   NATS → Kafka (브릿지)                            │
  │   → 채팅 기록 영구 저장                              │
  │   → 분석 시스템에서 소비                             │
  │   → 검색 인덱싱 (Elasticsearch)                     │
  │   → 알림 시스템에서 소비                             │
  │   (처리량: 수백만 TPS)                              │
  └─────────────────────────────────────────────────┘
```

**핵심:** NATS와 Kafka는 경쟁이 아니라 **보완** 관계입니다.

---

## 왜 Kafka가 "고성능"이라고 하는가?

### "고성능"의 정의가 다릅니다

```
NATS의 "성능" = 지연 시간 (Latency)
  → 메시지 1개를 얼마나 빨리 전달하는가
  → NATS 승리: 0.1ms

Kafka의 "성능" = 처리량 (Throughput)
  → 1초에 메시지를 얼마나 많이 처리하는가
  → Kafka 승리: 수백만 msg/sec
```

### 처리량 비교

| 시스템 | 초당 메시지 (단일 노드) | 초당 메시지 (클러스터) | 확장 방식 |
|--------|----------------------|---------------------|---------|
| **NATS JetStream** | ~100K | ~500K | 서버 추가 (제한적) |
| **Kafka** | ~300K | **~수백만** | 파티션 추가 (선형) |
| **Pulsar** | ~200K | **~수백만** | BookKeeper 추가 (선형) |

### 왜 Kafka가 처리량에서 압도적인가?

```
비밀 1: Sequential I/O (순차 쓰기)

  일반 DB:    랜덤 쓰기 → 디스크 헤드가 여기저기 → 느림
  Kafka:     순차 쓰기 → 로그 파일 끝에 계속 추가 → SSD 최대 성능

  SSD 랜덤 쓰기:   ~10,000 IOPS
  SSD 순차 쓰기:  ~500,000 IOPS  (50배 차이!)

비밀 2: Zero-Copy (제로 카피)

  일반 방식: 디스크 → 커널 버퍼 → 앱 메모리 → 소켓 버퍼 → 네트워크
  Kafka:    디스크 → 커널 버퍼 → 네트워크 (sendfile 시스템콜)
  → CPU 부하 대폭 감소, 복사 2회 제거

비밀 3: Batch 처리

  NATS:   메시지 1개 → 즉시 전달
  Kafka:  메시지 100개 모아서 → 한 번에 전달
  → 네트워크 왕복 횟수 99% 감소

비밀 4: 파티션 병렬화

  NATS:   1개 Subject → 1개 처리 스트림
  Kafka:  1개 Topic → 100개 파티션 → 100개 Consumer 동시 처리
  → 파티션 수 = 병렬도
```

### timingle 하루 50억 메시지 시나리오

```
하루 50억 메시지 = 초당 ~58,000 메시지 (평균)
피크 시간 (저녁 7~10시): 초당 ~200,000 메시지

NATS JetStream (현재):
  단일 서버: ~100,000 msg/sec → 피크 시간 처리 불가 ❌
  클러스터: ~500,000 msg/sec → 가능하지만 여유 없음 ⚠️
  문제: 영속화 + 전달 동시 부하 → 지연 시간 급증

Kafka:
  3 브로커, 100 파티션: ~2,000,000 msg/sec → 여유롭게 처리 ✅
  Consumer Group으로 Chat Worker 100대가 병렬 소비
  7일간 자동 보관 → 재처리 가능
  모니터링, 검색, 분석 시스템도 같은 데이터 소비 가능
```

---

## 3자 상세 비교

### 아키텍처 비교

| 기준 | NATS | Kafka | Pulsar |
|------|------|-------|--------|
| **설계 철학** | 심플, 경량 | 로그 기반 스트리밍 | 통합 메시징 |
| **프로토콜** | 자체 (텍스트) | 자체 (바이너리) | 자체 (바이너리) |
| **저장** | 메모리 + 파일 (JetStream) | 디스크 (로그 파일) | BookKeeper (분리) |
| **메시지 소비** | Push (서버가 밀어줌) | Pull (클라이언트가 가져감) | Push + Pull |
| **순서 보장** | Subject 내 보장 | Partition 내 보장 | Topic 내 보장 |
| **개발 언어** | Go | Java/Scala | Java |
| **개발사** | Synadia (Go 창시자) | LinkedIn → Apache | Yahoo → Apache |

### 기능 비교

| 기능 | NATS JetStream | Kafka | Pulsar |
|------|---------------|-------|--------|
| **Pub/Sub** | ✅ | ✅ | ✅ |
| **Message Queue** | ✅ | ⚠️ Consumer Group | ✅ 네이티브 |
| **Request/Reply** | ✅ 네이티브 | ❌ 별도 구현 | ❌ 별도 구현 |
| **영속화** | ✅ (JetStream) | ✅ (기본) | ✅ (BookKeeper) |
| **메시지 재생** | ✅ (제한적) | ✅ (강력) | ✅ (강력) |
| **정확히 1회 전달** | ⚠️ 제한적 | ✅ | ✅ |
| **스키마 레지스트리** | ❌ | ✅ (Confluent) | ✅ 내장 |
| **멀티 테넌시** | ✅ Accounts | ❌ 없음 | ✅ 네이티브 |
| **지리적 복제** | ❌ 없음 | ⚠️ MirrorMaker | ✅ 네이티브 |
| **Topic 수 한계** | 수만 | 수천 (ZooKeeper) | 수백만 |
| **클라이언트** | 40+ 언어 | 다수 | 다수 |
| **Go 클라이언트** | ⚡ 공식 (최고 품질) | ✅ confluent-kafka-go | ✅ 공식 |

### 운영 비교

| 기준 | NATS | Kafka | Pulsar |
|------|------|-------|--------|
| **설치 난이도** | ⭐ 바이너리 1개 | ⭐⭐⭐ ZK + Broker | ⭐⭐⭐⭐ ZK + Broker + BK |
| **최소 노드** | 1 | 3 (권장) | 6 (ZK 3 + Broker 2 + BK 3) |
| **메모리 사용** | ~50MB | ~1GB+ | ~2GB+ |
| **디스크 사용** | 낮음 | 높음 (로그 보관) | 높음 (BookKeeper) |
| **모니터링** | 내장 HTTP | JMX + 외부 도구 | 내장 + Grafana |
| **관리형 서비스** | Synadia Cloud | Confluent Cloud, AWS MSK | StreamNative Cloud |
| **커뮤니티 크기** | 중간 | ⭐ 매우 큼 | 성장 중 |
| **학습 곡선** | 낮음 | 중간 | 높음 |

---

## timingle 실제 적용 시나리오

### 현재 (MVP ~ 10만명): NATS JetStream 유지

```
현재 구조가 최적인 이유:

1. 단순함: NATS 바이너리 1개로 전부 해결
2. Go 친화적: Go 창시자(Derek Collison)가 만든 Go 네이티브 시스템
3. 지연 시간: 채팅 실시간 전달에 최적 (0.1ms)
4. 메모리: ~50MB로 가볍게 운영
5. JetStream: 메시지 영속화 + 오프라인 재전달 충분

이 규모에서 Kafka는 오버엔지니어링:
  - 최소 ZooKeeper 3대 + Broker 3대 = 6대 서버
  - 운영 복잡도 10배 증가
  - 10만명 메시지 규모에서 NATS가 충분히 처리
```

### 10만명 → 100만명: NATS 클러스터 + 모니터링

```
NATS를 아직 교체하지 않음!

변경:
  NATS 서버 1대 → NATS 클러스터 3대 (SuperCluster)
  모니터링 추가: nats-surveyor + Grafana

NATS SuperCluster:
  ┌──────────┐  ┌──────────┐  ┌──────────┐
  │ NATS 1   │──│ NATS 2   │──│ NATS 3   │
  │ Seoul    │  │ Seoul    │  │ Seoul    │
  └──────────┘  └──────────┘  └──────────┘
       │              │              │
       └──────── Gateway ──────────┘

  - 자동 페일오버
  - 메시지 미러링
  - JetStream 복제 (R=3)
```

### 100만명 → 1억명: NATS + Kafka 하이브리드

```
여기서 비로소 Kafka 도입!

┌─────────────────────────────────────────────────────────────┐
│                    메시지 흐름 (하이브리드)                      │
│                                                              │
│  실시간 경로 (NATS):                                          │
│    Client → WebSocket → NATS Publish → Hub Broadcast         │
│    지연: ~1ms                                                │
│    용도: 채팅 즉시 전달                                        │
│                                                              │
│  영속화 경로 (Kafka):                                         │
│    NATS → NATS-Kafka Bridge → Kafka Topic                    │
│    지연: ~10ms (영속화이므로 무관)                               │
│    용도: ↓                                                   │
│                                                              │
│    ┌──────────────────────────────────────────────┐          │
│    │ Kafka Consumer Groups                        │          │
│    │                                              │          │
│    │ 1. Chat History Worker                       │          │
│    │    → ScyllaDB 저장 (채팅 기록)                  │          │
│    │                                              │          │
│    │ 2. Search Indexer                            │          │
│    │    → Elasticsearch 인덱싱 (채팅 검색)           │          │
│    │                                              │          │
│    │ 3. Analytics Pipeline                        │          │
│    │    → ClickHouse (통계 분석)                    │          │
│    │                                              │          │
│    │ 4. Notification Service                      │          │
│    │    → 푸시 알림 발송                             │          │
│    │                                              │          │
│    │ 5. Audit Logger                              │          │
│    │    → 감사 로그 기록                             │          │
│    └──────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

**왜 하이브리드인가?**

| 역할 | NATS | Kafka |
|------|------|-------|
| 실시간 전달 | ✅ 0.1ms | ❌ 5~10ms |
| 대량 영속화 | ❌ 부하 큼 | ✅ Sequential I/O |
| 메시지 재생 | ⚠️ 제한적 | ✅ 7일간 전체 재생 |
| 다중 소비자 | ⚠️ 비효율 | ✅ Consumer Group |
| 운영 복잡도 | ⭐ 낮음 | ⭐⭐⭐ 높음 |

**한 문장 요약:** 실시간 전달은 NATS가, 데이터 파이프라인은 Kafka가 담당합니다.

---

## Pulsar는 언제 선택하는가?

### Pulsar가 Kafka보다 나은 경우

| 시나리오 | Pulsar 장점 |
|---------|-----------|
| **Topic 수가 매우 많을 때** | Kafka: ~수천 topic 한계, Pulsar: 수백만 |
| **멀티 테넌시** | 팀/서비스별 격리가 중요할 때 |
| **지리적 복제** | 한국↔일본↔미국 실시간 복제 필요 시 |
| **계층 저장** | 오래된 데이터 자동으로 S3 이동 |
| **Pub/Sub + Queue 둘 다** | 네이티브 지원 |

### timingle에서 Pulsar보다 Kafka를 추천하는 이유

```
1. 커뮤니티와 생태계:
   Kafka: 10년+ 역사, 수만 개 회사 사용, 풍부한 도구
   Pulsar: 5년+ 역사, 성장 중이지만 생태계 작음

2. 운영 복잡도:
   Kafka: ZooKeeper + Broker (KRaft 모드면 ZK 불필요)
   Pulsar: ZooKeeper + Broker + BookKeeper → 컴포넌트 3종

3. Go 클라이언트:
   Kafka: confluent-kafka-go (매우 안정적)
   Pulsar: apache/pulsar-client-go (비교적 젊음)

4. 관리형 서비스:
   Kafka: AWS MSK, Confluent Cloud → 원클릭 배포
   Pulsar: StreamNative → 선택지 적음

5. 채용:
   "Kafka 경험" → 대부분의 백엔드 개발자가 보유
   "Pulsar 경험" → 상대적으로 희소
```

---

## Go 코드로 보는 차이

### NATS (현재 timingle)

```go
// 연결
nc, _ := nats.Connect("nats://localhost:4222")
js, _ := nc.JetStream()

// 발행
js.Publish("chat.event.123", []byte(messageJSON))

// 구독 (Push 방식 - 메시지가 자동으로 옴)
js.Subscribe("chat.event.123", func(msg *nats.Msg) {
    // 메시지 처리
    processMessage(msg.Data)
    msg.Ack()
})
```

### Kafka

```go
// 발행
producer, _ := kafka.NewProducer(&kafka.ConfigMap{
    "bootstrap.servers": "kafka1:9092,kafka2:9092,kafka3:9092",
})
producer.Produce(&kafka.Message{
    TopicPartition: kafka.TopicPartition{
        Topic: &topic,
        Partition: kafka.PartitionAny,
    },
    Key:   []byte("event-123"),    // 같은 event는 같은 파티션
    Value: []byte(messageJSON),
}, nil)

// 구독 (Pull 방식 - 메시지를 직접 가져감)
consumer, _ := kafka.NewConsumer(&kafka.ConfigMap{
    "bootstrap.servers": "kafka1:9092",
    "group.id":          "chat-history-worker",
    "auto.offset.reset": "earliest",
})
consumer.Subscribe("chat.messages", nil)
for {
    msg, _ := consumer.ReadMessage(time.Second)  // Pull!
    processMessage(msg.Value)
}
```

### 핵심 차이

```
NATS:  Subscribe() → 콜백 함수 등록 → 메시지가 "밀려옴" (Push)
Kafka: ReadMessage() → 메시지를 "가져감" (Pull)

Push의 장점: 즉시 반응 → 실시간에 유리
Pull의 장점: Consumer가 속도 조절 가능 → 대량 처리에 유리

채팅 실시간 전달: Push(NATS) ✅
채팅 기록 배치 저장: Pull(Kafka) ✅
```

---

## 비용 비교 (AWS 기준)

### 관리형 서비스 월 비용

| 규모 | NATS (자체 운영) | Kafka (AWS MSK) | Pulsar (StreamNative) |
|------|----------------|----------------|---------------------|
| **10만명** | ~$50 (1대) | ~$600 (3 브로커) | ~$800 (6+ 노드) |
| **100만명** | ~$200 (3대) | ~$2,000 | ~$3,000 |
| **1억명** | ~$500 (5대) | ~$15,000 | ~$20,000 |

**NATS는 압도적으로 저렴합니다.** 이것이 "가능한 한 오래 NATS를 유지하라"는 이유입니다.

---

## timingle 메시지 큐 로드맵 요약

```
50명 ~ 10만명:
  NATS JetStream (단일 서버)
  ✅ 현재 그대로 유지
  비용: ~$50/월

10만명 ~ 100만명:
  NATS JetStream 클러스터 (3대)
  ✅ NATS만으로 충분
  비용: ~$200/월

100만명 ~ 1억명:
  NATS (실시간) + Kafka (영속화)
  ⚠️ 하이브리드 전환
  비용: ~$15,000/월

1억명 이후:
  NATS (실시간) + Kafka (영속화) + Kafka Streams/Flink (실시간 분석)
  🔄 데이터 파이프라인 고도화
  비용: ~$30,000+/월
```

**원칙: NATS를 버리지 않고, Kafka를 추가한다.**

---

## 관련 문서

- [확장성 전략](scalability.md) - 전체 확장 로드맵
- [채팅 시스템](chat.md) - 현재 NATS + WebSocket 구조
- [분산 SQL](distributed-sql.md) - PostgreSQL → CockroachDB 전환
- [전체 인덱스](README.md)

---

**작성일:** 2026-02-19
