# Admin Dashboard 실행 가이드

> timingle 관리자 대시보드 실행 및 개발 환경 설정

---

## 시스템 구조

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Admin System Architecture                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Windows (D:\projects\timingle2)                                        │
│  ├── admin/              ← Backend API (Bun + Hono)     :3000          │
│  └── admin/web/          ← Frontend (React + Vite)      :5173          │
│                                                                         │
│  WSL Rocky Linux                                                        │
│  └── containers/         ← Podman (PostgreSQL, Redis)   :5432, :6379   │
│                                                                         │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐             │
│  │  Frontend   │ ───► │  Backend    │ ───► │  Database   │             │
│  │  :5173      │      │  :3000      │      │  :5432      │             │
│  │  React+Vite │      │  Bun+Hono   │      │  PostgreSQL │             │
│  └─────────────┘      └─────────────┘      └─────────────┘             │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 기술 스택

| 레이어 | 기술 | 설명 |
|--------|------|------|
| **Frontend** | React 19 + Vite 7 | SPA 관리자 UI |
| **Backend** | Bun + Hono | 고성능 API 서버 |
| **ORM** | Drizzle | Type-safe SQL 쿼리 |
| **Database** | PostgreSQL | 메인 데이터베이스 |
| **Container** | Podman | WSL에서 컨테이너 실행 |

---

## 실행 순서

### Step 1: Database 실행 (WSL Rocky Linux)

```bash
# WSL 접속
wsl -d Rocky-9

# 프로젝트 디렉토리 이동
cd /mnt/d/projects/timingle2/containers

# 컨테이너 시작
podman-compose up -d

# 상태 확인
podman-compose ps
```

**예상 결과:**
```
NAME                 STATUS          PORTS
timingle-postgres    Up 10 minutes   0.0.0.0:5432->5432/tcp
timingle-redis       Up 10 minutes   0.0.0.0:6379->6379/tcp
timingle-nats        Up 10 minutes   0.0.0.0:4222->4222/tcp
timingle-scylla      Up 10 minutes   0.0.0.0:9042->9042/tcp
```

### Step 2: Admin Backend 실행 (Windows Terminal 1)

```bash
# 프로젝트 디렉토리 이동
cd D:\projects\timingle2\admin

# 환경 변수 설정 (최초 1회)
copy .env.example .env

# 의존성 설치 (최초 1회)
bun install

# 개발 서버 실행
bun run dev
```

**예상 결과:**
```
🦊 Hono server running at http://localhost:3000
```

### Step 3: Admin Frontend 실행 (Windows Terminal 2)

```bash
# 프로젝트 디렉토리 이동
cd D:\projects\timingle2\admin\web

# 의존성 설치 (최초 1회)
bun install

# 개발 서버 실행
bun run dev
```

**예상 결과:**
```
  VITE v7.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

### Step 4: 브라우저에서 접속

```
http://localhost:5173
```

---

## 포트 정리

| 서비스 | 포트 | 설명 |
|--------|------|------|
| PostgreSQL | 5432 | 메인 데이터베이스 |
| Redis | 6379 | 캐시/세션 |
| NATS | 4222 | 메시지 브로커 |
| ScyllaDB | 9042 | 시계열 데이터 |
| Admin API | 3000 | Backend API 서버 |
| Admin Web | 5173 | Frontend 개발 서버 |
| User API | 8080 | Go Backend (별도) |

---

## 환경 변수 (.env)

### admin/.env

```env
# Database
DATABASE_URL=postgres://timingle:timingle@localhost:5432/timingle

# JWT Secret (Admin 전용)
ADMIN_JWT_SECRET=your-super-secret-admin-jwt-key-change-in-production

# Server
PORT=3000

# CORS
CORS_ORIGIN=http://localhost:5173
```

---

## 스크립트 명령어

### Backend (admin/)

| 명령어 | 설명 |
|--------|------|
| `bun run dev` | 개발 서버 (Hot Reload) |
| `bun run start` | 프로덕션 서버 |
| `bun run db:generate` | Drizzle 마이그레이션 생성 |
| `bun run db:push` | DB 스키마 동기화 |

### Frontend (admin/web/)

| 명령어 | 설명 |
|--------|------|
| `bun run dev` | 개발 서버 (Vite) |
| `bun run build` | 프로덕션 빌드 |
| `bun run lint` | ESLint 검사 |
| `bun run preview` | 빌드 미리보기 |

---

## 빠른 시작 (한 줄 요약)

```bash
# Terminal 1 (WSL)
wsl -d Rocky-9 -e bash -c "cd /mnt/d/projects/timingle2/containers && podman-compose up -d"

# Terminal 2 (Windows)
cd D:\projects\timingle2\admin && bun run dev

# Terminal 3 (Windows)
cd D:\projects\timingle2\admin\web && bun run dev
```

---

## Troubleshooting

### DB 연결 실패

```
Error: connect ECONNREFUSED 127.0.0.1:5432
```

**해결:**
1. WSL에서 PostgreSQL 컨테이너 확인
2. `podman-compose ps`로 상태 확인
3. 컨테이너 재시작: `podman-compose restart postgres`

### CORS 에러

```
Access to fetch at 'http://localhost:3000' from origin 'http://localhost:5173'
has been blocked by CORS policy
```

**해결:**
- `admin/.env`에서 `CORS_ORIGIN=http://localhost:5173` 확인

### 포트 충돌

```
Error: listen EADDRINUSE: address already in use :::3000
```

**해결:**
```bash
# Windows에서 포트 사용 프로세스 확인
netstat -ano | findstr :3000

# 프로세스 종료
taskkill /PID <PID> /F
```

---

## 관련 문서

- [DEVELOPMENT.md](./DEVELOPMENT.md) - 전체 개발 환경 설정
- [API.md](./API.md) - API 명세
- [DATABASE.md](./DATABASE.md) - DB 스키마

---

마지막 업데이트: 2026-02-01
