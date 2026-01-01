package websocket

import (
	"log"
	"sync"
)

// Hub manages WebSocket connections
type Hub struct {
	// Event ID -> Client map
	rooms      map[int64]map[*Client]bool
	register   chan *Client
	unregister chan *Client
	broadcast  chan *BroadcastMessage
	mu         sync.RWMutex
}

// BroadcastMessage represents a message to broadcast to an event room
type BroadcastMessage struct {
	EventID int64
	Data    []byte
}

// NewHub creates a new Hub
func NewHub() *Hub {
	return &Hub{
		rooms:      make(map[int64]map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan *BroadcastMessage, 256),
	}
}

// Run starts the hub's main loop
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			if _, ok := h.rooms[client.EventID]; !ok {
				h.rooms[client.EventID] = make(map[*Client]bool)
			}
			h.rooms[client.EventID][client] = true
			h.mu.Unlock()
			log.Printf("✅ Client %d joined event %d", client.UserID, client.EventID)

		case client := <-h.unregister:
			h.mu.Lock()
			if clients, ok := h.rooms[client.EventID]; ok {
				if _, ok := clients[client]; ok {
					delete(clients, client)
					close(client.send)
					if len(clients) == 0 {
						delete(h.rooms, client.EventID)
					}
				}
			}
			h.mu.Unlock()
			log.Printf("👋 Client %d left event %d", client.UserID, client.EventID)

		case message := <-h.broadcast:
			h.mu.RLock()
			clients := h.rooms[message.EventID]
			h.mu.RUnlock()

			for client := range clients {
				select {
				case client.send <- message.Data:
				default:
					close(client.send)
					delete(clients, client)
				}
			}
		}
	}
}

// RegisterClient registers a client to the hub
func (h *Hub) RegisterClient(client *Client) {
	h.register <- client
}

// UnregisterClient unregisters a client from the hub
func (h *Hub) UnregisterClient(client *Client) {
	h.unregister <- client
}

// BroadcastToEvent broadcasts a message to all clients in an event room
func (h *Hub) BroadcastToEvent(eventID int64, data []byte) {
	h.broadcast <- &BroadcastMessage{
		EventID: eventID,
		Data:    data,
	}
}
