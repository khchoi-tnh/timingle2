# Timingle API 테스트 가이드

## 📁 파일 구조

```
postman/
├── docs/
│   ├── README.md          # 이 파일
│   ├── SETUP.md           # 환경 설정
│   └── TEST_FLOW.md       # 테스트 순서
├── 1_health.json          # Health Check
├── 2_auth.json            # 인증 (Phone, Token, Google)
├── 3_users.json           # 사용자
├── 4_events.json          # 이벤트 (CRUD, 상태, 메시지)
├── 5_calendar.json        # 캘린더
├── 6_future.json          # 미구현 (친구, 오픈예약, 결제)
└── timingle-local.postman_environment.json
```

## 🔢 넘버링 체계

| X | 카테고리 | Y (세부) | 상태 |
|---|---------|---------|------|
| 1 | Health | 1-1. Health Check | ✅ |
| 2 | Auth | 2-1. Phone, 2-2. Token, 2-3. Google | ✅ |
| 3 | Users | 3-1. Profile, 3-2. Search | ✅ |
| 4 | Events | 4-1. CRUD, 4-2. Status, 4-3. Messages | ✅ |
| 5 | Calendar | 5-1~3. Google Calendar | ✅ |
| 6 | Future | 6-1. Friends, 6-2. OpenSlots, 6-3. Payments | ❌ |

## 🚀 빠른 시작

1. Postman 설치
2. 모든 JSON 파일 Import
3. Environment Import (`timingle-local.postman_environment.json`)
4. [SETUP.md](./SETUP.md) 참고하여 Backend 실행
5. [TEST_FLOW.md](./TEST_FLOW.md) 순서대로 테스트

## 📚 문서 바로가기

- [환경 설정 가이드](./SETUP.md)
- [테스트 순서 가이드](./TEST_FLOW.md)
