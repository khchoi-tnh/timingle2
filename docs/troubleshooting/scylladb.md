# ScyllaDB Troubleshooting

**ScyllaDB 관련 문제 해결**

---

## ❌ 문제 1: Cluster Name 충돌

### 증상
```
ERROR: Startup failed: exceptions::configuration_exception
(Saved cluster name timingle-cluster != configured name )
```

### 원인
- ScyllaDB는 첫 실행 시 cluster name을 `/var/lib/scylla` 볼륨에 영구 저장
- 설정을 변경해도 볼륨에 저장된 이전 데이터와 충돌
- Podman 볼륨이 남아있어서 이전 설정이 계속 적용됨

### 해결 방법

```bash
# 1. 모든 컨테이너와 볼륨 완전 삭제
cd /home/khchoi/projects/timingle2/containers
podman-compose down -v

# 2. 볼륨이 정말 삭제되었는지 확인
podman volume ls
# (scylla_data가 없어야 함)

# 3. 수동으로 볼륨 삭제 (필요시)
podman volume rm containers_scylla_data

# 4. 재시작
podman-compose up -d

# 5. 로그 확인 (2분 대기)
sleep 120
podman logs timingle-scylla -f
```

### 예방
- 설정 변경 시 항상 `-v` 옵션으로 볼륨까지 삭제
- 개발 환경에서는 `--developer-mode 1` 필수

---

## ❌ 문제 2: 리소스 부족

### 증상
```
ERROR: Startup failed: bad_configuration_error
```
또는 컨테이너가 계속 재시작됨

### 원인
- ScyllaDB는 기본적으로 많은 리소스 요구 (4GB+ 메모리)
- 개발 환경에서 프로덕션 설정 사용

### 해결 방법

`containers/podman-compose.yml` 수정:

```yaml
scylla:
  image: docker.io/scylladb/scylla:5.4
  container_name: timingle-scylla
  command: --smp 1 --memory 1G --overprovisioned 1 --api-address 0.0.0.0 --developer-mode 1
  # 설정 설명:
  # --smp 1: CPU 코어 1개 사용
  # --memory 1G: 메모리 1GB로 제한
  # --overprovisioned 1: 리소스 부족 환경 허용
  # --developer-mode 1: 개발 모드 (엄격한 검증 완화)
```

### 환경별 권장 설정

| 환경 | CPU | 메모리 | command |
|------|-----|--------|---------|
| **개발** | 1 코어 | 1GB | `--smp 1 --memory 1G --developer-mode 1 --overprovisioned 1` |
| **스테이징** | 2 코어 | 2GB | `--smp 2 --memory 2G --overprovisioned 1` |
| **프로덕션** | 4+ 코어 | 4GB+ | 기본 설정 또는 scylla.yaml 사용 |

---

## ❌ 문제 3: CQL 포트 연결 실패

### 증상
```
Connection error: ('Unable to connect to any servers',
{'10.89.0.X:9042': ConnectionRefusedError(111, "Connection refused")})
```

### 원인
- ScyllaDB 초기화에 시간이 오래 걸림 (30-120초)
- CQL 포트(9042)가 API 서버보다 늦게 시작됨
- healthcheck가 너무 빨리 실행됨

### 해결 방법

#### 방법 1: 충분히 대기
```bash
# ScyllaDB 시작 후 최소 2분 대기
podman-compose up -d
sleep 120

# 연결 테스트
podman exec timingle-scylla cqlsh -e "DESCRIBE KEYSPACES;"
```

#### 방법 2: 로그로 시작 확인
```bash
# "Starting listening for CQL clients" 메시지 대기
podman logs timingle-scylla 2>&1 | grep -i "cql"
```

#### 방법 3: healthcheck 설정 조정

`podman-compose.yml`:
```yaml
scylla:
  healthcheck:
    test: ["CMD", "cqlsh", "-e", "DESCRIBE KEYSPACES"]
    interval: 30s
    timeout: 10s
    retries: 5
    start_period: 90s  # 초기 시작 90초 대기 (필수!)
```

### 확인 방법
```bash
# healthcheck 상태 확인
podman inspect timingle-scylla | grep -A 10 Health

# 수동 연결 테스트
podman exec -it timingle-scylla cqlsh
```

---

## ❌ 문제 4: scylla.yaml 설정 파일 오류

### 증상
```
ERROR: configuration error in scylla.yaml
```
또는 컨테이너 시작 직후 종료됨

### 원인
- 잘못된 YAML 문법
- 필수 설정 누락
- 개발 환경에 부적합한 프로덕션 설정

### 해결 방법

#### 방법 1: 설정 파일 마운트 제거 (권장 - 개발 환경)

```yaml
scylla:
  volumes:
    - scylla_data:/var/lib/scylla:Z
    # scylla.yaml 마운트 제거 - 기본 설정 사용
  command: --smp 1 --memory 1G --developer-mode 1
```

#### 방법 2: 최소 설정 파일 사용 (필요 시)

`containers/scylla/scylla.yaml`:
```yaml
cluster_name: 'timingle-cluster'
listen_address: 0.0.0.0
rpc_address: 0.0.0.0
seed_provider:
  - class_name: org.apache.cassandra.locator.SimpleSeedProvider
    parameters:
      - seeds: "127.0.0.1"
endpoint_snitch: SimpleSnitch
developer_mode: true
```

### 설정 파일 검증
```bash
# YAML 문법 검증
yamllint containers/scylla/scylla.yaml

# 또는 Python으로 검증
python3 -c "import yaml; yaml.safe_load(open('containers/scylla/scylla.yaml'))"
```

---

## ❌ 문제 5: 컨테이너가 계속 재시작됨

### 증상
```bash
podman-compose ps
# STATUS: Restarting (1) 2 seconds ago
```

### 원인
- ScyllaDB 시작 실패가 반복됨
- supervisor가 계속 재시도

### 해결 방법

```bash
# 1. 전체 로그 확인
podman logs timingle-scylla 2>&1 | tail -100

# 2. ERROR 라인만 추출
podman logs timingle-scylla 2>&1 | grep ERROR

# 3. 컨테이너 중지
podman-compose stop scylla

# 4. 볼륨 삭제
podman-compose down -v

# 5. 설정 수정 후 재시작
# podman-compose.yml 수정 (--developer-mode 1 추가)
podman-compose up -d
```

---

## 🔧 디버깅 명령어

### 로그 확인
```bash
# 실시간 로그
podman logs timingle-scylla -f

# 최근 100줄
podman logs timingle-scylla --tail 100

# 에러만 추출
podman logs timingle-scylla 2>&1 | grep -i error

# 특정 키워드 검색
podman logs timingle-scylla 2>&1 | grep -i "cql\|starting\|listening"
```

### 상태 확인
```bash
# 컨테이너 상태
podman inspect timingle-scylla | grep -A 10 State

# Health check 상태
podman inspect timingle-scylla | grep -A 10 Health

# 리소스 사용량
podman stats timingle-scylla --no-stream
```

### CQL 셸 접속
```bash
# 컨테이너 내부 접속
podman exec -it timingle-scylla cqlsh

# 한 줄 쿼리 실행
podman exec timingle-scylla cqlsh -e "DESCRIBE KEYSPACES;"
podman exec timingle-scylla cqlsh -e "SELECT cluster_name FROM system.local;"
```

---

## 💡 개발 환경 권장 설정

### podman-compose.yml (최종)

```yaml
scylla:
  image: docker.io/scylladb/scylla:5.4
  container_name: timingle-scylla
  ports:
    - "9042:9042"   # CQL
    - "10000:10000" # REST API
  volumes:
    - scylla_data:/var/lib/scylla:Z
  command: --smp 1 --memory 1G --overprovisioned 1 --api-address 0.0.0.0 --developer-mode 1
  healthcheck:
    test: ["CMD", "cqlsh", "-e", "DESCRIBE KEYSPACES"]
    interval: 30s
    timeout: 10s
    retries: 5
    start_period: 90s
  restart: unless-stopped
```

### 주요 포인트
- ✅ `--developer-mode 1`: 필수!
- ✅ `--smp 1 --memory 1G`: 개발 환경 최소 리소스
- ✅ `--overprovisioned 1`: 리소스 부족 허용
- ✅ `start_period: 90s`: 충분한 초기화 시간
- ❌ scylla.yaml 마운트 제거: 기본 설정 사용

---

## 📊 타임라인 (실제 발생한 문제)

**2025-12-31 프로젝트 초기 설정 시**:

1. **22:46**: scylla.yaml 파일 문제 + cluster name 충돌 발생
2. **22:48**: 볼륨 삭제 시도 (부분적 성공)
3. **22:51**: 여전히 이전 cluster name 남아있음
4. **22:52**: `podman-compose down -v`로 완전 삭제
5. **22:53**: 성공! ✅
   - 깨끗한 볼륨
   - 간단한 설정 (--developer-mode 1)
   - 2분 대기 후 정상 동작

**교훈**:
- 설정 변경 시 항상 볼륨까지 삭제 (`-v`)
- ScyllaDB는 최소 2분 초기화 시간 필요
- 개발 환경에서는 `--developer-mode 1` 필수

---

**마지막 업데이트**: 2025-12-31
