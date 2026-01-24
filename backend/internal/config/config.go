package config

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

// Config holds all application configuration
type Config struct {
	Server   ServerConfig
	Postgres PostgresConfig
	Redis    RedisConfig
	NATS     NATSConfig
	ScyllaDB ScyllaDBConfig
	JWT      JWTConfig
	OAuth    OAuthConfig
}

// OAuthConfig holds OAuth provider configuration
type OAuthConfig struct {
	GoogleClientID        string // Android client ID
	GoogleClientIDiOS     string // iOS client ID
	GoogleClientIDWeb     string // Web client ID (used for ID token verification)
	GoogleClientSecret    string // Web client secret (for token refresh)
}

// ServerConfig holds server-specific configuration
type ServerConfig struct {
	Port    string
	GinMode string
	BaseURL string // Base URL for generating invite links
}

// PostgresConfig holds PostgreSQL connection configuration
type PostgresConfig struct {
	Host     string
	Port     string
	User     string
	Password string
	DB       string
	SSLMode  string
}

// RedisConfig holds Redis connection configuration
type RedisConfig struct {
	Host     string
	Port     string
	Password string
	DB       int
}

// NATSConfig holds NATS connection configuration
type NATSConfig struct {
	URL string
}

// ScyllaDBConfig holds ScyllaDB connection configuration
type ScyllaDBConfig struct {
	Hosts    []string
	Keyspace string
}

// JWTConfig holds JWT configuration
type JWTConfig struct {
	Secret        string
	AccessExpiry  time.Duration
	RefreshExpiry time.Duration
}

// Load loads configuration from environment variables
func Load() (*Config, error) {
	config := &Config{
		Server: ServerConfig{
			Port:    getEnv("PORT", "8080"),
			GinMode: getEnv("GIN_MODE", "debug"),
			BaseURL: getEnv("BASE_URL", "https://timingle.app"),
		},
		Postgres: PostgresConfig{
			Host:     getEnv("POSTGRES_HOST", "localhost"),
			Port:     getEnv("POSTGRES_PORT", "5432"),
			User:     getEnv("POSTGRES_USER", "timingle"),
			Password: getEnv("POSTGRES_PASSWORD", ""),
			DB:       getEnv("POSTGRES_DB", "timingle"),
			SSLMode:  getEnv("POSTGRES_SSLMODE", "disable"),
		},
		Redis: RedisConfig{
			Host:     getEnv("REDIS_HOST", "localhost"),
			Port:     getEnv("REDIS_PORT", "6379"),
			Password: getEnv("REDIS_PASSWORD", ""),
			DB:       getEnvAsInt("REDIS_DB", 0),
		},
		NATS: NATSConfig{
			URL: getEnv("NATS_URL", "nats://localhost:4222"),
		},
		ScyllaDB: ScyllaDBConfig{
			Hosts:    []string{getEnv("SCYLLA_HOST", "localhost")},
			Keyspace: getEnv("SCYLLA_KEYSPACE", "timingle"),
		},
		JWT: JWTConfig{
			Secret:        getEnv("JWT_SECRET", "your-secret-key-change-this-in-production"),
			AccessExpiry:  getEnvAsDuration("JWT_ACCESS_EXPIRY", "15m"),
			RefreshExpiry: getEnvAsDuration("JWT_REFRESH_EXPIRY", "168h"),
		},
		OAuth: OAuthConfig{
			GoogleClientID:        getEnv("GOOGLE_CLIENT_ID_AND", ""),
			GoogleClientIDiOS:     getEnv("GOOGLE_CLIENT_ID_IOS", ""),
			GoogleClientIDWeb:     getEnv("GOOGLE_CLIENT_ID_WEB", ""),
			GoogleClientSecret:    getEnv("GOOGLE_CLIENT_SECRET", ""),
		},
	}

	// Validate required fields
	if config.Postgres.Password == "" {
		return nil, fmt.Errorf("POSTGRES_PASSWORD is required")
	}

	return config, nil
}

// GetPostgresConnectionString returns PostgreSQL connection string
func (c *Config) GetPostgresConnectionString() string {
	return fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
		c.Postgres.Host,
		c.Postgres.Port,
		c.Postgres.User,
		c.Postgres.Password,
		c.Postgres.DB,
		c.Postgres.SSLMode,
	)
}

// getEnv reads an environment variable or returns a default value
func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// getEnvAsInt reads an environment variable as int or returns a default value
func getEnvAsInt(key string, defaultValue int) int {
	valueStr := os.Getenv(key)
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return defaultValue
}

// getEnvAsDuration reads an environment variable as duration or returns a default value
func getEnvAsDuration(key, defaultValue string) time.Duration {
	valueStr := getEnv(key, defaultValue)
	duration, err := time.ParseDuration(valueStr)
	if err != nil {
		// If parsing fails, try to parse as default
		duration, _ = time.ParseDuration(defaultValue)
	}
	return duration
}
