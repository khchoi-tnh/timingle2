# Phase 1: Backend 핵심 구현 (Week 1)

**목표**: Go 백엔드 핵심 기능 구축 - 인증, 이벤트 CRUD, 기본 API

**소요 시간**: 5-7일

**완료 조건**:
- ✅ Go 프로젝트 구조 생성 완료
- ✅ PostgreSQL 마이그레이션 완료
- ✅ JWT 인증 시스템 동작
- ✅ 이벤트 CRUD API 동작
- ✅ Postman/cURL로 모든 엔드포인트 테스트 완료

---

## 📋 사전 준비사항

### 완료 확인
- [ ] PHASE_0_SETUP.md 완료 (컨테이너 실행 중)
- [ ] Go 1.22+ 설치 완료
- [ ] PostgreSQL, Redis 컨테이너 정상 동작

### 확인 명령
```bash
# Go 버전 확인
go version  # go1.22.0 이상

# 컨테이너 상태 확인
cd /home/khchoi/projects/timingle2/containers
podman-compose ps

# PostgreSQL 접속 확인
podman exec -it timingle-postgres psql -U timingle -d timingle -c "SELECT version();"

# Redis 접속 확인
podman exec -it timingle-redis redis-cli ping
```

---

## 🏗️ Step 1: Go 프로젝트 구조 생성

### 1.1 디렉토리 생성
```bash
cd /home/khchoi/projects/timingle2

# Backend 디렉토리 구조 생성
mkdir -p backend/{cmd/{api,gateway,worker},internal/{config,db,models,repositories,services,handlers,middleware,websocket},migrations,pkg/utils}

# 구조 확인
tree backend -L 3
```

**예상 출력**:
```
backend/
├── cmd/
│   ├── api/          # REST API 서버
│   ├── gateway/      # WebSocket Gateway
│   └── worker/       # NATS Consumer
├── internal/
│   ├── config/       # 설정 로드
│   ├── db/           # DB 연결
│   ├── models/       # 데이터 모델
│   ├── repositories/ # DB 쿼리 레이어
│   ├── services/     # 비즈니스 로직
│   ├── handlers/     # HTTP 핸들러
│   ├── middleware/   # 인증, 로깅
│   └── websocket/    # WebSocket 관리
├── migrations/       # DB 마이그레이션
└── pkg/
    └── utils/        # 공통 유틸리티
```

### 1.2 Go 모듈 초기화
```bash
cd backend

# Go 모듈 초기화
go mod init github.com/yourusername/timingle

# 기본 의존성 설치
go get -u github.com/gin-gonic/gin
go get -u github.com/lib/pq                    # PostgreSQL 드라이버
go get -u github.com/go-redis/redis/v8
go get -u github.com/golang-jwt/jwt/v5
go get -u github.com/joho/godotenv              # .env 로드
go get -u github.com/gorilla/websocket
go get -u github.com/nats-io/nats.go
go get -u github.com/gocql/gocql                # ScyllaDB 드라이버
go get -u golang.org/x/crypto/bcrypt
go get -u github.com/google/uuid

# 개발 도구
go get -u github.com/swaggo/swag/cmd/swag       # API 문서 생성
go get -u github.com/cosmtrek/air               # Hot reload

# go.mod 정리
go mod tidy
```

### 1.3 환경변수 파일 생성
```bash
# backend/.env 파일 생성
cat > .env << 'EOF'
# Server
PORT=8080
GIN_MODE=debug

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=timingle
POSTGRES_PASSWORD=timingle_dev_password
POSTGRES_DB=timingle

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# NATS
NATS_URL=nats://localhost:4222

# ScyllaDB
SCYLLA_HOSTS=localhost
SCYLLA_KEYSPACE=timingle
SCYLLA_CONSISTENCY=QUORUM

# JWT
JWT_SECRET=your-secret-key-change-this-in-production
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# External APIs (나중에 설정)
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
PHONE_VERIFY_API_KEY=
EOF

echo "✅ backend/.env 파일 생성 완료"
```

---

## 🗄️ Step 2: 데이터베이스 마이그레이션

### 2.1 마이그레이션 파일 생성

#### migrations/001_create_users_table.sql
```bash
cat > migrations/001_create_users_table.sql << 'EOF'
-- 사용자 테이블
CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  phone VARCHAR(20) UNIQUE NOT NULL,
  name VARCHAR(100),
  email VARCHAR(255),
  profile_image_url TEXT,
  region VARCHAR(50),
  interests TEXT[],
  role VARCHAR(20) DEFAULT 'USER' CHECK (role IN ('USER', 'BUSINESS')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_region ON users(region);
CREATE INDEX idx_users_role ON users(role);

-- 업데이트 시간 자동 갱신 트리거
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
EOF
```

#### migrations/002_create_events_table.sql
```bash
cat > migrations/002_create_events_table.sql << 'EOF'
-- 이벤트 테이블
CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL,
  location VARCHAR(200),
  creator_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  status VARCHAR(20) DEFAULT 'PROPOSED' CHECK (status IN ('PROPOSED', 'CONFIRMED', 'CANCELED', 'DONE')),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_events_creator_id ON events(creator_id);
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_creator_status ON events(creator_id, status);

-- 업데이트 시간 자동 갱신
CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
EOF
```

#### migrations/003_create_event_participants_table.sql
```bash
cat > migrations/003_create_event_participants_table.sql << 'EOF'
-- 이벤트 참여자 테이블
CREATE TABLE IF NOT EXISTS event_participants (
  event_id BIGINT REFERENCES events(id) ON DELETE CASCADE,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  confirmed BOOLEAN DEFAULT FALSE,
  confirmed_at TIMESTAMP,
  PRIMARY KEY (event_id, user_id)
);

-- 인덱스
CREATE INDEX idx_event_participants_user_id ON event_participants(user_id);
CREATE INDEX idx_event_participants_event_confirmed ON event_participants(event_id, confirmed);
EOF
```

#### migrations/004_create_refresh_tokens_table.sql
```bash
cat > migrations/004_create_refresh_tokens_table.sql << 'EOF'
-- Refresh Token 테이블
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
EOF
```

### 2.2 마이그레이션 실행 스크립트
```bash
cat > migrations/migrate.sh << 'EOF'
#!/bin/bash

set -e

POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-timingle}"
POSTGRES_DB="${POSTGRES_DB:-timingle}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-timingle_dev_password}"

MIGRATION_DIR="$(dirname "$0")"

echo "🚀 Running migrations on ${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}..."

for file in $(ls -v ${MIGRATION_DIR}/*.sql 2>/dev/null); do
  echo "📄 Applying $(basename $file)..."
  PGPASSWORD="${POSTGRES_PASSWORD}" psql -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -f "$file"
done

echo "✅ All migrations applied successfully!"
EOF

chmod +x migrations/migrate.sh
```

### 2.3 마이그레이션 실행
```bash
cd backend

# 환경변수 로드 후 마이그레이션 실행
export $(cat .env | grep -v '^#' | xargs)
./migrations/migrate.sh
```

**예상 출력**:
```
🚀 Running migrations on localhost:5432/timingle...
📄 Applying 001_create_users_table.sql...
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE FUNCTION
CREATE TRIGGER
📄 Applying 002_create_events_table.sql...
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE INDEX
CREATE TRIGGER
📄 Applying 003_create_event_participants_table.sql...
CREATE TABLE
CREATE INDEX
CREATE INDEX
📄 Applying 004_create_refresh_tokens_table.sql...
CREATE TABLE
CREATE INDEX
CREATE INDEX
CREATE INDEX
✅ All migrations applied successfully!
```

### 2.4 테이블 확인
```bash
podman exec -it timingle-postgres psql -U timingle -d timingle -c "\dt"
```

**예상 출력**:
```
                 List of relations
 Schema |         Name          | Type  |  Owner
--------+-----------------------+-------+----------
 public | event_participants    | table | timingle
 public | events                | table | timingle
 public | refresh_tokens        | table | timingle
 public | users                 | table | timingle
```

---

## 🔧 Step 3: Config 및 Database 연결

### 3.1 internal/config/config.go
```bash
cat > internal/config/config.go << 'EOF'
package config

import (
	"fmt"
	"os"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Server   ServerConfig
	Postgres PostgresConfig
	Redis    RedisConfig
	NATS     NATSConfig
	Scylla   ScyllaConfig
	JWT      JWTConfig
}

type ServerConfig struct {
	Port    string
	GinMode string
}

type PostgresConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	Database string
}

type RedisConfig struct {
	Host     string
	Port     string
	Password string
}

type NATSConfig struct {
	URL string
}

type ScyllaConfig struct {
	Hosts       []string
	Keyspace    string
	Consistency string
}

type JWTConfig struct {
	Secret        string
	AccessExpiry  time.Duration
	RefreshExpiry time.Duration
}

func Load() (*Config, error) {
	// .env 파일 로드 (개발 환경)
	_ = godotenv.Load()

	cfg := &Config{
		Server: ServerConfig{
			Port:    getEnv("PORT", "8080"),
			GinMode: getEnv("GIN_MODE", "debug"),
		},
		Postgres: PostgresConfig{
			Host:     getEnv("POSTGRES_HOST", "localhost"),
			Port:     getEnv("POSTGRES_PORT", "5432"),
			User:     getEnv("POSTGRES_USER", "timingle"),
			Password: getEnv("POSTGRES_PASSWORD", "timingle_dev_password"),
			Database: getEnv("POSTGRES_DB", "timingle"),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
		},
		NATS: NATSConfig{
			URL: getEnv("NATS_URL", "nats://localhost:4222"),
		},
		Scylla: ScyllaConfig{
			Hosts:       []string{getEnv("SCYLLA_HOSTS", "localhost")},
			Keyspace:    getEnv("SCYLLA_KEYSPACE", "timingle"),
			Consistency: getEnv("SCYLLA_CONSISTENCY", "QUORUM"),
		},
		JWT: JWTConfig{
			Secret:        getEnv("JWT_SECRET", "your-secret-key"),
			AccessExpiry:  parseDuration(getEnv("JWT_ACCESS_EXPIRY", "15m")),
			RefreshExpiry: parseDuration(getEnv("JWT_REFRESH_EXPIRY", "168h")), // 7d
		},
	}

	return cfg, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func parseDuration(s string) time.Duration {
	d, err := time.ParseDuration(s)
	if err != nil {
		return 15 * time.Minute
	}
	return d
}

func (c *PostgresConfig) DSN() string {
	return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		c.Host, c.Port, c.User, c.Password, c.Database)
}

func (c *RedisConfig) Addr() string {
	return fmt.Sprintf("%s:%s", c.Host, c.Port)
}
EOF
```

### 3.2 internal/db/postgres.go
```bash
cat > internal/db/postgres.go << 'EOF'
package db

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

type PostgresDB struct {
	*sql.DB
}

func NewPostgresDB(dsn string) (*PostgresDB, error) {
	db, err := sql.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// 연결 테스트
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// 연결 풀 설정
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	log.Println("✅ PostgreSQL connected successfully")

	return &PostgresDB{DB: db}, nil
}

func (db *PostgresDB) Close() error {
	log.Println("🔌 Closing PostgreSQL connection...")
	return db.DB.Close()
}
EOF
```

### 3.3 internal/db/redis.go
```bash
cat > internal/db/redis.go << 'EOF'
package db

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/go-redis/redis/v8"
)

type RedisClient struct {
	*redis.Client
}

func NewRedisClient(addr, password string) (*RedisClient, error) {
	client := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		DB:           0,
		DialTimeout:  5 * time.Second,
		ReadTimeout:  3 * time.Second,
		WriteTimeout: 3 * time.Second,
		PoolSize:     10,
	})

	// 연결 테스트
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to ping redis: %w", err)
	}

	log.Println("✅ Redis connected successfully")

	return &RedisClient{Client: client}, nil
}

func (r *RedisClient) Close() error {
	log.Println("🔌 Closing Redis connection...")
	return r.Client.Close()
}
EOF
```

---

## 📦 Step 4: Models 정의

### 4.1 internal/models/user.go
```bash
cat > internal/models/user.go << 'EOF'
package models

import "time"

type User struct {
	ID              int64     `json:"id" db:"id"`
	Phone           string    `json:"phone" db:"phone"`
	Name            string    `json:"name" db:"name"`
	Email           string    `json:"email" db:"email"`
	ProfileImageURL string    `json:"profile_image_url" db:"profile_image_url"`
	Region          string    `json:"region" db:"region"`
	Interests       []string  `json:"interests" db:"interests"`
	Role            string    `json:"role" db:"role"` // USER, BUSINESS
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
}

type CreateUserRequest struct {
	Phone           string   `json:"phone" binding:"required"`
	Name            string   `json:"name" binding:"required"`
	Email           string   `json:"email"`
	ProfileImageURL string   `json:"profile_image_url"`
	Region          string   `json:"region"`
	Interests       []string `json:"interests"`
}

type UpdateUserRequest struct {
	Name            *string   `json:"name"`
	Email           *string   `json:"email"`
	ProfileImageURL *string   `json:"profile_image_url"`
	Region          *string   `json:"region"`
	Interests       *[]string `json:"interests"`
}
EOF
```

### 4.2 internal/models/event.go
```bash
cat > internal/models/event.go << 'EOF'
package models

import "time"

type EventStatus string

const (
	EventStatusProposed  EventStatus = "PROPOSED"
	EventStatusConfirmed EventStatus = "CONFIRMED"
	EventStatusCanceled  EventStatus = "CANCELED"
	EventStatusDone      EventStatus = "DONE"
)

type Event struct {
	ID          int64       `json:"id" db:"id"`
	Title       string      `json:"title" db:"title"`
	Description string      `json:"description" db:"description"`
	StartTime   time.Time   `json:"start_time" db:"start_time"`
	EndTime     time.Time   `json:"end_time" db:"end_time"`
	Location    string      `json:"location" db:"location"`
	CreatorID   int64       `json:"creator_id" db:"creator_id"`
	Status      EventStatus `json:"status" db:"status"`
	CreatedAt   time.Time   `json:"created_at" db:"created_at"`
	UpdatedAt   time.Time   `json:"updated_at" db:"updated_at"`
}

type EventWithParticipants struct {
	Event
	Participants []EventParticipant `json:"participants"`
}

type EventParticipant struct {
	EventID     int64      `json:"event_id" db:"event_id"`
	UserID      int64      `json:"user_id" db:"user_id"`
	Confirmed   bool       `json:"confirmed" db:"confirmed"`
	ConfirmedAt *time.Time `json:"confirmed_at" db:"confirmed_at"`
	User        *User      `json:"user,omitempty"`
}

type CreateEventRequest struct {
	Title         string   `json:"title" binding:"required"`
	Description   string   `json:"description"`
	StartTime     string   `json:"start_time" binding:"required"` // RFC3339 format
	EndTime       string   `json:"end_time" binding:"required"`
	Location      string   `json:"location"`
	ParticipantIDs []int64 `json:"participant_ids"` // 초대할 사용자 IDs
}

type UpdateEventRequest struct {
	Title       *string `json:"title"`
	Description *string `json:"description"`
	StartTime   *string `json:"start_time"` // RFC3339 format
	EndTime     *string `json:"end_time"`
	Location    *string `json:"location"`
	Status      *string `json:"status"` // PROPOSED, CONFIRMED, CANCELED, DONE
}
EOF
```

### 4.3 internal/models/auth.go
```bash
cat > internal/models/auth.go << 'EOF'
package models

import "time"

type RefreshToken struct {
	ID        int64     `json:"id" db:"id"`
	UserID    int64     `json:"user_id" db:"user_id"`
	Token     string    `json:"token" db:"token"`
	ExpiresAt time.Time `json:"expires_at" db:"expires_at"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

type LoginRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"` // 인증 코드
}

type GoogleLoginRequest struct {
	IDToken string `json:"id_token" binding:"required"`
}

type TokenResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int64  `json:"expires_in"` // seconds
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}
EOF
```

---

## 🔐 Step 5: JWT 인증 시스템

### 5.1 pkg/utils/jwt.go
```bash
cat > pkg/utils/jwt.go << 'EOF'
package utils

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type Claims struct {
	UserID int64  `json:"user_id"`
	Phone  string `json:"phone"`
	Role   string `json:"role"`
	jwt.RegisteredClaims
}

func GenerateAccessToken(userID int64, phone, role, secret string, expiry time.Duration) (string, error) {
	claims := &Claims{
		UserID: userID,
		Phone:  phone,
		Role:   role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(expiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func ValidateToken(tokenString, secret string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}

	return nil, fmt.Errorf("invalid token")
}
EOF
```

### 5.2 pkg/utils/random.go
```bash
cat > pkg/utils/random.go << 'EOF'
package utils

import (
	"crypto/rand"
	"encoding/base64"
)

// GenerateRandomToken generates a random token of specified byte length
func GenerateRandomToken(length int) (string, error) {
	b := make([]byte, length)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b), nil
}
EOF
```

---

## 📂 Step 6: Repository Layer (데이터베이스 쿼리)

### 6.1 internal/repositories/user_repository.go
```bash
cat > internal/repositories/user_repository.go << 'EOF'
package repositories

import (
	"database/sql"
	"fmt"

	"github.com/lib/pq"
	"github.com/yourusername/timingle/internal/models"
)

type UserRepository struct {
	db *sql.DB
}

func NewUserRepository(db *sql.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(user *models.User) error {
	query := `
		INSERT INTO users (phone, name, email, profile_image_url, region, interests, role)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`
	return r.db.QueryRow(
		query,
		user.Phone,
		user.Name,
		user.Email,
		user.ProfileImageURL,
		user.Region,
		pq.Array(user.Interests),
		user.Role,
	).Scan(&user.ID, &user.CreatedAt, &user.UpdatedAt)
}

func (r *UserRepository) GetByID(id int64) (*models.User, error) {
	user := &models.User{}
	query := `
		SELECT id, phone, name, email, profile_image_url, region, interests, role, created_at, updated_at
		FROM users
		WHERE id = $1
	`
	err := r.db.QueryRow(query, id).Scan(
		&user.ID,
		&user.Phone,
		&user.Name,
		&user.Email,
		&user.ProfileImageURL,
		&user.Region,
		pq.Array(&user.Interests),
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	return user, err
}

func (r *UserRepository) GetByPhone(phone string) (*models.User, error) {
	user := &models.User{}
	query := `
		SELECT id, phone, name, email, profile_image_url, region, interests, role, created_at, updated_at
		FROM users
		WHERE phone = $1
	`
	err := r.db.QueryRow(query, phone).Scan(
		&user.ID,
		&user.Phone,
		&user.Name,
		&user.Email,
		&user.ProfileImageURL,
		&user.Region,
		pq.Array(&user.Interests),
		&user.Role,
		&user.CreatedAt,
		&user.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("user not found")
	}
	return user, err
}

func (r *UserRepository) Update(id int64, req *models.UpdateUserRequest) error {
	query := `
		UPDATE users
		SET name = COALESCE($1, name),
		    email = COALESCE($2, email),
		    profile_image_url = COALESCE($3, profile_image_url),
		    region = COALESCE($4, region),
		    interests = COALESCE($5, interests)
		WHERE id = $6
	`
	var interests interface{}
	if req.Interests != nil {
		interests = pq.Array(*req.Interests)
	}

	_, err := r.db.Exec(query, req.Name, req.Email, req.ProfileImageURL, req.Region, interests, id)
	return err
}
EOF
```

### 6.2 internal/repositories/event_repository.go
```bash
cat > internal/repositories/event_repository.go << 'EOF'
package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/yourusername/timingle/internal/models"
)

type EventRepository struct {
	db *sql.DB
}

func NewEventRepository(db *sql.DB) *EventRepository {
	return &EventRepository{db: db}
}

func (r *EventRepository) Create(event *models.Event) error {
	query := `
		INSERT INTO events (title, description, start_time, end_time, location, creator_id, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		RETURNING id, created_at, updated_at
	`
	return r.db.QueryRow(
		query,
		event.Title,
		event.Description,
		event.StartTime,
		event.EndTime,
		event.Location,
		event.CreatorID,
		event.Status,
	).Scan(&event.ID, &event.CreatedAt, &event.UpdatedAt)
}

func (r *EventRepository) GetByID(id int64) (*models.Event, error) {
	event := &models.Event{}
	query := `
		SELECT id, title, description, start_time, end_time, location, creator_id, status, created_at, updated_at
		FROM events
		WHERE id = $1
	`
	err := r.db.QueryRow(query, id).Scan(
		&event.ID,
		&event.Title,
		&event.Description,
		&event.StartTime,
		&event.EndTime,
		&event.Location,
		&event.CreatorID,
		&event.Status,
		&event.CreatedAt,
		&event.UpdatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("event not found")
	}
	return event, err
}

func (r *EventRepository) GetByUserID(userID int64) ([]*models.Event, error) {
	query := `
		SELECT DISTINCT e.id, e.title, e.description, e.start_time, e.end_time, e.location, e.creator_id, e.status, e.created_at, e.updated_at
		FROM events e
		LEFT JOIN event_participants ep ON e.id = ep.event_id
		WHERE e.creator_id = $1 OR ep.user_id = $1
		ORDER BY e.start_time DESC
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	events := []*models.Event{}
	for rows.Next() {
		event := &models.Event{}
		if err := rows.Scan(
			&event.ID,
			&event.Title,
			&event.Description,
			&event.StartTime,
			&event.EndTime,
			&event.Location,
			&event.CreatorID,
			&event.Status,
			&event.CreatedAt,
			&event.UpdatedAt,
		); err != nil {
			return nil, err
		}
		events = append(events, event)
	}

	return events, nil
}

func (r *EventRepository) Update(id int64, req *models.UpdateEventRequest) error {
	query := `
		UPDATE events
		SET title = COALESCE($1, title),
		    description = COALESCE($2, description),
		    start_time = COALESCE($3, start_time),
		    end_time = COALESCE($4, end_time),
		    location = COALESCE($5, location),
		    status = COALESCE($6, status)
		WHERE id = $7
	`

	var startTime, endTime interface{}
	if req.StartTime != nil {
		t, _ := time.Parse(time.RFC3339, *req.StartTime)
		startTime = t
	}
	if req.EndTime != nil {
		t, _ := time.Parse(time.RFC3339, *req.EndTime)
		endTime = t
	}

	_, err := r.db.Exec(query, req.Title, req.Description, startTime, endTime, req.Location, req.Status, id)
	return err
}

func (r *EventRepository) Delete(id int64) error {
	_, err := r.db.Exec("DELETE FROM events WHERE id = $1", id)
	return err
}

// Participants
func (r *EventRepository) AddParticipant(eventID, userID int64) error {
	query := `
		INSERT INTO event_participants (event_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (event_id, user_id) DO NOTHING
	`
	_, err := r.db.Exec(query, eventID, userID)
	return err
}

func (r *EventRepository) GetParticipants(eventID int64) ([]*models.EventParticipant, error) {
	query := `
		SELECT ep.event_id, ep.user_id, ep.confirmed, ep.confirmed_at,
		       u.id, u.phone, u.name, u.profile_image_url
		FROM event_participants ep
		JOIN users u ON ep.user_id = u.id
		WHERE ep.event_id = $1
	`
	rows, err := r.db.Query(query, eventID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	participants := []*models.EventParticipant{}
	for rows.Next() {
		p := &models.EventParticipant{User: &models.User{}}
		if err := rows.Scan(
			&p.EventID,
			&p.UserID,
			&p.Confirmed,
			&p.ConfirmedAt,
			&p.User.ID,
			&p.User.Phone,
			&p.User.Name,
			&p.User.ProfileImageURL,
		); err != nil {
			return nil, err
		}
		participants = append(participants, p)
	}

	return participants, nil
}

func (r *EventRepository) ConfirmParticipant(eventID, userID int64) error {
	query := `
		UPDATE event_participants
		SET confirmed = TRUE, confirmed_at = NOW()
		WHERE event_id = $1 AND user_id = $2
	`
	_, err := r.db.Exec(query, eventID, userID)
	return err
}
EOF
```

### 6.3 internal/repositories/auth_repository.go
```bash
cat > internal/repositories/auth_repository.go << 'EOF'
package repositories

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/yourusername/timingle/internal/models"
)

type AuthRepository struct {
	db *sql.DB
}

func NewAuthRepository(db *sql.DB) *AuthRepository {
	return &AuthRepository{db: db}
}

func (r *AuthRepository) SaveRefreshToken(userID int64, token string, expiresAt time.Time) error {
	query := `
		INSERT INTO refresh_tokens (user_id, token, expires_at)
		VALUES ($1, $2, $3)
	`
	_, err := r.db.Exec(query, userID, token, expiresAt)
	return err
}

func (r *AuthRepository) GetRefreshToken(token string) (*models.RefreshToken, error) {
	rt := &models.RefreshToken{}
	query := `
		SELECT id, user_id, token, expires_at, created_at
		FROM refresh_tokens
		WHERE token = $1 AND expires_at > NOW()
	`
	err := r.db.QueryRow(query, token).Scan(
		&rt.ID,
		&rt.UserID,
		&rt.Token,
		&rt.ExpiresAt,
		&rt.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("refresh token not found or expired")
	}
	return rt, err
}

func (r *AuthRepository) DeleteRefreshToken(token string) error {
	_, err := r.db.Exec("DELETE FROM refresh_tokens WHERE token = $1", token)
	return err
}

func (r *AuthRepository) DeleteUserRefreshTokens(userID int64) error {
	_, err := r.db.Exec("DELETE FROM refresh_tokens WHERE user_id = $1", userID)
	return err
}
EOF
```

---

## 🧩 Step 7: Service Layer (비즈니스 로직)

### 7.1 internal/services/auth_service.go
```bash
cat > internal/services/auth_service.go << 'EOF'
package services

import (
	"fmt"
	"time"

	"github.com/yourusername/timingle/internal/models"
	"github.com/yourusername/timingle/internal/repositories"
	"github.com/yourusername/timingle/pkg/utils"
)

type AuthService struct {
	userRepo  *repositories.UserRepository
	authRepo  *repositories.AuthRepository
	jwtSecret string
	accessExp time.Duration
	refreshExp time.Duration
}

func NewAuthService(
	userRepo *repositories.UserRepository,
	authRepo *repositories.AuthRepository,
	jwtSecret string,
	accessExp, refreshExp time.Duration,
) *AuthService {
	return &AuthService{
		userRepo:   userRepo,
		authRepo:   authRepo,
		jwtSecret:  jwtSecret,
		accessExp:  accessExp,
		refreshExp: refreshExp,
	}
}

func (s *AuthService) Login(phone, code string) (*models.TokenResponse, error) {
	// TODO: 실제 전화번호 인증 로직 (외부 API 연동)
	// 지금은 간단히 code가 "123456"이면 통과
	if code != "123456" {
		return nil, fmt.Errorf("invalid verification code")
	}

	// 사용자 조회 또는 생성
	user, err := s.userRepo.GetByPhone(phone)
	if err != nil {
		// 사용자 없으면 생성
		user = &models.User{
			Phone: phone,
			Name:  "User_" + phone[len(phone)-4:], // 기본 이름
			Role:  "USER",
		}
		if err := s.userRepo.Create(user); err != nil {
			return nil, fmt.Errorf("failed to create user: %w", err)
		}
	}

	return s.generateTokens(user)
}

func (s *AuthService) RefreshToken(refreshToken string) (*models.TokenResponse, error) {
	// Refresh Token 검증
	rt, err := s.authRepo.GetRefreshToken(refreshToken)
	if err != nil {
		return nil, fmt.Errorf("invalid refresh token")
	}

	// 사용자 조회
	user, err := s.userRepo.GetByID(rt.UserID)
	if err != nil {
		return nil, fmt.Errorf("user not found")
	}

	// 기존 Refresh Token 삭제
	_ = s.authRepo.DeleteRefreshToken(refreshToken)

	// 새 토큰 발급
	return s.generateTokens(user)
}

func (s *AuthService) Logout(refreshToken string) error {
	return s.authRepo.DeleteRefreshToken(refreshToken)
}

func (s *AuthService) generateTokens(user *models.User) (*models.TokenResponse, error) {
	// Access Token 생성
	accessToken, err := utils.GenerateAccessToken(user.ID, user.Phone, user.Role, s.jwtSecret, s.accessExp)
	if err != nil {
		return nil, err
	}

	// Refresh Token 생성
	refreshToken, err := utils.GenerateRandomToken(32)
	if err != nil {
		return nil, err
	}

	// Refresh Token 저장
	expiresAt := time.Now().Add(s.refreshExp)
	if err := s.authRepo.SaveRefreshToken(user.ID, refreshToken, expiresAt); err != nil {
		return nil, err
	}

	return &models.TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int64(s.accessExp.Seconds()),
	}, nil
}
EOF
```

### 7.2 internal/services/event_service.go
```bash
cat > internal/services/event_service.go << 'EOF'
package services

import (
	"fmt"
	"time"

	"github.com/yourusername/timingle/internal/models"
	"github.com/yourusername/timingle/internal/repositories"
)

type EventService struct {
	eventRepo *repositories.EventRepository
}

func NewEventService(eventRepo *repositories.EventRepository) *EventService {
	return &EventService{eventRepo: eventRepo}
}

func (s *EventService) CreateEvent(creatorID int64, req *models.CreateEventRequest) (*models.EventWithParticipants, error) {
	// 시간 파싱
	startTime, err := time.Parse(time.RFC3339, req.StartTime)
	if err != nil {
		return nil, fmt.Errorf("invalid start_time format")
	}
	endTime, err := time.Parse(time.RFC3339, req.EndTime)
	if err != nil {
		return nil, fmt.Errorf("invalid end_time format")
	}

	// 이벤트 생성
	event := &models.Event{
		Title:       req.Title,
		Description: req.Description,
		StartTime:   startTime,
		EndTime:     endTime,
		Location:    req.Location,
		CreatorID:   creatorID,
		Status:      models.EventStatusProposed,
	}

	if err := s.eventRepo.Create(event); err != nil {
		return nil, err
	}

	// 참여자 추가 (본인 포함)
	allParticipants := append([]int64{creatorID}, req.ParticipantIDs...)
	for _, userID := range allParticipants {
		_ = s.eventRepo.AddParticipant(event.ID, userID)
	}

	// 참여자 목록 조회
	participants, _ := s.eventRepo.GetParticipants(event.ID)

	return &models.EventWithParticipants{
		Event:        *event,
		Participants: convertParticipants(participants),
	}, nil
}

func (s *EventService) GetEvent(eventID, userID int64) (*models.EventWithParticipants, error) {
	event, err := s.eventRepo.GetByID(eventID)
	if err != nil {
		return nil, err
	}

	// 권한 확인 (참여자인지 확인)
	participants, err := s.eventRepo.GetParticipants(eventID)
	if err != nil {
		return nil, err
	}

	hasAccess := false
	for _, p := range participants {
		if p.UserID == userID {
			hasAccess = true
			break
		}
	}
	if !hasAccess {
		return nil, fmt.Errorf("access denied")
	}

	return &models.EventWithParticipants{
		Event:        *event,
		Participants: convertParticipants(participants),
	}, nil
}

func (s *EventService) GetUserEvents(userID int64) ([]*models.Event, error) {
	return s.eventRepo.GetByUserID(userID)
}

func (s *EventService) UpdateEvent(eventID, userID int64, req *models.UpdateEventRequest) error {
	// 이벤트 조회
	event, err := s.eventRepo.GetByID(eventID)
	if err != nil {
		return err
	}

	// 권한 확인 (생성자만 수정 가능)
	if event.CreatorID != userID {
		return fmt.Errorf("only creator can update event")
	}

	return s.eventRepo.Update(eventID, req)
}

func (s *EventService) DeleteEvent(eventID, userID int64) error {
	event, err := s.eventRepo.GetByID(eventID)
	if err != nil {
		return err
	}

	if event.CreatorID != userID {
		return fmt.Errorf("only creator can delete event")
	}

	return s.eventRepo.Delete(eventID)
}

func (s *EventService) ConfirmParticipation(eventID, userID int64) error {
	return s.eventRepo.ConfirmParticipant(eventID, userID)
}

func convertParticipants(participants []*models.EventParticipant) []models.EventParticipant {
	result := make([]models.EventParticipant, len(participants))
	for i, p := range participants {
		result[i] = *p
	}
	return result
}
EOF
```

---

## 🌐 Step 8: Handlers (HTTP Endpoints)

### 8.1 internal/handlers/auth_handler.go
```bash
cat > internal/handlers/auth_handler.go << 'EOF'
package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/yourusername/timingle/internal/models"
	"github.com/yourusername/timingle/internal/services"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(authService *services.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// POST /api/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req models.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tokens, err := h.authService.Login(req.Phone, req.Code)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tokens)
}

// POST /api/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req models.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	tokens, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, tokens)
}

// POST /api/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	var req models.RefreshTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.authService.Logout(req.RefreshToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "logged out successfully"})
}
EOF
```

### 8.2 internal/handlers/event_handler.go
```bash
cat > internal/handlers/event_handler.go << 'EOF'
package handlers

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/yourusername/timingle/internal/models"
	"github.com/yourusername/timingle/internal/services"
)

type EventHandler struct {
	eventService *services.EventService
}

func NewEventHandler(eventService *services.EventService) *EventHandler {
	return &EventHandler{eventService: eventService}
}

// POST /api/events
func (h *EventHandler) CreateEvent(c *gin.Context) {
	userID := c.GetInt64("user_id") // Middleware에서 설정

	var req models.CreateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	event, err := h.eventService.CreateEvent(userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, event)
}

// GET /api/events/:id
func (h *EventHandler) GetEvent(c *gin.Context) {
	userID := c.GetInt64("user_id")
	eventID, _ := strconv.ParseInt(c.Param("id"), 10, 64)

	event, err := h.eventService.GetEvent(eventID, userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, event)
}

// GET /api/events
func (h *EventHandler) GetUserEvents(c *gin.Context) {
	userID := c.GetInt64("user_id")

	events, err := h.eventService.GetUserEvents(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"events": events})
}

// PATCH /api/events/:id
func (h *EventHandler) UpdateEvent(c *gin.Context) {
	userID := c.GetInt64("user_id")
	eventID, _ := strconv.ParseInt(c.Param("id"), 10, 64)

	var req models.UpdateEventRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.eventService.UpdateEvent(eventID, userID, &req); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "event updated successfully"})
}

// DELETE /api/events/:id
func (h *EventHandler) DeleteEvent(c *gin.Context) {
	userID := c.GetInt64("user_id")
	eventID, _ := strconv.ParseInt(c.Param("id"), 10, 64)

	if err := h.eventService.DeleteEvent(eventID, userID); err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "event deleted successfully"})
}

// POST /api/events/:id/confirm
func (h *EventHandler) ConfirmParticipation(c *gin.Context) {
	userID := c.GetInt64("user_id")
	eventID, _ := strconv.ParseInt(c.Param("id"), 10, 64)

	if err := h.eventService.ConfirmParticipation(eventID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "participation confirmed"})
}
EOF
```

---

## 🔒 Step 9: Middleware (인증, 로깅)

### 9.1 internal/middleware/auth.go
```bash
cat > internal/middleware/auth.go << 'EOF'
package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/yourusername/timingle/pkg/utils"
)

func AuthMiddleware(jwtSecret string) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Authorization 헤더 추출
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "authorization header required"})
			c.Abort()
			return
		}

		// Bearer 토큰 추출
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization header format"})
			c.Abort()
			return
		}

		token := parts[1]

		// 토큰 검증
		claims, err := utils.ValidateToken(token, jwtSecret)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}

		// 컨텍스트에 사용자 정보 저장
		c.Set("user_id", claims.UserID)
		c.Set("phone", claims.Phone)
		c.Set("role", claims.Role)

		c.Next()
	}
}
EOF
```

### 9.2 internal/middleware/logger.go
```bash
cat > internal/middleware/logger.go << 'EOF'
package middleware

import (
	"log"
	"time"

	"github.com/gin-gonic/gin"
)

func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		method := c.Request.Method

		c.Next()

		latency := time.Since(start)
		statusCode := c.Writer.Status()

		log.Printf("[%s] %s %d %v", method, path, statusCode, latency)
	}
}
EOF
```

---

## 🚀 Step 10: API Server (main.go)

### 10.1 cmd/api/main.go
```bash
cat > cmd/api/main.go << 'EOF'
package main

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/yourusername/timingle/internal/config"
	"github.com/yourusername/timingle/internal/db"
	"github.com/yourusername/timingle/internal/handlers"
	"github.com/yourusername/timingle/internal/middleware"
	"github.com/yourusername/timingle/internal/repositories"
	"github.com/yourusername/timingle/internal/services"
)

func main() {
	// 설정 로드
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// PostgreSQL 연결
	pgDB, err := db.NewPostgresDB(cfg.Postgres.DSN())
	if err != nil {
		log.Fatalf("Failed to connect to PostgreSQL: %v", err)
	}
	defer pgDB.Close()

	// Redis 연결
	redisClient, err := db.NewRedisClient(cfg.Redis.Addr(), cfg.Redis.Password)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer redisClient.Close()

	// Repositories
	userRepo := repositories.NewUserRepository(pgDB.DB)
	eventRepo := repositories.NewEventRepository(pgDB.DB)
	authRepo := repositories.NewAuthRepository(pgDB.DB)

	// Services
	authService := services.NewAuthService(userRepo, authRepo, cfg.JWT.Secret, cfg.JWT.AccessExpiry, cfg.JWT.RefreshExpiry)
	eventService := services.NewEventService(eventRepo)

	// Handlers
	authHandler := handlers.NewAuthHandler(authService)
	eventHandler := handlers.NewEventHandler(eventService)

	// Gin 설정
	gin.SetMode(cfg.Server.GinMode)
	r := gin.Default()

	// Middleware
	r.Use(middleware.Logger())

	// Routes
	api := r.Group("/api")
	{
		// Public routes
		auth := api.Group("/auth")
		{
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/logout", authHandler.Logout)
		}

		// Protected routes
		protected := api.Group("")
		protected.Use(middleware.AuthMiddleware(cfg.JWT.Secret))
		{
			// Events
			events := protected.Group("/events")
			{
				events.POST("", eventHandler.CreateEvent)
				events.GET("", eventHandler.GetUserEvents)
				events.GET("/:id", eventHandler.GetEvent)
				events.PATCH("/:id", eventHandler.UpdateEvent)
				events.DELETE("/:id", eventHandler.DeleteEvent)
				events.POST("/:id/confirm", eventHandler.ConfirmParticipation)
			}
		}
	}

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// 서버 시작
	log.Printf("🚀 Server starting on port %s", cfg.Server.Port)
	if err := r.Run(":" + cfg.Server.Port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
EOF
```

---

## ✅ Step 11: 테스트 및 검증

### 11.1 서버 실행
```bash
cd backend

# 환경변수 로드
export $(cat .env | grep -v '^#' | xargs)

# 서버 실행
go run cmd/api/main.go
```

**예상 출력**:
```
✅ PostgreSQL connected successfully
✅ Redis connected successfully
🚀 Server starting on port 8080
[GIN-debug] Listening and serving HTTP on :8080
```

### 11.2 API 테스트 (cURL)

#### 1. Health Check
```bash
curl http://localhost:8080/health
```

**응답**:
```json
{"status":"ok"}
```

#### 2. 로그인 (전화번호 인증)
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+821012345678",
    "code": "123456"
  }'
```

**응답**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "abc123...",
  "expires_in": 900
}
```

**토큰 저장**:
```bash
export ACCESS_TOKEN="여기에_access_token_복사"
```

#### 3. 이벤트 생성
```bash
curl -X POST http://localhost:8080/api/events \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "title": "9am -> 길동이",
    "description": "커피 한잔 어때요?",
    "start_time": "2025-01-15T09:00:00+09:00",
    "end_time": "2025-01-15T10:00:00+09:00",
    "location": "강남역 스타벅스",
    "participant_ids": []
  }'
```

**응답**:
```json
{
  "id": 1,
  "title": "9am -> 길동이",
  "description": "커피 한잔 어때요?",
  "start_time": "2025-01-15T09:00:00+09:00",
  "end_time": "2025-01-15T10:00:00+09:00",
  "location": "강남역 스타벅스",
  "creator_id": 1,
  "status": "PROPOSED",
  "created_at": "2025-01-10T...",
  "updated_at": "2025-01-10T...",
  "participants": [
    {
      "event_id": 1,
      "user_id": 1,
      "confirmed": false,
      "user": {
        "id": 1,
        "phone": "+821012345678",
        "name": "User_5678",
        "profile_image_url": ""
      }
    }
  ]
}
```

#### 4. 이벤트 목록 조회
```bash
curl -X GET http://localhost:8080/api/events \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

#### 5. 이벤트 상세 조회
```bash
curl -X GET http://localhost:8080/api/events/1 \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

#### 6. 이벤트 수정
```bash
curl -X PATCH http://localhost:8080/api/events/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -d '{
    "status": "CONFIRMED"
  }'
```

#### 7. 참여 확인
```bash
curl -X POST http://localhost:8080/api/events/1/confirm \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

---

## 📝 완료 체크리스트

### Phase 1 완료 조건
- [ ] Go 프로젝트 구조 생성 완료
- [ ] `go mod tidy` 성공
- [ ] PostgreSQL 마이그레이션 완료 (4개 테이블)
- [ ] 서버 실행 성공 (`go run cmd/api/main.go`)
- [ ] Health Check 성공 (`/health`)
- [ ] 로그인 API 성공 (`POST /api/auth/login`)
- [ ] 이벤트 생성 API 성공 (`POST /api/events`)
- [ ] 이벤트 조회 API 성공 (`GET /api/events`)
- [ ] 인증 미들웨어 동작 확인 (401 Unauthorized)
- [ ] PostgreSQL 데이터 확인 (`SELECT * FROM events;`)

### 디버깅 팁
```bash
# PostgreSQL 데이터 확인
podman exec -it timingle-postgres psql -U timingle -d timingle -c "SELECT * FROM users;"
podman exec -it timingle-postgres psql -U timingle -d timingle -c "SELECT * FROM events;"

# Redis 데이터 확인 (나중에 세션 저장 시)
podman exec -it timingle-redis redis-cli KEYS '*'

# 로그 확인
go run cmd/api/main.go 2>&1 | tee server.log
```

---

## 🎯 다음 단계

**Phase 1 완료 후**:
- ✅ Backend 핵심 API 동작 확인
- ➡️ **PHASE_2_REALTIME.md**: WebSocket, NATS, ScyllaDB 연동
- ➡️ **PHASE_3_FLUTTER.md**: Flutter 앱 구현

**Phase 1 결과물**:
- `/backend` 디렉토리 완전 구현
- REST API 서버 동작
- JWT 인증 시스템
- 이벤트 CRUD 완료
- PostgreSQL 연동 완료

---

**Phase 1 완료! 🎉**
