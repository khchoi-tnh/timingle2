# Backend Migrations

timingle 백엔드 데이터베이스 마이그레이션 스크립트

---

## 📂 구조

```
backend/migrations/
├── 001_create_users_table.sql              # 사용자 테이블
├── 002_create_events_table.sql             # 이벤트 테이블
├── 003_create_event_participants_table.sql # 이벤트 참가자
├── 004_create_refresh_tokens_table.sql     # 리프레시 토큰
├── 005_create_oauth_accounts_table.sql     # OAuth 계정
├── 006_add_oauth_tokens.sql                # OAuth 토큰
├── 007_add_google_calendar_id.sql          # Google Calendar ID
├── 008_alter_phone_length.sql              # 전화번호 길이 변경
├── 009_create_friendships_table.sql        # 친구 관계
├── 010_alter_event_participants.sql        # 참가자 테이블 수정
├── 011_create_event_invite_links.sql       # 초대 링크
├── 012_add_admin_role.sql                  # Admin 역할 추가
├── 013_create_audit_logs.sql               # 감사 로그
├── run_migrations.sh                       # 마이그레이션 실행 (Bash)
├── run_migrations.bat                      # 마이그레이션 실행 (Windows)
└── README.md                               # 이 파일
```

---

## 🚀 사용 방법

### Windows에서 실행

```cmd
cd D:\projects\timingle2\backend\migrations
run_migrations.bat
```

### WSL/Linux에서 실행

```bash
cd /mnt/d/projects/timingle2/backend/migrations

# 실행 권한 부여 (최초 1회)
chmod +x run_migrations.sh

# 실행
./run_migrations.sh
```

---

## ⚙️ 동작 방식

1. **환경 변수 로드**: `backend/.env` 파일에서 DB 설정 읽기
2. **컨테이너 확인**: PostgreSQL 컨테이너가 실행 중인지 확인
3. **파일 탐색**: `migrations/*.sql` 파일을 모두 찾음
4. **정렬 실행**: 파일명 순서대로 (`001` → `002` → ...) 실행
5. **에러 처리**: 이미 적용된 마이그레이션은 에러 발생 가능 (정상)
6. **결과 요약**: 성공/실패 개수 출력

---

## 📋 출력 예시

```
======================================
  timingle Backend Migrations
======================================

📄 Loading environment from: /path/to/backend/.env
   🔹 Host: localhost:5432
   🔹 User: timingle
   🔹 Database: timingle

📁 Found 13 migration files

🔄 Running: 001_create_users_table.sql
   ✅ Success

🔄 Running: 002_create_events_table.sql
   ✅ Success

...

======================================
  Migration Results
======================================
✅ Success: 13
❌ Failed:  0
📊 Total:   13

🎉 All migrations completed successfully!
```

---

## ⚠️ 주의사항

### 이미 적용된 마이그레이션

- 이미 적용된 마이그레이션을 다시 실행하면 에러가 발생할 수 있습니다.
- 예: `CREATE TABLE` → `already exists` 에러
- 이는 정상이며, 스크립트는 계속 진행됩니다.

### 마이그레이션 순서

- 마이그레이션은 **반드시 순서대로** 실행되어야 합니다.
- 파일명 앞에 `001`, `002`, ... 번호가 있어 자동으로 정렬됩니다.

### 환경 변수 설정

스크립트는 `backend/.env` 파일에서 다음 변수를 읽습니다:

```env
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=timingle
POSTGRES_PASSWORD=timingle_dev_password
POSTGRES_DB=timingle
```

### 새 마이그레이션 추가

새 마이그레이션을 추가할 때:

1. 다음 번호로 파일 생성 (예: `014_새기능.sql`)
2. 스크립트 수정 불필요 (자동으로 탐지)
3. `.env` 파일의 DB 설정이 자동으로 사용됨

---

## 🔧 수동 실행 (개별 마이그레이션)

특정 마이그레이션만 실행하려면:

```bash
# WSL에서
podman exec -i timingle-postgres psql -U timingle -d timingle < 001_create_users_table.sql

# Windows에서 (WSL 경로)
wsl -d AlmaLinux-Kitten-10 -e podman exec -i timingle-postgres psql -U timingle -d timingle < /mnt/d/projects/timingle2/backend/migrations/001_create_users_table.sql
```

---

## 📊 vs Admin Dashboard Drizzle

| 항목 | Backend Migrations | Admin Dashboard |
|------|-------------------|-----------------|
| **위치** | `backend/migrations/*.sql` | `admin/src/db/schema.ts` |
| **실행** | `run_migrations.sh` | `bun run db:push` |
| **DB** | timingle (Go Backend용) | timingle (Admin용) |
| **테이블** | users, events, friendships, oauth 등 | users, events, audit_logs 등 |
| **목적** | Go Backend API | Admin Dashboard |

**주의**: 두 시스템 모두 같은 `timingle` 데이터베이스를 사용하지만, **스키마가 다를 수 있습니다!**

---

마지막 업데이트: 2026-02-01
