# PostgreSQL Troubleshooting

**PostgreSQL 관련 문제 해결**

---

## ❌ 문제 1: psql: command not found

### 원인
- 호스트에 PostgreSQL 클라이언트 미설치

### 해결 방법

```bash
# 방법 1: 컨테이너 내부에서 실행 (권장)
podman exec timingle-postgres psql -U timingle -d timingle -c "SELECT 1;"

# 방법 2: 클라이언트 설치
sudo dnf install -y postgresql

# 방법 3: 마이그레이션 파일 복사
podman cp migrations/ timingle-postgres:/tmp/
podman exec timingle-postgres sh -c 'for f in /tmp/migrations/*.sql; do psql -U timingle -d timingle -f "$f"; done'
```

---

## ❌ 문제 2: password authentication failed

### 증상
```
FATAL: password authentication failed for user "timingle"
```

### 해결 방법

```bash
# 1. 환경변수 확인
echo $POSTGRES_PASSWORD

# 2. .env 파일 확인
cat backend/.env | grep POSTGRES_PASSWORD

# 3. 컨테이너 재시작 (비밀번호 변경 시)
podman-compose down -v
podman-compose up -d
```

---

## ❌ 문제 3: 마이그레이션 실패

### 해결 방법

```bash
# 1. 테이블 목록 확인
podman exec timingle-postgres psql -U timingle -d timingle -c "\dt"

# 2. 마이그레이션 파일 복사 및 실행
podman cp backend/migrations timingle-postgres:/tmp/
podman exec timingle-postgres sh -c 'for f in /tmp/migrations/*.sql; do echo "Applying $(basename $f)..."; psql -U timingle -d timingle -f "$f"; done'

# 3. 결과 확인
podman exec timingle-postgres psql -U timingle -d timingle -c "\dt"
```

---

**마지막 업데이트**: 2025-12-31
