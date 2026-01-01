# Go Troubleshooting

**Go 관련 문제 해결**

---

## ❌ 문제 1: go: command not found

### 해결 방법

```bash
# PATH에 Go 추가
export PATH=$PATH:/usr/local/go/bin

# 영구 적용
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bash_profile
source ~/.bash_profile

# 확인
go version
```

---

## ❌ 문제 2: package not found

### 증상
```
package github.com/gin-gonic/gin: cannot find package
```

### 해결 방법

```bash
cd /home/khchoi/projects/timingle2/backend

# 모듈 정리
go mod tidy

# 캐시 클리어
go clean -modcache

# 의존성 다운로드
go mod download

# 확인
go list -m all
```

---

## ❌ 문제 3: 빌드 오류

### 해결 방법

```bash
# Go 버전 확인 (1.22+ 필요)
go version

# 모듈 초기화 확인
ls go.mod go.sum

# 의존성 재설치
export PATH=$PATH:/usr/local/go/bin
go get -u github.com/gin-gonic/gin
go mod tidy
```

---

**마지막 업데이트**: 2025-12-31
