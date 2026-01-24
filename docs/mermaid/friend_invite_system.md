# 친구/초대 시스템 다이어그램

## 핵심 원칙

**시스템이 문자를 보내지 않음** - 사용자 폰에서 직접 공유

```
❌ Backend → SMS Provider → 상대방 (사용 안 함)
✅ 사용자 폰 → 네이티브 공유 (카카오톡, 문자 등) → 상대방
```

## 전체 흐름

```mermaid
flowchart TB
    subgraph 사용자A[👤 사용자 A]
        A1[이벤트 생성]
        A2[초대 링크 생성]
        A3[네이티브 공유]
    end

    subgraph Backend[🖥️ Backend]
        B1[이벤트 저장]
        B2[링크 생성]
        B3[앱 내 알림]
    end

    subgraph 공유[📤 공유 방식]
        S1[카카오톡]
        S2[문자 SMS]
        S3[라인]
    end

    subgraph 사용자B[👤 사용자 B]
        C1[링크 수신]
        C2[앱 열기/설치]
        C3[참가 확정]
    end

    A1 --> B1
    A2 --> B2
    B2 --> A3
    A3 --> S1 & S2 & S3
    S1 & S2 & S3 --> C1
    C1 --> C2
    C2 --> C3
    C3 --> B1
```

## 친구 초대 (앱 내 알림)

가입된 친구에게 앱 내 알림으로 초대합니다.

```mermaid
sequenceDiagram
    autonumber
    participant A as 👤 사용자 A
    participant B as 🖥️ Backend
    participant DB as 🗄️ Database
    participant Push as 📱 Push Service
    participant C as 👤 친구 B

    A->>B: POST /events<br/>{ invite_friend_ids: [5, 7] }
    B->>DB: 이벤트 저장
    DB->>B: event_id

    loop 각 친구
        B->>DB: INSERT event_participants (status: PENDING)
        B->>Push: 알림 발송
        Push->>C: "A님이 '점심 약속'에 초대했습니다"
    end

    B->>A: { event, invites: { sent: 2 } }

    Note over C: 알림 수신 → 앱 열기

    C->>B: POST /events/45/accept
    B->>DB: UPDATE event_participants SET status = 'ACCEPTED'
    B->>Push: A에게 알림
    Push->>A: "B님이 수락했습니다"
```

## 초대 링크 + 네이티브 공유 (핵심)

미가입자 포함 누구에게나 초대할 수 있는 방식입니다.

```mermaid
sequenceDiagram
    autonumber
    participant A as 👤 사용자 A
    participant App as 📱 Flutter 앱
    participant B as 🖥️ Backend
    participant DB as 🗄️ Database
    participant Share as 📤 네이티브 공유
    participant C as 👤 사용자 B

    A->>App: 초대 버튼 클릭
    App->>B: POST /events/45/invite-link
    B->>DB: INSERT event_invite_links
    B->>App: { code: "abc123", link: "timingle.app/invite/abc123" }

    App->>Share: Share.share(link)
    Note over Share: 공유 시트 표시<br/>(카카오톡, 문자, 라인 등)
    A->>Share: 카카오톡 선택
    Share->>C: 메시지 전송 (A의 폰에서)

    Note over C: 링크 클릭

    C->>B: GET /invite/abc123

    alt 앱 설치 + 로그인됨
        B->>C: { event: {...} }
        C->>B: POST /invite/abc123/join
        B->>DB: INSERT event_participants
        B->>C: 참가 완료
    else 앱 미설치 또는 미로그인
        B->>C: 앱스토어 또는 로그인 화면으로 안내
        C->>C: 앱 설치 / 로그인
        C->>B: POST /invite/abc123/join
    end
```

## ERD

```mermaid
erDiagram
    users ||--o{ friendships : "has"
    users ||--o{ events : "creates"
    users ||--o{ event_participants : "participates"
    events ||--o{ event_participants : "has"
    events ||--o{ event_invite_links : "has"

    users {
        bigint id PK
        varchar phone UK
        varchar name
        varchar email
    }

    friendships {
        bigint id PK
        bigint user_id FK
        bigint friend_id FK
        varchar status
        timestamp created_at
    }

    events {
        bigint id PK
        bigint creator_id FK
        varchar title
        varchar status
    }

    event_participants {
        bigint event_id FK
        bigint user_id FK
        varchar status
        bigint invited_by FK
        varchar invite_method
    }

    event_invite_links {
        bigint id PK
        bigint event_id FK
        varchar code UK
        timestamp expires_at
        int max_uses
        int use_count
    }
```

## 관련 문서

- [친구/참가자 시스템 설계](../design/FRIEND_PARTICIPANT_SYSTEM.md) - 전체 설계 문서
