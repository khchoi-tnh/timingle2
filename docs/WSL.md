# WSL 가이드

Windows에서 timingle 백엔드 개발을 위한 WSL 완벽 가이드

---

## 목차

1. [빠른 시작](#빠른-시작)
2. [WSL 실행 방법](#wsl-실행-방법)
3. [서버 시작](#서버-시작)
4. [자주 쓰는 명령어](#자주-쓰는-명령어)
5. [VSCode 연동](#vscode-연동)
6. [파일 경로](#파일-경로)
7. [문제 해결](#문제-해결)
8. [초기 설정](#초기-설정)

---

## 빠른 시작

### 방법 1: WSL 접속 후 실행

```powershell
# PowerShell에서 WSL 접속
wsl -d AlmaLinux-Kitten-10
```

```bash
# WSL 내부에서 서버 시작
bash /mnt/d/projects/timingle2/containers/setup_podman.sh
bash /mnt/d/projects/timingle2/backend/run.sh
```

### 방법 2: PowerShell에서 바로 실행 (WSL 접속 없이)

```powershell
# 컨테이너 시작
wsl -d AlmaLinux-Kitten-10 bash /mnt/d/projects/timingle2/containers/setup_podman.sh

# API 서버 시작
wsl -d AlmaLinux-Kitten-10 bash /mnt/d/projects/timingle2/backend/run.sh
```

### 한 줄로 실행 (WSL 내부)
```bash
bash /mnt/d/projects/timingle2/containers/setup_podman.sh && bash /mnt/d/projects/timingle2/backend/run.sh
```

### 테스트
```bash
curl http://localhost:8080/health
# {"status":"healthy","service":"timingle-api"}
```

---

## WSL 실행 방법

### 방법 1: PowerShell (가장 간단)

```powershell
wsl -d AlmaLinux-Kitten-10
```

### 방법 2: Windows Terminal (권장)

1. `Win + R` → `wt` 입력 → Enter
2. 상단 탭 옆 `▼` 클릭 → **AlmaLinux-Kitten-10** 선택

### 방법 3: 바탕화면 바로가기

1. 바탕화면 우클릭 → 새로 만들기 → 바로 가기
2. 위치: `wt -d ~ wsl -d AlmaLinux-Kitten-10`
3. 이름: "timingle WSL"

---

## 서버 시작

### 전체 시작 (컨테이너 + API)
```bash
bash /mnt/d/projects/timingle2/containers/setup_podman.sh
bash /mnt/d/projects/timingle2/backend/run.sh
```

### 컨테이너만 시작
```bash
cd ~/projects/timingle2/containers
~/.local/bin/podman-compose -f podman-compose-wsl.yml up -d
```

### API만 시작
```bash
bash /mnt/d/projects/timingle2/backend/run.sh
```

### 상태 확인
```bash
podman ps                          # 컨테이너 상태
curl http://localhost:8080/health  # API 테스트
```

### 서버 종료
```bash
Ctrl + C                           # API 서버 중지
exit                               # WSL 종료
```

---

## 자주 쓰는 명령어

### PowerShell에서

| 명령어 | 설명 |
|--------|------|
| `wsl -l -v` | 설치된 WSL 목록 |
| `wsl -d AlmaLinux-Kitten-10` | WSL 접속 |
| `wsl --shutdown` | 모든 WSL 종료 |
| `wsl -t AlmaLinux-Kitten-10` | AlmaLinux만 종료 |

### WSL 내부에서

| 명령어 | 설명 |
|--------|------|
| `podman ps` | 실행 중인 컨테이너 |
| `podman ps -a` | 모든 컨테이너 |
| `podman logs timingle-postgres` | PostgreSQL 로그 |
| `podman logs timingle-scylla` | ScyllaDB 로그 |
| `podman stop timingle-postgres` | 컨테이너 중지 |
| `podman start timingle-postgres` | 컨테이너 시작 |
| `podman rm -af` | 모든 컨테이너 삭제 |

---

## VSCode 연동

### 설정 (처음 한 번)

1. VSCode에서 `Ctrl + Shift + X`
2. "WSL" 검색 → Microsoft 제작 확장 설치

### WSL에 연결하기

**방법 1**: VSCode 좌측 하단 녹색 `><` 클릭 → "Connect to WSL..."

**방법 2**: `Ctrl + Shift + P` → "WSL: Connect to WSL"

**방법 3**: WSL 터미널에서
```bash
code ~/projects/timingle2/backend
```

---

## 파일 경로

### Windows ↔ WSL 변환

| Windows | WSL |
|---------|-----|
| `D:\projects\timingle2` | `/mnt/d/projects/timingle2` |
| `C:\Users\사용자명` | `/mnt/c/Users/사용자명` |

### 프로젝트 위치

| 용도 | 경로 |
|------|------|
| Windows 원본 | `D:\projects\timingle2` |
| WSL Backend | `~/projects/timingle2` |
| Flutter | `D:\projects\timingle2\frontend` |

### 파일 탐색기에서 WSL 접근

주소창에 입력:
```
\\wsl$\AlmaLinux-Kitten-10\root\projects\timingle2
```

---

## 문제 해결

### WSL이 시작되지 않음

```powershell
# PowerShell (관리자)
wsl --update
wsl --shutdown
wsl -d AlmaLinux-Kitten-10
```

### nftables 오류 (컨테이너 시작 실패)

**증상**:
```
Error: unable to start container: netavark: nftables error
```

**원인**: WSL2 커널이 nftables를 완전히 지원하지 않음

**해결**: `network_mode: host` 사용 (이미 `podman-compose-wsl.yml`에 적용됨)

### ScyllaDB 연결 실패

**증상**:
```
gocql: unable to dial control conn 127.0.0.1:9042
```

**원인**: ScyllaDB가 127.0.1.1에 바인딩됨

**해결**: 명시적 주소 설정 (이미 설정됨)
```bash
# 확인
ss -tlnp | grep 9042
# 출력이 0.0.0.0:9042 이어야 함
```

### Keyspace 없음 오류

**증상**:
```
Keyspace 'timingle' does not exist
```

**해결**:
```bash
podman exec timingle-scylla cqlsh -e "
  CREATE KEYSPACE IF NOT EXISTS timingle
  WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};
"
```

### 컨테이너가 실행되지 않음

```bash
# 상태 확인
podman ps -a

# 모두 삭제 후 재시작
podman rm -af
bash /mnt/d/projects/timingle2/containers/setup_podman.sh
```

### localhost:8080 연결 안됨

```bash
# API 서버 실행 확인
curl http://localhost:8080/health

# 서버 재시작
bash /mnt/d/projects/timingle2/backend/run.sh
```

### WSL 메모리 과다 사용

`C:\Users\사용자명\.wslconfig` 생성:
```ini
[wsl2]
memory=4GB
processors=2
```

적용:
```powershell
wsl --shutdown
wsl -d AlmaLinux-Kitten-10
```

### PowerShell PATH 오류

**증상**:
```
bash: syntax error near unexpected token `('
```

**원인**: Windows PATH의 괄호가 bash 문법 오류 유발

**해결**: 스크립트 파일 사용 (이미 `build.sh`, `run.sh` 있음)

---

## 초기 설정

### Go 설치
```bash
cd /tmp
curl -LO https://go.dev/dl/go1.25.5.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.25.5.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
go version
```

### Podman + podman-compose 설치
```bash
sudo dnf install -y podman python3-pip
pip3 install --user podman-compose
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc
podman --version
~/.local/bin/podman-compose --version
```

### systemd 활성화

`/etc/wsl.conf`:
```ini
[boot]
systemd=true
```

---

## 일상 개발 흐름

### 아침 (시작)

```powershell
# 1. WSL 접속
wsl -d AlmaLinux-Kitten-10

# 2. 서버 시작
bash /mnt/d/projects/timingle2/containers/setup_podman.sh
bash /mnt/d/projects/timingle2/backend/run.sh

# 3. 새 터미널에서 Flutter (Windows)
cd D:\projects\timingle2\frontend
flutter run
```

### 저녁 (종료)

```bash
Ctrl + C  # API 서버 중지
exit      # WSL 종료
```

---

## 포트 정보

| 서비스 | 포트 |
|--------|------|
| API 서버 | 8080 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| NATS | 4222 |
| NATS Monitor | 8222 |
| ScyllaDB | 9042 |

---

## 환경 정보

- **WSL 배포판**: AlmaLinux-Kitten-10
- **Podman**: 5.6.0
- **podman-compose**: 1.5.0
- **Go**: 1.25.5

---

**마지막 업데이트**: 2026-01-09
