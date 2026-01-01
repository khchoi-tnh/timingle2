package main

import (
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/nats-io/nats.go"
	"github.com/khchoi-tnh/timingle/internal/config"
	"github.com/khchoi-tnh/timingle/internal/db"
	"github.com/khchoi-tnh/timingle/internal/models"
	"github.com/khchoi-tnh/timingle/internal/repositories"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Connect to ScyllaDB
	scyllaDB, err := db.NewScyllaDB(cfg.ScyllaDB.Hosts, cfg.ScyllaDB.Keyspace)
	if err != nil {
		log.Fatalf("Failed to connect to ScyllaDB: %v", err)
	}
	defer scyllaDB.Close()

	chatRepo := repositories.NewChatRepository(scyllaDB.Session)

	// Connect to NATS
	natsClient, err := db.NewNATSClient(cfg.NATS.URL)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer natsClient.Close()

	// Create JetStream consumer
	sub, err := natsClient.JS.Subscribe("chat.message.*", func(msg *nats.Msg) {
		// Parse message
		var chatMsg models.ChatMessage
		if err := json.Unmarshal(msg.Data, &chatMsg); err != nil {
			log.Printf("Failed to unmarshal message: %v", err)
			msg.Nak()
			return
		}

		// Save to ScyllaDB
		if err := chatRepo.SaveMessage(&chatMsg); err != nil {
			log.Printf("Failed to save message to ScyllaDB: %v", err)
			msg.Nak()
			return
		}

		log.Printf("✅ Saved message %s to event %d", chatMsg.MessageID, chatMsg.EventID)
		msg.Ack()
	}, nats.Durable("chat-worker"), nats.ManualAck())

	if err != nil {
		log.Fatalf("Failed to subscribe: %v", err)
	}
	defer sub.Unsubscribe()

	log.Println("🚀 Chat worker started. Listening for messages...")

	// Graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	<-sigChan

	log.Println("👋 Chat worker shutting down...")
}
