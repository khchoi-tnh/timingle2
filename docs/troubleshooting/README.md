# Troubleshooting Guide

**timingle 프로젝트 문제 해결 가이드**

---

## 📋 문제 유형별 가이드

### 인프라 & 컨테이너
- [ScyllaDB 문제](./scylladb.md) - Cluster name 충돌, 리소스 부족, 연결 실패
- [Podman 문제](./podman.md) - 설치, 권한, 네트워크
- [PostgreSQL 문제](./postgresql.md) - 연결, 인증, 마이그레이션
- [Redis & NATS 문제](./redis-nats.md) - 연결, 설정
- [WSL 문제](../WSL.md#문제-해결) - nftables 오류, 네트워크, ScyllaDB 바인딩 (Windows 개발 환경)

### 개발 환경
- [Go 빌드 문제](./go.md) - 설치, 패키지, 빌드 오류
- [Flutter 문제](./flutter.md) - 설치, 빌드, 의존성

### 일반
- [디버깅 팁](./debugging-tips.md) - 로그 수집, 초기화 방법

---

## 🚨 긴급 문제 해결

### 모든 서비스가 작동하지 않을 때

```bash
cd /home/khchoi/projects/timingle2/containers
podman-compose down -v
podman-compose up -d
sleep 120  # ScyllaDB 초기화 대기
podman-compose ps
```

### 특정 컨테이너만 재시작

```bash
podman-compose restart scylla
podman-compose restart postgres
```

---

## 📝 문제 보고 가이드

새로운 문제를 발견하면 다음 단계를 따라주세요:

### 1. 문제 재현 및 정보 수집

```bash
# 시스템 정보
uname -a
podman --version
go version

# 컨테이너 상태
podman-compose ps

# 로그 수집
podman logs [container-name] > issue.log 2>&1
```

### 2. 해결 방법 찾기

1. 해당 카테고리 문서 확인 (위 링크)
2. [docs/DEVELOPMENT.md](../DEVELOPMENT.md) 확인
3. 공식 문서 참조

### 3. 해결 후 문서화 (필수!)

**해결한 문제는 반드시 이 디렉토리에 문서화해주세요!**

```bash
# 해당 카테고리 파일 수정
# 예: ScyllaDB 문제 해결 시
docs/troubleshooting/scylladb.md
```

**추가할 내용**:
- ❌ 문제 제목 및 증상
- 🔍 원인 분석
- ✅ 해결 방법 (단계별)
- 💡 예방 팁

---

## 📞 도움이 필요하면

1. **문서 확인**: 이 디렉토리의 관련 문서
2. **로그 분석**: `podman logs [container-name]`
3. **이슈 등록**: GitHub Issues (재현 가능한 경우)

---

**이 가이드는 프로젝트 진행 중 발생한 실제 문제들을 기록합니다.**

마지막 업데이트: 2026-01-07
