package db

import (
	"fmt"
	"log"
	"time"

	"github.com/gocql/gocql"
)

// ScyllaDB wraps the ScyllaDB session
type ScyllaDB struct {
	Session *gocql.Session
}

// NewScyllaDB creates a new ScyllaDB connection
func NewScyllaDB(hosts []string, keyspace string) (*ScyllaDB, error) {
	cluster := gocql.NewCluster(hosts...)
	cluster.Keyspace = keyspace
	cluster.Consistency = gocql.Quorum
	cluster.ProtoVersion = 4
	cluster.ConnectTimeout = 10 * time.Second
	cluster.Timeout = 5 * time.Second
	cluster.NumConns = 2

	session, err := cluster.CreateSession()
	if err != nil {
		return nil, fmt.Errorf("failed to connect to ScyllaDB: %w", err)
	}

	log.Println("✅ Connected to ScyllaDB")

	return &ScyllaDB{Session: session}, nil
}

// Close closes the ScyllaDB connection
func (s *ScyllaDB) Close() {
	log.Println("🔌 Closing ScyllaDB connection...")
	s.Session.Close()
}

// Health checks ScyllaDB health
func (s *ScyllaDB) Health() error {
	// Simple query to check connectivity
	return s.Session.Query("SELECT now() FROM system.local").Exec()
}
