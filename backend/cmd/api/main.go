package main

import (
	"fmt"
	"log"

	"github.com/gin-gonic/gin"
	"github.com/khchoi-tnh/timingle/internal/config"
	"github.com/khchoi-tnh/timingle/internal/db"
	"github.com/khchoi-tnh/timingle/internal/handlers"
	"github.com/khchoi-tnh/timingle/internal/middleware"
	"github.com/khchoi-tnh/timingle/internal/repositories"
	"github.com/khchoi-tnh/timingle/internal/services"
	"github.com/khchoi-tnh/timingle/internal/websocket"
	"github.com/khchoi-tnh/timingle/pkg/utils"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Set Gin mode
	gin.SetMode(cfg.Server.GinMode)

	// Connect to PostgreSQL
	postgresDB, err := db.NewPostgresDB(cfg.GetPostgresConnectionString())
	if err != nil {
		log.Fatalf("Failed to connect to PostgreSQL: %v", err)
	}
	defer postgresDB.Close()
	log.Println("✅ Connected to PostgreSQL")

	// Connect to Redis
	redisClient, err := db.NewRedisClient(cfg.Redis.Host, cfg.Redis.Port, cfg.Redis.Password, cfg.Redis.DB)
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}
	defer redisClient.Close()
	log.Println("✅ Connected to Redis")

	// Connect to ScyllaDB
	scyllaDB, err := db.NewScyllaDB(cfg.ScyllaDB.Hosts, cfg.ScyllaDB.Keyspace)
	if err != nil {
		log.Fatalf("Failed to connect to ScyllaDB: %v", err)
	}
	defer scyllaDB.Close()

	// Connect to NATS
	natsClient, err := db.NewNATSClient(cfg.NATS.URL)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer natsClient.Close()

	// Create NATS Streams
	if err := natsClient.CreateStreams(); err != nil {
		log.Fatalf("Failed to create NATS streams: %v", err)
	}

	// Initialize WebSocket Hub
	hub := websocket.NewHub()
	go hub.Run()

	// Initialize JWT manager
	jwtManager := utils.NewJWTManager(cfg.JWT.Secret, cfg.JWT.AccessExpiry, cfg.JWT.RefreshExpiry)

	// Initialize Google OAuth verifier with client secret for token refresh
	googleVerifier := utils.NewGoogleOAuthVerifierWithSecret(
		cfg.OAuth.GoogleClientIDWeb,
		cfg.OAuth.GoogleClientSecret,
		cfg.OAuth.GoogleClientID,
		cfg.OAuth.GoogleClientIDiOS,
		cfg.OAuth.GoogleClientIDWeb,
	)

	// Initialize repositories
	userRepo := repositories.NewUserRepository(postgresDB.DB)
	eventRepo := repositories.NewEventRepository(postgresDB.DB)
	authRepo := repositories.NewAuthRepository(postgresDB.DB)
	oauthRepo := repositories.NewOAuthRepository(postgresDB.DB)
	chatRepo := repositories.NewChatRepository(scyllaDB.Session)
	inviteRepo := repositories.NewInviteRepository(postgresDB.DB)

	// Initialize services
	authService := services.NewAuthService(userRepo, authRepo, oauthRepo, jwtManager, googleVerifier)
	eventService := services.NewEventService(eventRepo, userRepo)
	chatService := services.NewChatService(chatRepo, userRepo, eventService, hub, natsClient.JS)
	calendarService := services.NewCalendarService(authService, eventRepo, oauthRepo)
	inviteService := services.NewInviteService(inviteRepo, eventRepo, userRepo, cfg.Server.BaseURL)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService)
	eventHandler := handlers.NewEventHandler(eventService)
	calendarHandler := handlers.NewCalendarHandler(calendarService)
	wsHandler := handlers.NewWebSocketHandler(hub, chatService)
	inviteHandler := handlers.NewInviteHandler(inviteService)

	// Setup router
	router := gin.Default()

	// Apply middleware
	router.Use(middleware.CORSMiddleware())
	router.Use(middleware.LoggerMiddleware())

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status": "healthy",
			"service": "timingle-api",
		})
	})

	// API v1 routes
	v1 := router.Group("/api/v1")
	{
		// Auth routes (public)
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authHandler.Register)
			auth.POST("/login", authHandler.Login)
			auth.POST("/refresh", authHandler.RefreshToken)
			auth.POST("/google", authHandler.GoogleLogin)                   // Google OAuth login
			auth.POST("/google/calendar", authHandler.GoogleCalendarLogin) // Google OAuth login with Calendar scope

			// Protected auth routes
			authProtected := auth.Group("")
			authProtected.Use(middleware.AuthMiddleware(jwtManager, userRepo))
			{
				authProtected.POST("/logout", authHandler.Logout)
				authProtected.GET("/me", authHandler.Me)
			}
		}

		// Event routes (protected)
		events := v1.Group("/events")
		events.Use(middleware.AuthMiddleware(jwtManager, userRepo))
		{
			events.POST("", eventHandler.CreateEvent)
			events.GET("", eventHandler.GetUserEvents)
			events.GET("/:id", eventHandler.GetEvent)
			events.PUT("/:id", eventHandler.UpdateEvent)
			events.DELETE("/:id", eventHandler.DeleteEvent)

			// Event actions
			events.POST("/:id/participants", eventHandler.AddParticipant)
			events.DELETE("/:id/participants/:participant_id", eventHandler.RemoveParticipant)
			events.POST("/:id/confirm-participation", eventHandler.ConfirmParticipation)
			events.POST("/:id/confirm", eventHandler.ConfirmEvent)
			events.POST("/:id/cancel", eventHandler.CancelEvent)
			events.POST("/:id/done", eventHandler.MarkEventDone)

			// Chat messages
			events.GET("/:id/messages", wsHandler.GetMessages)

			// Invite links
			events.POST("/:id/invite-link", inviteHandler.CreateInviteLink)
			events.POST("/:id/accept", inviteHandler.AcceptInvite)
			events.POST("/:id/decline", inviteHandler.DeclineInvite)
		}

		// Invite routes (protected) - for accessing invite links
		invite := v1.Group("/invite")
		invite.Use(middleware.AuthMiddleware(jwtManager, userRepo))
		{
			invite.GET("/:code", inviteHandler.GetInviteInfo)
			invite.POST("/:code/join", inviteHandler.JoinViaInvite)
		}

		// WebSocket route (protected)
		v1.GET("/ws", middleware.AuthMiddleware(jwtManager, userRepo), wsHandler.HandleWebSocket)

		// Calendar routes (protected)
		calendar := v1.Group("/calendar")
		calendar.Use(middleware.AuthMiddleware(jwtManager, userRepo))
		{
			calendar.GET("/status", calendarHandler.CheckCalendarAccess)
			calendar.GET("/events", calendarHandler.GetCalendarEvents)
			calendar.POST("/sync/:event_id", calendarHandler.SyncEventToCalendar)
		}
	}

	// Start server
	addr := fmt.Sprintf(":%s", cfg.Server.Port)
	log.Printf("🚀 Server starting on %s", addr)
	if err := router.Run(addr); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
