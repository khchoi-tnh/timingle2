# 인증 시스템 서버 코드 분석

> 회원가입, 로그인, JWT 토큰, 인증 미들웨어 전체 분석
> Google OAuth 로그인은 [google-login.md](google-login.md) 참조

---

## 개요

timingle의 인증 시스템은 **전화번호 기반 인증 + JWT 토큰** 방식입니다.

| 기능 | 엔드포인트 | 인증 |
|------|-----------|------|
| 회원가입 | `POST /api/v1/auth/register` | Public |
| 로그인 | `POST /api/v1/auth/login` | Public |
| 토큰 갱신 | `POST /api/v1/auth/refresh` | Public |
| 로그아웃 | `POST /api/v1/auth/logout` | Protected |
| 내 정보 | `GET /api/v1/auth/me` | Protected |

---

## 파일 구조

| 레이어 | 파일 | 역할 |
|--------|------|------|
| Handler | `internal/handlers/auth_handler.go` | HTTP 요청 처리 |
| Service | `internal/services/auth_service.go` | 비즈니스 로직 |
| Repository | `internal/repositories/auth_repository.go` | Refresh Token DB |
| Repository | `internal/repositories/user_repository.go` | 사용자 DB |
| Model | `internal/models/auth.go` | 인증 데이터 구조 |
| Model | `internal/models/user.go` | 사용자 데이터 구조 |
| Middleware | `internal/middleware/auth.go` | JWT 검증 미들웨어 |
| Utility | `pkg/utils/jwt.go` | JWT 생성/검증 |

---

## API 엔드포인트

### 1. 회원가입

```http
POST /api/v1/auth/register
Content-Type: application/json

{ "phone": "01012345678", "name": "홍길동" }
```

**Response (201):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "a1b2c3d4e5f6...",
  "expires_in": 3600,
  "user": { "id": 1, "phone": "01012345678", "name": "홍길동", "role": "USER" }
}
```

### 2. 로그인

```http
POST /api/v1/auth/login
Content-Type: application/json

{ "phone": "01012345678" }
```

**Response (200):** 회원가입과 동일한 형식

### 3. 토큰 갱신

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{ "refresh_token": "a1b2c3d4e5f6..." }
```

**Response (200):** 새 access_token + 동일 refresh_token

### 4. 로그아웃

```http
POST /api/v1/auth/logout
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

**Response (200):**
```json
{ "message": "logged out successfully" }
```

### 5. 내 정보

```http
GET /api/v1/auth/me
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

**Response (200):**
```json
{
  "id": 1, "phone": "01012345678", "name": "홍길동",
  "email": null, "timezone": "UTC", "language": "ko", "role": "USER"
}
```

---

## JWT 토큰 구조

### Access Token (HS256)

```json
// Header
{ "alg": "HS256", "typ": "JWT" }

// Payload (Claims)
{
  "user_id": 1,
  "phone": "01012345678",
  "role": "USER",
  "exp": 1709899600,    // 만료 시간
  "iat": 1709896000,    // 발급 시간
  "nbf": 1709896000,    // 유효 시작 시간
  "iss": "timingle",    // 발급자
  "sub": "1"            // 사용자 ID
}
```

### Refresh Token

```
랜덤 32바이트 → Base64 URL 인코딩
예: "dGhpcyBpcyBhIHJhbmRvbSB0b2tlbg=="
```

### 토큰 수명

| 토큰 | 수명 | 저장 위치 |
|------|------|----------|
| Access Token | 설정값 (기본 1시간) | 클라이언트 메모리 |
| Refresh Token | 설정값 (기본 30일) | PostgreSQL DB |

---

## 코드 상세 분석

### Handler Layer

```go
// Register - 회원가입
func (h *AuthHandler) Register(c *gin.Context) {
    var req models.RegisterRequest            // { phone, name }
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    response, err := h.authService.Register(&req)
    if err != nil {
        c.JSON(400, gin.H{"error": err.Error()})
        return
    }
    c.JSON(201, response)                     // AuthResponse
}

// Login - 로그인
func (h *AuthHandler) Login(c *gin.Context) {
    var req models.LoginRequest               // { phone }
    // ... ShouldBindJSON → authService.Login → 200 or 401
}

// RefreshToken - 토큰 갱신
func (h *AuthHandler) RefreshToken(c *gin.Context) {
    var req models.RefreshTokenRequest        // { refresh_token }
    // ... ShouldBindJSON → authService.RefreshToken → 200 or 401
}

// Logout - 로그아웃 (Protected)
func (h *AuthHandler) Logout(c *gin.Context) {
    userID, _ := c.Get("userID")              // 미들웨어에서 설정
    h.authService.Logout(userID.(int64))
}

// Me - 내 정보 (Protected)
func (h *AuthHandler) Me(c *gin.Context) {
    user, _ := c.Get("user")                  // 미들웨어에서 설정
    c.JSON(200, user.(*models.User).ToUserResponse())
}
```

### Service Layer

```go
// Register - 회원가입
func (s *AuthService) Register(req *models.RegisterRequest) (*models.AuthResponse, error) {
    // 1. 중복 확인
    existingUser, _ := s.userRepo.FindByPhone(req.Phone)
    if existingUser != nil {
        return nil, fmt.Errorf("user with this phone already exists")
    }

    // 2. 사용자 생성
    user := &models.User{
        Phone: req.Phone, Name: &req.Name,
        Timezone: "UTC", Language: "ko", Role: models.UserRoleUser,
    }
    s.userRepo.Create(user)

    // 3. JWT 토큰 발급
    return s.generateAuthResponse(user)
}

// Login - 로그인
func (s *AuthService) Login(req *models.LoginRequest) (*models.AuthResponse, error) {
    user, err := s.userRepo.FindByPhone(req.Phone)
    if err != nil { return nil, fmt.Errorf("invalid phone number") }
    // 참고: 프로덕션에서는 SMS 인증 코드 검증 필요
    return s.generateAuthResponse(user)
}

// RefreshToken - 토큰 갱신
func (s *AuthService) RefreshToken(req *models.RefreshTokenRequest) (*models.AuthResponse, error) {
    // 1. DB에서 Refresh Token 조회
    refreshToken, err := s.authRepo.FindRefreshToken(req.RefreshToken)
    // 2. 만료 확인
    if time.Now().After(refreshToken.ExpiresAt) {
        s.authRepo.DeleteRefreshToken(req.RefreshToken)
        return nil, fmt.Errorf("refresh token expired")
    }
    // 3. 새 Access Token만 발급 (Refresh Token은 유지)
    accessToken, _ := s.jwtManager.GenerateAccessToken(user)
    return &models.AuthResponse{
        AccessToken: accessToken,
        RefreshToken: req.RefreshToken,  // 동일 Refresh Token 반환
        ExpiresIn: int64(s.jwtManager.GetAccessExpiry().Seconds()),
        User: user.ToUserResponse(),
    }, nil
}

// generateAuthResponse - JWT 토큰 쌍 생성
func (s *AuthService) generateAuthResponse(user *models.User) (*models.AuthResponse, error) {
    accessToken, _ := s.jwtManager.GenerateAccessToken(user)   // JWT
    refreshTokenStr, _ := s.jwtManager.GenerateRefreshToken()  // 랜덤 문자열
    // DB에 Refresh Token 저장
    s.authRepo.SaveRefreshToken(&models.RefreshToken{
        UserID: user.ID, Token: refreshTokenStr,
        ExpiresAt: time.Now().Add(s.jwtManager.GetRefreshExpiry()),
    })
    return &models.AuthResponse{...}, nil
}
```

### JWT Manager

```go
type JWTManager struct {
    secret        string        // HS256 서명 키
    accessExpiry  time.Duration // Access Token 수명
    refreshExpiry time.Duration // Refresh Token 수명
}

// Access Token 생성 (HS256 JWT)
func (m *JWTManager) GenerateAccessToken(user *models.User) (string, error) {
    claims := Claims{
        UserID: user.ID, Phone: user.Phone, Role: user.Role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(m.accessExpiry)),
            Issuer: "timingle",
            Subject: fmt.Sprintf("%d", user.ID),
        },
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(m.secret))
}

// Refresh Token 생성 (32바이트 랜덤)
func (m *JWTManager) GenerateRefreshToken() (string, error) {
    b := make([]byte, 32)
    rand.Read(b)
    return base64.URLEncoding.EncodeToString(b), nil
}

// Access Token 검증
func (m *JWTManager) ValidateAccessToken(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method")
        }
        return []byte(m.secret), nil
    })
    // ... claims 추출 및 반환
}
```

### Auth Middleware

```go
func AuthMiddleware(jwtManager *utils.JWTManager, userRepo *repositories.UserRepository) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. Authorization 헤더 추출
        authHeader := c.GetHeader("Authorization")
        // "Bearer eyJhbGciOiJIUzI1NiIs..." → ["Bearer", "eyJ..."]

        // 2. JWT 검증
        claims, err := jwtManager.ValidateAccessToken(parts[1])
        if err != nil {
            c.JSON(401, gin.H{"error": "invalid or expired token"})
            c.Abort()
            return
        }

        // 3. DB에서 사용자 로드
        user, err := userRepo.FindByID(claims.UserID)

        // 4. Context에 사용자 정보 설정
        c.Set("userID", user.ID)   // int64
        c.Set("user", user)        // *models.User
        c.Set("role", user.Role)   // models.UserRole

        c.Next()
    }
}
```

---

## 인증 흐름 다이어그램

```mermaid
sequenceDiagram
    participant 📱 as Flutter
    participant 🖥️ as Backend
    participant 🗄️ as PostgreSQL

    Note over 📱,🗄️: 회원가입

    📱->>🖥️: POST /auth/register { phone, name }
    🖥️->>🗄️: FindByPhone(phone) → null
    🖥️->>🗄️: INSERT INTO users
    🖥️->>🖥️: GenerateAccessToken (JWT)
    🖥️->>🖥️: GenerateRefreshToken (random)
    🖥️->>🗄️: INSERT INTO refresh_tokens
    🖥️-->>📱: { access_token, refresh_token, user }

    Note over 📱,🗄️: 로그인

    📱->>🖥️: POST /auth/login { phone }
    🖥️->>🗄️: FindByPhone(phone) → User
    🖥️->>🖥️: GenerateAccessToken + RefreshToken
    🖥️->>🗄️: INSERT INTO refresh_tokens
    🖥️-->>📱: { access_token, refresh_token, user }

    Note over 📱,🗄️: Protected API 호출

    📱->>🖥️: GET /auth/me (Authorization: Bearer ...)
    🖥️->>🖥️: AuthMiddleware: ValidateAccessToken
    🖥️->>🗄️: FindByID(claims.UserID)
    🖥️->>🖥️: c.Set("userID", "user", "role")
    🖥️-->>📱: { user info }

    Note over 📱,🗄️: 토큰 갱신

    📱->>🖥️: POST /auth/refresh { refresh_token }
    🖥️->>🗄️: FindRefreshToken(token) → valid
    🖥️->>🗄️: FindByID(userID) → User
    🖥️->>🖥️: GenerateAccessToken (새 JWT)
    🖥️-->>📱: { new access_token, same refresh_token }
```

---

## 데이터 모델

### User

```go
type User struct {
    ID              int64    // PK
    Phone           string   // unique, 필수
    Name            *string  // nullable
    Email           *string  // nullable
    ProfileImageURL *string  // nullable
    Region          *string  // nullable
    Interests       []string // nullable
    Timezone        string   // default: "UTC"
    Language        string   // default: "ko"
    Role            UserRole // "USER" | "BUSINESS"
}
```

### RefreshToken

```go
type RefreshToken struct {
    ID        int64
    UserID    int64     // FK → users.id
    Token     string    // 랜덤 32바이트 base64
    ExpiresAt time.Time // 만료 시간
}
```

---

## 에러 처리

| 상황 | HTTP | 메시지 |
|------|------|--------|
| phone 누락 | 400 | `Key: 'RegisterRequest.Phone'...` |
| 이미 가입된 번호 | 400 | `user with this phone already exists` |
| 존재하지 않는 번호로 로그인 | 401 | `invalid phone number` |
| Authorization 헤더 누락 | 401 | `authorization header required` |
| 잘못된 Bearer 형식 | 401 | `invalid authorization header format` |
| JWT 만료/변조 | 401 | `invalid or expired token` |
| Refresh Token 만료 | 401 | `refresh token expired` |

---

## 보안

- HS256 서명으로 JWT 변조 방지
- Refresh Token은 DB 저장 (서버 측 무효화 가능)
- 로그아웃 시 모든 Refresh Token 삭제
- 비밀번호 없음 (전화번호 + SMS 인증 방식, 현재 개발 중)

---

## 관련 문서

- [Google 로그인](google-login.md) - Google OAuth 인증
- [이벤트 관리](events.md) - Protected API 사용 예시
- [전체 인덱스](README.md)

---

**작성일:** 2026-02-19
