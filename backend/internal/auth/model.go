package auth

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type RefreshTokens struct {
	ID        int       `json:"id"`
	Token     string    `json:"token"`
	Username  string    `json:"username"`
	Role      string    `json:"role"`
	CreatedAt time.Time `json:"created_at"`
}

type Claims struct {
	Username string `json:"username"`
	Role     string `json:"role"`
	jwt.RegisteredClaims
}

type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type ValidateRequest struct {
	AccessToken string `json:"access_token"`
}

type Permission struct {
	Section     string   `json:"section"`
	Permissions []string `json:"permissions"`
}
