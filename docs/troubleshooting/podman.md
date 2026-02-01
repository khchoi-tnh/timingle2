# Podman Troubleshooting

**Podman 관련 문제 해결**

---

## ❌ 문제 1: podman-compose: command not found

### 해결 방법
```bash
# Rocky Linux 9 / RHEL 9
sudo dnf install -y podman podman-compose

# 또는 pip로 설치
pip3 install podman-compose

# 설치 확인
podman-compose --version
```

---

## ❌ 문제 2: Permission denied (SELinux)

### 증상
```
Error: error mounting volume: permission denied
```

### 해결 방법

```yaml
# 볼륨 마운트 시 :Z 플래그 추가
volumes:
  - postgres_data:/var/lib/postgresql/data:Z
  - scylla_data:/var/lib/scylla:Z
```

**:Z 플래그 설명**:
- SELinux 컨텍스트를 private unshared label로 설정
- Podman에서 권장하는 방법
- 컨테이너별로 독립적인 권한

---

## ❌ 문제 3: 컨테이너 간 통신 불가

### 증상
```
Error: could not resolve host: timingle-postgres
```

### 해결 방법

```yaml
# podman-compose.yml에 명시적 네트워크 설정
networks:
  default:
    name: timingle-network
```

```bash
# 네트워크 확인
podman network ls
podman network inspect timingle-network
```

---

## ❌ 문제 4: WSL에서 nftables 오류

### 증상
```
Error: unable to start container: netavark: nftables error:
"nft" did not return successfully while applying ruleset
```

### 원인
- WSL2 커널이 nftables 커널 모듈을 완전히 지원하지 않음
- Podman 5.x는 기본적으로 netavark + nftables 사용

### 해결 방법
**`network_mode: host`** 사용 → 자세한 내용은 [WSL 문제 해결](./wsl.md) 참조

---

## ❌ 문제 5: podman-compose PATH 문제 (pip 설치 시)

### 증상
```
WARNING: The script podman-compose is installed in '/root/.local/bin' which is not on PATH.
```

### 해결 방법
```bash
# PATH에 추가
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
source ~/.bashrc

# 또는 전체 경로 사용
~/.local/bin/podman-compose up -d
```

---

**마지막 업데이트**: 2026-01-07
