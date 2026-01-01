# timingle REST API 명세서

## 📋 목차

1. [기본 정보](#기본-정보)
2. [인증](#인증)
3. [사용자 관리](#사용자-관리)
4. [이벤트 관리](#이벤트-관리)
5. [오픈 예약](#오픈-예약)
6. [친구 관리](#친구-관리)
7. [채팅](#채팅)
8. [결제](#결제)
9. [에러 코드](#에러-코드)

---

## 기본 정보

### Base URL
```
Development: http://localhost:8080/api/v1
Production: https://api.timingle.com/api/v1
```

### HTTP 메서드
- `GET`: 리소스 조회
- `POST`: 리소스 생성
- `PUT`: 리소스 전체 수정
- `PATCH`: 리소스 부분 수정
- `DELETE`: 리소스 삭제

### 공통 헤더
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer {access_token}  # 인증 필요한 엔드포인트
```

### 응답 형식
#### 성공 응답
```json
{
  "success": true,
  "data": { /* 응답 데이터 */ },
  "message": "Success"
}
```

#### 에러 응답
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": { /* 추가 정보 */ }
  }
}
```

### 페이지네이션
```http
GET /api/v1/resource?page=1&limit=20&sort=created_at&order=desc
```

응답:
```json
{
  "success": true,
  "data": {
    "items": [ /* 리스트 */ ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 100,
      "items_per_page": 20
    }
  }
}
```

---

## 인증

### 1. 전화번호 인증 요청
```http
POST /auth/phone/send
```

**Request Body**:
```json
{
  "phone": "+821012345678"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "verification_id": "ver_123456",
    "expires_at": "2025-01-01T10:05:00Z"
  },
  "message": "Verification code sent"
}
```

### 2. 전화번호 인증 확인
```http
POST /auth/phone/verify
```

**Request Body**:
```json
{
  "verification_id": "ver_123456",
  "code": "123456"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900,  // 15분 (초)
    "user": {
      "id": 1,
      "phone": "+821012345678",
      "name": "홍길동",
      "role": "USER",
      "is_new_user": true
    }
  }
}
```

### 3. Google OAuth 로그인
```http
GET /auth/google
```

리다이렉트 → Google 로그인 페이지

### 4. Google OAuth 콜백
```http
GET /auth/google/callback?code={auth_code}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900,
    "user": {
      "id": 1,
      "email": "user@example.com",
      "name": "John Doe",
      "profile_image_url": "https://...",
      "role": "USER"
    }
  }
}
```

### 5. 토큰 갱신
```http
POST /auth/refresh
```

**Request Body**:
```json
{
  "refresh_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900
  }
}
```

### 6. 로그아웃
```http
POST /auth/logout
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Logged out successfully"
}
```

---

## 사용자 관리

### 1. 내 프로필 조회
```http
GET /users/me
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "phone": "+821012345678",
    "email": "user@example.com",
    "name": "홍길동",
    "display_name": "길동이",
    "profile_image_url": "https://...",
    "region": "서울특별시 강남구",
    "interests": ["운동", "독서", "음악"],
    "role": "USER",
    "is_active": true,
    "created_at": "2025-01-01T10:00:00Z",
    "updated_at": "2025-01-01T10:00:00Z"
  }
}
```

### 2. 프로필 수정
```http
PATCH /users/me
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "name": "홍길동",
  "display_name": "길동이",
  "region": "서울특별시 강남구",
  "interests": ["운동", "독서"]
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "홍길동",
    "display_name": "길동이",
    "region": "서울특별시 강남구",
    "interests": ["운동", "독서"],
    "updated_at": "2025-01-01T11:00:00Z"
  }
}
```

### 3. 사용자 검색 (친구 찾기)
```http
GET /users/search?q={query}
Authorization: Bearer {access_token}
```

**Query Parameters**:
- `q`: 검색어 (이름, 전화번호)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 2,
        "name": "김철수",
        "display_name": "철수",
        "profile_image_url": "https://...",
        "region": "서울특별시 강남구"
      }
    ]
  }
}
```

### 4. 사용자 상세 조회
```http
GET /users/{user_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 2,
    "name": "김철수",
    "display_name": "철수",
    "profile_image_url": "https://...",
    "region": "서울특별시 강남구",
    "role": "BUSINESS"
  }
}
```

---

## 이벤트 관리

### 1. 이벤트 목록 조회
```http
GET /events?status={status}&page=1&limit=20
Authorization: Bearer {access_token}
```

**Query Parameters**:
- `status`: `PROPOSED`, `CONFIRMED`, `CANCELED`, `DONE` (선택)
- `page`: 페이지 번호 (기본: 1)
- `limit`: 페이지당 개수 (기본: 20)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "events": [
      {
        "id": 1,
        "title": "9am -> 길동이",
        "description": "PT 수업",
        "start_time": "2025-01-05T09:00:00Z",
        "end_time": "2025-01-05T10:00:00Z",
        "location": "강남 피트니스",
        "status": "CONFIRMED",
        "creator": {
          "id": 1,
          "name": "홍길동",
          "profile_image_url": "https://..."
        },
        "participants": [
          {
            "id": 2,
            "name": "김철수",
            "profile_image_url": "https://...",
            "confirmed": true,
            "confirmed_at": "2025-01-01T12:00:00Z"
          }
        ],
        "unread_messages": 3,
        "created_at": "2025-01-01T10:00:00Z",
        "updated_at": "2025-01-01T12:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 5,
      "total_items": 100,
      "items_per_page": 20
    }
  }
}
```

### 2. 이벤트 상세 조회
```http
GET /events/{event_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "9am -> 길동이",
    "description": "PT 수업",
    "start_time": "2025-01-05T09:00:00Z",
    "end_time": "2025-01-05T10:00:00Z",
    "location": "강남 피트니스",
    "status": "CONFIRMED",
    "creator": {
      "id": 1,
      "name": "홍길동",
      "display_name": "길동이",
      "profile_image_url": "https://..."
    },
    "participants": [
      {
        "id": 2,
        "name": "김철수",
        "display_name": "철수",
        "profile_image_url": "https://...",
        "confirmed": true,
        "confirmed_at": "2025-01-01T12:00:00Z"
      }
    ],
    "created_at": "2025-01-01T10:00:00Z",
    "updated_at": "2025-01-01T12:00:00Z"
  }
}
```

### 3. 이벤트 생성
```http
POST /events
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "title": "9am -> 길동이",
  "description": "PT 수업",
  "start_time": "2025-01-05T09:00:00Z",
  "end_time": "2025-01-05T10:00:00Z",
  "location": "강남 피트니스",
  "participant_ids": [2, 3]
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "9am -> 길동이",
    "description": "PT 수업",
    "start_time": "2025-01-05T09:00:00Z",
    "end_time": "2025-01-05T10:00:00Z",
    "location": "강남 피트니스",
    "status": "PROPOSED",
    "creator_id": 1,
    "participants": [
      {
        "id": 2,
        "confirmed": false
      },
      {
        "id": 3,
        "confirmed": false
      }
    ],
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

### 4. 이벤트 수정
```http
PATCH /events/{event_id}
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "title": "10am -> 길동이",
  "start_time": "2025-01-05T10:00:00Z",
  "end_time": "2025-01-05T11:00:00Z"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "title": "10am -> 길동이",
    "start_time": "2025-01-05T10:00:00Z",
    "end_time": "2025-01-05T11:00:00Z",
    "updated_at": "2025-01-01T11:00:00Z"
  }
}
```

### 5. 이벤트 취소
```http
DELETE /events/{event_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Event canceled successfully"
}
```

### 6. 참여 확인
```http
POST /events/{event_id}/confirm
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "event_id": 1,
    "user_id": 2,
    "confirmed": true,
    "confirmed_at": "2025-01-01T12:00:00Z"
  }
}
```

### 7. 이벤트 히스토리 조회
```http
GET /events/{event_id}/history
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "history": [
      {
        "change_id": "uuid-1234",
        "event_id": 1,
        "actor": {
          "id": 1,
          "name": "홍길동"
        },
        "change_type": "CREATED",
        "old_value": null,
        "new_value": "{\"title\": \"9am -> 길동이\"}",
        "changed_at": "2025-01-01T10:00:00Z"
      },
      {
        "change_id": "uuid-5678",
        "event_id": 1,
        "actor": {
          "id": 2,
          "name": "김철수"
        },
        "change_type": "CONFIRMED",
        "old_value": null,
        "new_value": null,
        "changed_at": "2025-01-01T12:00:00Z"
      }
    ]
  }
}
```

---

## 오픈 예약

### 1. 오픈 예약 목록 조회
```http
GET /open-slots?region={region}&service_type={type}&page=1&limit=20
Authorization: Bearer {access_token}
```

**Query Parameters**:
- `region`: 지역 (예: "서울특별시 강남구")
- `service_type`: 서비스 유형 (예: "PT", "네일아트")
- `available_only`: `true` (기본값: true)
- `start_date`: 시작 날짜 (ISO 8601)
- `end_date`: 종료 날짜 (ISO 8601)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "slots": [
      {
        "id": 1,
        "business_user": {
          "id": 5,
          "name": "김트레이너",
          "profile_image_url": "https://..."
        },
        "service_type": "PT",
        "title": "오전 PT 수업",
        "description": "1:1 개인 PT",
        "start_time": "2025-01-05T09:00:00Z",
        "duration_minutes": 60,
        "price": 50000.00,
        "region": "서울특별시 강남구",
        "is_available": true,
        "created_at": "2025-01-01T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 3,
      "total_items": 50,
      "items_per_page": 20
    }
  }
}
```

### 2. 오픈 예약 생성 (비즈니스 사용자만)
```http
POST /open-slots
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "service_type": "PT",
  "title": "오전 PT 수업",
  "description": "1:1 개인 PT",
  "start_time": "2025-01-05T09:00:00Z",
  "duration_minutes": 60,
  "price": 50000.00,
  "region": "서울특별시 강남구"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "business_user_id": 5,
    "service_type": "PT",
    "title": "오전 PT 수업",
    "start_time": "2025-01-05T09:00:00Z",
    "duration_minutes": 60,
    "price": 50000.00,
    "region": "서울특별시 강남구",
    "is_available": true,
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

### 3. 오픈 예약으로 이벤트 생성
```http
POST /open-slots/{slot_id}/book
Authorization: Bearer {access_token}
```

**Request Body** (선택):
```json
{
  "message": "PT 받고 싶습니다!"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "event": {
      "id": 10,
      "title": "9am -> 김트레이너",
      "start_time": "2025-01-05T09:00:00Z",
      "end_time": "2025-01-05T10:00:00Z",
      "status": "PROPOSED",
      "creator_id": 3,
      "participants": [
        {
          "id": 5,
          "confirmed": false
        }
      ]
    },
    "slot": {
      "id": 1,
      "is_available": false
    }
  }
}
```

### 4. 오픈 예약 삭제
```http
DELETE /open-slots/{slot_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Open slot deleted successfully"
}
```

---

## 친구 관리

### 1. 친구 목록 조회
```http
GET /friends?page=1&limit=20
Authorization: Bearer {access_token}
```

**Query Parameters**:
- `page`: 페이지 번호 (기본: 1)
- `limit`: 페이지당 개수 (기본: 20)
- `search`: 검색어 (이름, 전화번호)

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "friends": [
      {
        "id": 2,
        "name": "김철수",
        "phone": "+821098765432",
        "profile_image_url": "https://...",
        "status": "ACCEPTED",
        "last_event_date": "2025-12-31T10:00:00Z",
        "event_count": 5,
        "created_at": "2025-01-01T10:00:00Z"
      }
    ],
    "pagination": {
      "current_page": 1,
      "total_pages": 1,
      "total_items": 5,
      "items_per_page": 20
    }
  }
}
```

### 2. 친구 요청 목록 조회
```http
GET /friends/requests
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "received": [
      {
        "id": 10,
        "name": "이요청",
        "phone": "+821011112222",
        "profile_image_url": "https://...",
        "status": "RECEIVED",
        "created_at": "2025-12-31T08:00:00Z"
      }
    ],
    "pending": [
      {
        "id": 11,
        "name": "박대기",
        "phone": "+821033334444",
        "profile_image_url": "https://...",
        "status": "PENDING",
        "created_at": "2025-12-31T06:00:00Z"
      }
    ]
  }
}
```

### 3. 친구 요청 보내기
```http
POST /friends/request
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "phone": "+821098765432"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": 15,
    "target_user": {
      "id": 5,
      "name": "박친구",
      "phone": "+821098765432"
    },
    "status": "PENDING",
    "created_at": "2026-01-01T10:00:00Z"
  },
  "message": "Friend request sent"
}
```

### 4. 친구 요청 수락
```http
POST /friends/requests/{request_id}/accept
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "friend": {
      "id": 10,
      "name": "이요청",
      "phone": "+821011112222",
      "status": "ACCEPTED"
    }
  },
  "message": "Friend request accepted"
}
```

### 5. 친구 요청 거절
```http
POST /friends/requests/{request_id}/reject
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Friend request rejected"
}
```

### 6. 친구 삭제
```http
DELETE /friends/{friend_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Friend removed successfully"
}
```

### 7. 친구 차단
```http
POST /friends/{friend_id}/block
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "User blocked successfully"
}
```

### 8. 친구 차단 해제
```http
DELETE /friends/{friend_id}/block
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "User unblocked successfully"
}
```

---

## 채팅

### 1. 채팅 메시지 목록 조회
```http
GET /api/v1/events/{event_id}/messages?limit=50
Authorization: Bearer {access_token}
```

**Query Parameters**:
- `limit`: 메시지 개수 (기본: 50)

**Response** (200 OK):
```json
[
  {
    "event_id": 1,
    "created_at": "2025-12-31T10:00:00Z",
    "message_id": "550e8400-e29b-41d4-a716-446655440000",
    "sender_id": 1,
    "sender_name": "홍길동",
    "sender_profile_url": "https://...",
    "message": "안녕하세요!",
    "message_type": "text",
    "attachments": [],
    "reply_to": null,
    "edited_at": null,
    "is_deleted": false,
    "metadata": {}
  }
]
```

**Note**: 실시간 메시지 전송은 WebSocket을 사용합니다. 이 API는 히스토리 조회용입니다.

---

## 결제

### 1. 결제 생성
```http
POST /payments
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "event_id": 1,
  "amount": 50000.00,
  "currency": "KRW",
  "payment_method": "TOSS"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "event_id": 1,
    "payer_id": 3,
    "receiver_id": 5,
    "amount": 50000.00,
    "currency": "KRW",
    "status": "PENDING",
    "payment_method": "TOSS",
    "checkout_url": "https://pay.toss.im/...",
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

### 2. 결제 상태 조회
```http
GET /payments/{payment_id}
Authorization: Bearer {access_token}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "event_id": 1,
    "payer_id": 3,
    "receiver_id": 5,
    "amount": 50000.00,
    "currency": "KRW",
    "status": "COMPLETED",
    "payment_method": "TOSS",
    "transaction_id": "toss_12345678",
    "metadata": {},
    "created_at": "2025-01-01T10:00:00Z",
    "updated_at": "2025-01-01T10:05:00Z"
  }
}
```

### 3. 환불 요청
```http
POST /payments/{payment_id}/refund
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "reason": "일정 취소"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "REFUNDED",
    "refund_amount": 50000.00,
    "updated_at": "2025-01-01T11:00:00Z"
  }
}
```

---

## 에러 코드

### HTTP 상태 코드

| 코드 | 의미 | 사용 예시 |
|------|------|-----------|
| 200 | OK | 성공적인 GET, PATCH, DELETE |
| 201 | Created | 성공적인 POST (리소스 생성) |
| 400 | Bad Request | 잘못된 요청 데이터 |
| 401 | Unauthorized | 인증 실패 (토큰 없음/만료) |
| 403 | Forbidden | 권한 없음 |
| 404 | Not Found | 리소스 없음 |
| 409 | Conflict | 중복 리소스 (예: 이미 예약됨) |
| 422 | Unprocessable Entity | 검증 실패 |
| 429 | Too Many Requests | Rate Limit 초과 |
| 500 | Internal Server Error | 서버 오류 |

### 커스텀 에러 코드

| 에러 코드 | HTTP | 설명 |
|-----------|------|------|
| `AUTH_TOKEN_MISSING` | 401 | Authorization 헤더 없음 |
| `AUTH_TOKEN_EXPIRED` | 401 | Access Token 만료 |
| `AUTH_TOKEN_INVALID` | 401 | 잘못된 토큰 |
| `AUTH_PHONE_VERIFICATION_FAILED` | 400 | 전화번호 인증 실패 |
| `AUTH_PHONE_CODE_EXPIRED` | 400 | 인증 코드 만료 |
| `USER_NOT_FOUND` | 404 | 사용자 없음 |
| `USER_ALREADY_EXISTS` | 409 | 이미 존재하는 사용자 |
| `EVENT_NOT_FOUND` | 404 | 이벤트 없음 |
| `EVENT_ACCESS_DENIED` | 403 | 이벤트 접근 권한 없음 |
| `EVENT_ALREADY_CONFIRMED` | 409 | 이미 확정된 이벤트 |
| `EVENT_ALREADY_CANCELED` | 409 | 이미 취소된 이벤트 |
| `SLOT_NOT_AVAILABLE` | 409 | 예약 불가능한 슬롯 |
| `SLOT_NOT_FOUND` | 404 | 오픈 슬롯 없음 |
| `PAYMENT_FAILED` | 400 | 결제 실패 |
| `PAYMENT_NOT_FOUND` | 404 | 결제 정보 없음 |
| `REFUND_NOT_ALLOWED` | 403 | 환불 불가 |
| `VALIDATION_ERROR` | 422 | 입력 검증 실패 |
| `RATE_LIMIT_EXCEEDED` | 429 | API 호출 제한 초과 |
| `INTERNAL_ERROR` | 500 | 서버 내부 오류 |

### 에러 응답 예시

```json
{
  "success": false,
  "error": {
    "code": "EVENT_NOT_FOUND",
    "message": "Event with ID 123 not found",
    "details": {
      "event_id": 123
    }
  }
}
```

---

## WebSocket API

### 연결
```
ws://localhost:8080/api/v1/ws?event_id={event_id}
Authorization: Bearer {access_token}  // HTTP 헤더로 전달
```

**연결 파라미터**:
- `event_id`: 이벤트 ID (필수)

**인증**:
- Authorization 헤더에 Bearer 토큰 포함
- 토큰에서 user_id 추출하여 사용자 인증

### 메시지 형식

#### 1. 채팅 메시지 전송 (Client → Server)
```json
{
  "type": "message",
  "message": "안녕하세요!",
  "reply_to": "550e8400-e29b-41d4-a716-446655440000"
}
```

**필드**:
- `type`: 메시지 타입 ("message", "typing", "system")
- `message`: 메시지 내용 (필수)
- `reply_to`: 답장할 메시지 ID (선택)

#### 2. 채팅 메시지 수신 (Server → Client - 브로드캐스트)
```json
{
  "event_id": 1,
  "created_at": "2025-12-31T10:00:00Z",
  "message_id": "550e8400-e29b-41d4-a716-446655440000",
  "sender_id": 1,
  "sender_name": "홍길동",
  "sender_profile_url": "https://...",
  "message": "안녕하세요!",
  "message_type": "text",
  "attachments": [],
  "reply_to": null,
  "edited_at": null,
  "is_deleted": false,
  "metadata": {}
}
```

#### 3. Ping/Pong (연결 유지)
- Ping: 서버 → 클라이언트 (54초마다)
- Pong: 클라이언트 → 서버 (응답)
- Read Deadline: 60초
- Write Timeout: 10초

### 연결 관리

**Room 기반 브로드캐스팅**:
- 각 이벤트마다 독립적인 채팅방
- 같은 event_id로 연결한 모든 클라이언트에게 메시지 브로드캐스트

**메시지 흐름**:
1. 클라이언트 → WebSocket Gateway (메시지 전송)
2. Gateway → NATS JetStream (메시지 발행: `chat.message.{event_id}`)
3. Gateway → 같은 이벤트의 모든 클라이언트 (즉시 브로드캐스트)
4. Chat Worker ← NATS JetStream (메시지 구독)
5. Chat Worker → ScyllaDB (메시지 영구 저장)

**재연결**:
- 연결 끊김 시 자동 재연결
- 마지막 메시지 이후 데이터는 REST API로 조회

---

## Rate Limiting

### 제한 정책
- **일반 사용자**: 100 requests/분
- **비즈니스 사용자**: 300 requests/분

### 헤더
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1609459200  // Unix timestamp
```

### 초과 시 응답
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 30 seconds.",
    "details": {
      "retry_after": 30
    }
  }
}
```

---

## 버전 관리

### API 버전
- 현재 버전: `v1`
- Base URL: `/api/v1`

### 버전 업그레이드 정책
- 하위 호환성 유지 (최소 6개월)
- 새 버전 출시 시 공지 (최소 3개월 전)
- Deprecated 엔드포인트는 헤더로 알림:
  ```http
  X-API-Deprecated: true
  X-API-Sunset: 2025-07-01T00:00:00Z
  ```

---

자세한 내용은 [Backend API 코드](../backend/) 참조
