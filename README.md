# timingle

> 약속이 대화가 되는 앱

[![Project Status](https://img.shields.io/badge/status-in%20development-yellow)](https://github.com/yourusername/timingle)
[![Go Version](https://img.shields.io/badge/go-1.22%2B-blue)](https://go.dev/)
[![Flutter Version](https://img.shields.io/badge/flutter-3.0%2B-blue)](https://flutter.dev/)

## 📱 프로젝트 소개

**timingle** (Time + Mingle)는 약속 중심 커뮤니케이션 플랫폼입니다.

### 핵심 철학
> **"약속 없이는 대화 불가"**

- 🗓️ **약속이 먼저** - 모든 대화는 약속(이벤트)에 종속됩니다
- 💬 **독립적인 채팅** - 약속마다 별도의 채팅방
- 📝 **자동 기록** - 모든 변경/확정 이력 추적
- 🎯 **책임 강제** - 노쇼 방지 및 확인 시스템

### 차별점

| 기능 | 카카오톡 | Google Calendar | timingle |
|------|----------|-----------------|----------|
| 약속 관리 | ❌ | ✅ | ✅ |
| 실시간 채팅 | ✅ | ❌ | ✅ |
| 변경 이력 | ❌ | ❌ | ✅ |
| 노쇼 방지 | ❌ | ❌ | ✅ |
| 약속별 채팅 분리 | ❌ | ❌ | ✅ |

## 🚀 빠른 시작

### 필수 요구사항

- **Backend**: Go 1.22+
- **Frontend**: Flutter 3.0+, Dart 3.0+
- **Infrastructure**: Podman 4.0+, podman-compose 1.0+

### 로컬 개발 환경 설정

```bash
# 1. 저장소 클론
git clone https://github.com/yourusername/timingle2.git
cd timingle2

# 2. Podman 환경 시작 (PostgreSQL, Redis, NATS, ScyllaDB)
cd containers
podman-compose up -d

# 3. Backend 서버 실행
cd ../backend
go run cmd/api/main.go

# 4. Frontend 앱 실행
cd ../frontend
flutter pub get
flutter run
```

자세한 내용은 [개발 가이드](docs/DEVELOPMENT.md)를 참조하세요.

## 📂 프로젝트 구조

```
timingle2/
├── backend/              # Go 백엔드
│   ├── cmd/             # 실행 파일
│   ├── internal/        # 내부 패키지
│   └── migrations/      # DB 마이그레이션
├── frontend/            # Flutter 앱
│   └── lib/
│       ├── core/        # 공통 코드
│       └── features/    # 기능별 모듈
├── containers/          # Podman 설정
├── docs/                # 문서
│   ├── phases/          # 단계별 실행 계획
│   └── *.md             # 각종 문서
├── CLAUDE.md            # Claude 협업 가이드
└── README.md            # 이 파일
```

## 🎯 주요 기능

### MVP (Phase 1-3)
- ✅ 사용자 인증 (전화번호, Google)
- ✅ 이벤트 생성/관리
- ✅ 이벤트별 실시간 채팅
- ✅ 변경 이력 자동 기록
- ✅ 상태 관리 (제안/확정/완료/취소)

### 확장 기능 (Phase 4-5)
- 🔄 오픈 예약 시스템
- 🔄 결제 연동 (Toss/Stripe)
- 🔄 지역/관심사 기반 추천
- 🔄 노쇼 방지 정책

## 🏗️ 기술 스택

### Backend
- **언어**: Go 1.22+
- **프레임워크**: Gin
- **데이터베이스**: PostgreSQL, ScyllaDB
- **캐시**: Redis
- **메시징**: NATS JetStream
- **인증**: JWT

### Frontend
- **프레임워크**: Flutter 3.0+
- **아키텍처**: Clean Architecture + SOLID
- **상태관리**: Riverpod
- **네트워킹**: Dio + Retrofit
- **로컬 저장소**: Hive

### Infrastructure
- **컨테이너**: Podman, podman-compose (rootless)
- **CI/CD**: GitHub Actions (예정)
- **모니터링**: Prometheus + Grafana (예정)

## 📖 문서

### 핵심 문서
- [CLAUDE.md](CLAUDE.md) - Claude와의 협업 가이드
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - 시스템 아키텍처
- [docs/DATABASE.md](docs/DATABASE.md) - 데이터베이스 설계
- [docs/API.md](docs/API.md) - REST API 명세
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) - 개발 환경 설정

### 단계별 실행 계획
- [docs/PHASES.md](docs/PHASES.md) - 전체 단계 개요
- [docs/phases/PHASE_0_SETUP.md](docs/phases/PHASE_0_SETUP.md) - 환경 설정
- [docs/phases/PHASE_1_BACKEND_CORE.md](docs/phases/PHASE_1_BACKEND_CORE.md) - 백엔드 핵심
- [docs/phases/PHASE_2_REALTIME.md](docs/phases/PHASE_2_REALTIME.md) - 실시간 기능
- [docs/phases/PHASE_3_FLUTTER.md](docs/phases/PHASE_3_FLUTTER.md) - Flutter 앱

## 🎨 브랜드

### 로고
- 알람시계 + 말풍선 결합
- 블루 그라디언트 (`#2E4A8F` → `#5EC4E8`)

### 색상 팔레트
```
Primary Blue:   #2E4A8F (진한 네이비 블루)
Secondary Blue: #5EC4E8 (밝은 하늘색)
Accent Blue:    #3B82F6 (포인트 버튼)
```

자세한 내용은 [docs/BRAND.md](docs/BRAND.md)를 참조하세요.

## 🔧 개발 가이드

### 코딩 컨벤션

#### Backend (Go)
```go
// 파일명: snake_case
// event_service.go

// 구조체: PascalCase
type EventService struct {}

// Public 메서드: PascalCase
func (s *EventService) CreateEvent() {}

// Private 메서드: camelCase
func (s *EventService) validateEvent() {}
```

#### Frontend (Flutter)
```dart
// 파일명: snake_case
// event_repository.dart

// 클래스: PascalCase
class EventRepository {}

// 변수/함수: camelCase
void getEvents() {}

// 상수: lowerCamelCase with k prefix
const kPrimaryColor = Color(0xFF2E4A8F);
```

### Git 브랜치 전략

```
main           # 프로덕션
├── develop    # 개발
    ├── feature/event-creation
    ├── feature/real-time-chat
    └── fix/auth-bug
```

### 커밋 메시지 형식

```
feat: 새 기능 추가
fix: 버그 수정
docs: 문서 수정
style: 코드 포맷팅
refactor: 코드 리팩토링
test: 테스트 추가
chore: 빌드/설정 변경

예시:
feat: Add event creation API endpoint
fix: Fix JWT token expiration issue
docs: Update API documentation for events
```

## 🧪 테스트

### Backend
```bash
cd backend
go test ./...
```

### Frontend
```bash
cd frontend
flutter test
```

## 📈 로드맵

### Phase 0: 환경 설정 (1-2일)
- [ ] Docker Compose 설정
- [ ] 프로젝트 구조 생성
- [ ] 기본 설정 파일

### Phase 1: 백엔드 핵심 (Week 1)
- [ ] JWT 인증
- [ ] 이벤트 CRUD API
- [ ] 상태 머신 구현

### Phase 2: 실시간 기능 (Week 2)
- [ ] WebSocket Gateway
- [ ] NATS 메시징
- [ ] 채팅 Worker

### Phase 3: Flutter 앱 (Week 3)
- [ ] Clean Architecture 구조
- [ ] 로그인/메인 화면
- [ ] 이벤트 목록/상세
- [ ] 실시간 채팅

### Phase 4: 통합 테스트 (Week 4)
- [ ] E2E 테스트
- [ ] 성능 최적화
- [ ] 버그 수정

### Phase 5: 배포 (Week 4+)
- [ ] CI/CD 파이프라인
- [ ] 프로덕션 배포
- [ ] 모니터링 설정

자세한 로드맵은 [docs/PHASES.md](docs/PHASES.md)를 참조하세요.

## 👥 팀

- **Backend**: Go Developer
- **Frontend**: Flutter Developer
- **DevOps**: Infrastructure Engineer
- **Design**: UI/UX Designer

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🤝 기여하기

기여는 언제나 환영합니다! 자세한 내용은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

### 기여 절차
1. 이슈 생성 또는 기존 이슈 선택
2. Fork 후 feature 브랜치 생성
3. 변경사항 커밋
4. Pull Request 생성
5. 코드 리뷰 및 머지

## 📞 문의

- **이슈**: [GitHub Issues](https://github.com/yourusername/timingle2/issues)
- **이메일**: contact@timingle.com
- **문서**: [docs/](docs/)

---

**timingle** - 약속이 대화가 되는 순간

*Made with ❤️ by timingle team*
