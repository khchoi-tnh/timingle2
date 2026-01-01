# timingle 단계별 실행 계획

> 각 단계는 독립적으로 실행 가능하도록 설계되어 있습니다.

## 📋 전체 개요

timingle 프로젝트는 **6개의 Phase**로 구성되어 있으며, 각 Phase는 명확한 목표와 체크리스트를 가지고 있습니다.

### 전체 타임라인

```
Phase 0: 환경 설정        [1-2일]   ━━━━━
Phase 1: 백엔드 핵심      [Week 1]  ━━━━━━━━━━
Phase 2: 실시간 기능      [Week 2]  ━━━━━━━━━━
Phase 3: Flutter 앱       [Week 3]  ━━━━━━━━━━
Phase 4: 통합 테스트      [Week 4]  ━━━━━━━━━━
Phase 5: 배포 및 출시     [Week 4+] ━━━━━━
```

**총 예상 기간**: 4-5주

---

## Phase 0: 환경 설정 (1-2일) ✅ 완료

### 🎯 목표
개발에 필요한 모든 환경을 로컬에 구축합니다.

### ✅ 완료 조건
- [x] Podman Compose로 모든 인프라 실행 중
- [x] Backend 프로젝트 구조 생성
- [x] Frontend 프로젝트 생성
- [x] 기본 설정 파일 완료

### 📝 상세 문서
[docs/phases/PHASE_0_SETUP.md](phases/PHASE_0_SETUP.md)

### 주요 작업
1. Docker Compose 설정 (PostgreSQL, Redis, NATS, ScyllaDB)
2. Go 프로젝트 구조 생성
3. Flutter 프로젝트 생성 및 Clean Architecture 구조
4. 환경변수 설정 (.env)
5. Git 설정 (.gitignore)

---

## Phase 1: 백엔드 핵심 (Week 1) ✅ 완료

### 🎯 목표
인증 시스템과 이벤트 CRUD API를 구현합니다.

### ✅ 완료 조건
- [x] JWT 인증 시스템 작동
- [x] 이벤트 생성/조회/수정/삭제 API 완료
- [x] 상태 머신 구현 (PROPOSED/CONFIRMED/DONE/CANCELED)
- [x] 단위 테스트 작성

### 📝 상세 문서
[docs/phases/PHASE_1_BACKEND_CORE.md](phases/PHASE_1_BACKEND_CORE.md)

### 주요 작업
1. DB 스키마 마이그레이션
2. JWT 인증 미들웨어
3. 사용자 등록/로그인 API
4. 이벤트 CRUD API
5. 이벤트 참여자 관리
6. 상태 전이 로직

---

## Phase 2: 실시간 기능 (Week 2) ✅ 완료

### 🎯 목표
WebSocket 기반 실시간 채팅을 구현합니다.

### ✅ 완료 조건
- [x] WebSocket Gateway 실행 중
- [x] NATS JetStream 설정 완료
- [x] 채팅 메시지 송수신 작동
- [x] ScyllaDB에 메시지 저장
- [x] 이벤트 히스토리 자동 기록

### 📝 상세 문서
[docs/phases/PHASE_2_REALTIME.md](phases/PHASE_2_REALTIME.md)

### 주요 작업
1. WebSocket Gateway 구현
2. NATS JetStream 설정
3. Chat Worker 구현
4. 메시지 저장/조회 API
5. 이벤트 히스토리 시스템
6. 재연결 로직

---

## Phase 3: Flutter 앱 (Week 3) ✅ 완료

### 🎯 목표
Flutter 앱의 핵심 화면과 기능을 구현합니다.

### ✅ 완료 조건
- [x] Clean Architecture 구조 완성
- [x] 5개 메인 화면 구현
- [x] 이벤트 CRUD 기능
- [x] 실시간 채팅 연동
- [x] Riverpod 상태 관리

### 📝 상세 문서
[docs/phases/PHASE_3_FLUTTER.md](phases/PHASE_3_FLUTTER.md)

### 주요 작업
1. Flutter 프로젝트 Clean Architecture 구조
2. Riverpod Provider 설정
3. 로그인 화면 (Google 인증)
4. Timingle 메인 화면 (이벤트 목록)
5. Timeline 화면
6. 이벤트 상세 화면 (채팅 포함)
7. WebSocket 연동

---

## Phase 4: 통합 테스트 (Week 4) ✅ 완료

### 🎯 목표
전체 시스템 통합 테스트 및 최적화를 수행합니다.

### ✅ 완료 조건
- [x] Timeline 화면 구현 (캘린더 뷰)
- [x] Open Timingle 화면 구현 (오픈 예약)
- [x] Friends 화면 구현 (친구 목록)
- [x] Bottom Navigation Bar (5개 탭)
- [x] UI/UX 개선
- [x] 문서 업데이트
- [ ] E2E 테스트 (Phase 5로 이동)

### 📝 상세 문서
[docs/phases/PHASE_4_INTEGRATION.md](phases/PHASE_4_INTEGRATION.md)

### 주요 작업
1. E2E 테스트 시나리오 작성
2. 로드 테스트 (Artillery/k6)
3. 메모리 누수 체크
4. API 응답 시간 최적화
5. 사용자 피드백 반영

---

## Phase 5: 배포 및 출시 (Week 4+) 🔄 진행 예정

### 🎯 목표
프로덕션 환경 배포 및 모니터링 설정을 완료합니다.

### ✅ 완료 조건
- [ ] E2E 테스트 및 성능 최적화
- [ ] CI/CD 파이프라인 구축
- [ ] 프로덕션 환경 배포
- [ ] 모니터링 대시보드 설정
- [ ] 앱 스토어 배포 준비
- [ ] 첫 50명 사용자 확보

### 📝 상세 문서
[docs/phases/PHASE_5_DEPLOYMENT.md](phases/PHASE_5_DEPLOYMENT.md)

### 주요 작업
1. GitHub Actions CI/CD
2. Docker 이미지 빌드 자동화
3. Kubernetes 배포 (선택)
4. Prometheus + Grafana 모니터링
5. 앱 스토어 심사 제출
6. 마케팅 및 사용자 확보

---

## 🔄 Phase 간 의존성

```
Phase 0 (환경 설정)
  ↓
Phase 1 (백엔드 핵심)
  ↓
Phase 2 (실시간 기능)
  ↓
Phase 3 (Flutter 앱) ← Phase 1, 2 완료 필요
  ↓
Phase 4 (통합 테스트) ← Phase 1, 2, 3 완료 필요
  ↓
Phase 5 (배포) ← Phase 4 완료 필요
```

### 병렬 작업 가능
- Phase 1과 Phase 3의 일부 (UI 프로토타입)는 병렬 작업 가능
- Phase 2와 Phase 3의 일부 (로컬 상태 관리)는 병렬 작업 가능

---

## 📊 진행 상황 추적

### Phase 0: 환경 설정
- [x] 완료 (100%) ✅

### Phase 1: 백엔드 핵심
- [x] 완료 (100%) ✅

### Phase 2: 실시간 기능
- [x] 완료 (100%) ✅

### Phase 3: Flutter 앱
- [x] 완료 (100%) ✅

### Phase 4: 통합 테스트
- [x] 완료 (100%) ✅

### Phase 5: 배포 및 출시
- [ ] 진행 예정 (0%)

---

## 🎯 Phase별 우선순위

### 높음 (Must Have)
- Phase 0: 모든 항목
- Phase 1: JWT 인증, 이벤트 CRUD
- Phase 2: WebSocket, NATS 기본
- Phase 3: 로그인, 이벤트 목록, 상세, 채팅

### 중간 (Should Have)
- Phase 1: 전화번호 인증
- Phase 2: 이벤트 히스토리
- Phase 3: Timeline, Friends

### 낮음 (Nice to Have)
- Phase 2: ScyllaDB 최적화
- Phase 3: Open Timingle (오픈 예약)
- Phase 5: Kubernetes 배포

---

## 🚀 빠른 시작 가이드

### Phase 0부터 시작하기

```bash
# 1. Phase 0 문서 확인
cat docs/phases/PHASE_0_SETUP.md

# 2. Docker Compose 실행
cd docker
docker-compose up -d

# 3. 상태 확인
docker-compose ps

# 4. Phase 0 완료 확인
# - PostgreSQL: localhost:5432
# - Redis: localhost:6379
# - NATS: localhost:4222
```

### 특정 Phase로 건너뛰기

각 Phase는 독립적으로 실행 가능하지만, 이전 Phase의 완료를 권장합니다.

```bash
# Phase 3로 바로 가기 (Backend Mock 사용)
cd docs/phases
cat PHASE_3_FLUTTER.md

# Mock 서버로 프론트엔드만 개발 가능
```

---

## 📚 관련 문서

### 아키텍처 및 설계
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) - 전체 시스템 아키텍처
- [docs/DATABASE.md](DATABASE.md) - 데이터베이스 스키마
- [docs/API.md](API.md) - REST API 명세

### 개발 가이드
- [docs/DEVELOPMENT.md](DEVELOPMENT.md) - 개발 환경 설정
- [CLAUDE.md](../CLAUDE.md) - Claude 협업 가이드
- [README.md](../README.md) - 프로젝트 개요

---

## ❓ FAQ

### Q1. Phase를 순서대로 진행해야 하나요?
**A**: 권장하지만 필수는 아닙니다. Phase 3 (Flutter)은 Mock 서버로 독립 개발 가능합니다.

### Q2. Phase 0을 건너뛸 수 있나요?
**A**: 불가능합니다. Phase 0은 모든 개발의 기반이 됩니다.

### Q3. 각 Phase의 예상 소요 시간은?
**A**:
- Phase 0: 1-2일
- Phase 1-3: 각 1주
- Phase 4: 1주
- Phase 5: 1-2주

### Q4. Phase 중간에 막히면?
**A**: 각 Phase 문서의 "Troubleshooting" 섹션 참조 또는 Issues 생성

### Q5. 여러 명이 병렬로 작업할 수 있나요?
**A**: 가능합니다.
- Backend 개발자: Phase 1, 2
- Frontend 개발자: Phase 3 (Mock 사용)
- DevOps: Phase 0, 5

---

## 🔔 Phase 완료 체크리스트

각 Phase 완료 시 다음을 확인하세요:

### 기술적 완료
- [ ] 모든 테스트 통과
- [ ] 문서 업데이트
- [ ] 코드 리뷰 완료
- [ ] 다음 Phase 블로커 없음

### 프로세스 완료
- [ ] Git 커밋 및 푸시
- [ ] Phase 문서에 "완료" 체크
- [ ] 다음 Phase 문서 리뷰
- [ ] 팀원에게 공유

---

## 📞 도움이 필요한 경우

- **기술 이슈**: [GitHub Issues](https://github.com/yourusername/timingle2/issues)
- **문서 피드백**: Pull Request 생성
- **긴급 문제**: Slack/Discord/Email

---

**각 Phase는 독립적으로 실행 가능하며, 명확한 목표와 체크리스트를 제공합니다.**

**다음: [Phase 0 시작하기](phases/PHASE_0_SETUP.md) →**
