package db

import (
	"fmt"
	"log"
	"time"

	"github.com/nats-io/nats.go"
)

// NATSClient wraps the NATS connection
type NATSClient struct {
	Conn *nats.Conn
	JS   nats.JetStreamContext
}

// NewNATSClient creates a new NATS client with JetStream
func NewNATSClient(url string) (*NATSClient, error) {
	nc, err := nats.Connect(url,
		nats.MaxReconnects(5),
		nats.ReconnectWait(2*time.Second),
	)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to NATS: %w", err)
	}

	// Enable JetStream
	js, err := nc.JetStream()
	if err != nil {
		return nil, fmt.Errorf("failed to create JetStream context: %w", err)
	}

	log.Println("✅ Connected to NATS JetStream")

	return &NATSClient{Conn: nc, JS: js}, nil
}

// Close closes the NATS connection
func (n *NATSClient) Close() {
	log.Println("🔌 Closing NATS connection...")
	n.Conn.Close()
}

// CreateStreams creates JetStream streams (run once during initialization)
func (n *NATSClient) CreateStreams() error {
	// Chat messages stream
	_, err := n.JS.AddStream(&nats.StreamConfig{
		Name:     "CHAT_MESSAGES",
		Subjects: []string{"chat.message.*"},
		MaxAge:   24 * time.Hour, // 24 hours retention
		Storage:  nats.FileStorage,
	})
	if err != nil && err != nats.ErrStreamNameAlreadyInUse {
		return fmt.Errorf("failed to create CHAT_MESSAGES stream: %w", err)
	}

	// Event events stream
	_, err = n.JS.AddStream(&nats.StreamConfig{
		Name:     "EVENTS",
		Subjects: []string{"event.*"},
		MaxAge:   7 * 24 * time.Hour, // 7 days retention
		Storage:  nats.FileStorage,
	})
	if err != nil && err != nats.ErrStreamNameAlreadyInUse {
		return fmt.Errorf("failed to create EVENTS stream: %w", err)
	}

	log.Println("✅ NATS JetStream streams created/verified")

	return nil
}
