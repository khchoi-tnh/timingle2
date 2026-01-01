package models

import (
	"time"
)

// UserRole represents user role types
type UserRole string

const (
	UserRoleUser     UserRole = "USER"
	UserRoleBusiness UserRole = "BUSINESS"
)

// User represents a user in the system
type User struct {
	ID              int64     `json:"id" db:"id"`
	Phone           string    `json:"phone" db:"phone"`
	Name            *string   `json:"name,omitempty" db:"name"`
	Email           *string   `json:"email,omitempty" db:"email"`
	ProfileImageURL *string   `json:"profile_image_url,omitempty" db:"profile_image_url"`
	Region          *string   `json:"region,omitempty" db:"region"`
	Interests       []string  `json:"interests,omitempty" db:"interests"`
	Timezone        string    `json:"timezone" db:"timezone"`
	Language        string    `json:"language" db:"language"`
	Role            UserRole  `json:"role" db:"role"`
	CreatedAt       time.Time `json:"created_at" db:"created_at"`
	UpdatedAt       time.Time `json:"updated_at" db:"updated_at"`
}

// RegisterRequest represents user registration request
type RegisterRequest struct {
	Phone string `json:"phone" binding:"required"`
	Name  string `json:"name" binding:"required"`
}

// UpdateUserRequest represents user profile update request
type UpdateUserRequest struct {
	Name            *string  `json:"name,omitempty"`
	Email           *string  `json:"email,omitempty"`
	ProfileImageURL *string  `json:"profile_image_url,omitempty"`
	Region          *string  `json:"region,omitempty"`
	Interests       []string `json:"interests,omitempty"`
	Timezone        *string  `json:"timezone,omitempty"`
	Language        *string  `json:"language,omitempty"`
}

// UserResponse represents user data in API responses (excludes sensitive fields)
type UserResponse struct {
	ID              int64     `json:"id"`
	Phone           string    `json:"phone"`
	Name            *string   `json:"name,omitempty"`
	Email           *string   `json:"email,omitempty"`
	ProfileImageURL *string   `json:"profile_image_url,omitempty"`
	Region          *string   `json:"region,omitempty"`
	Interests       []string  `json:"interests,omitempty"`
	Timezone        string    `json:"timezone"`
	Language        string    `json:"language"`
	Role            UserRole  `json:"role"`
	CreatedAt       time.Time `json:"created_at"`
}

// ToUserResponse converts User to UserResponse
func (u *User) ToUserResponse() *UserResponse {
	return &UserResponse{
		ID:              u.ID,
		Phone:           u.Phone,
		Name:            u.Name,
		Email:           u.Email,
		ProfileImageURL: u.ProfileImageURL,
		Region:          u.Region,
		Interests:       u.Interests,
		Timezone:        u.Timezone,
		Language:        u.Language,
		Role:            u.Role,
		CreatedAt:       u.CreatedAt,
	}
}
