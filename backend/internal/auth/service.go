package auth

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"os"
	"time"
	"warehouse/pkg/utils"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

var secretKey = []byte(os.Getenv("SECRET_KEY"))

func GenerateToken(username string, role string) (string, error) {
	expirationTime := time.Now().Add(time.Hour)

	claims := &Claims{
		Username: username,
		Role:     role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretKey)
}

func GenerateRefreshToken(repo *AuthRepository, username, role string) (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	refreshToken := hex.EncodeToString(b)

	if err := repo.SaveRefreshToken(refreshToken, username, role); err != nil {
		return "", err
	}

	return refreshToken, nil
}

func RefreshAccessToken(repo *AuthRepository, token string, role string) (string, error) {
	rt, err := repo.GetRefreshToken(token, role)
	if err != nil {
		return "", err
	}

	if err := repo.DeleteRefreshToken(token, role); err != nil {
		return "", err
	}

	return GenerateToken(rt.Username, rt.Role)
}

func ValidateToken(tokenStr string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		return secretKey, nil
	})
	if err != nil || !token.Valid {
		return nil, err
	}
	return claims, nil
}

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.AbortWithStatusJSON(401, utils.Response{
				Success: false,
				Message: "missing token",
				Status:  http.StatusUnauthorized,
				Data: gin.H{
					"required_data": "Authorization Bearer",
				},
				Error:    "missing token",
				Endpoint: c.FullPath(),
			})
			return
		}

		tokenStr := authHeader[len("Bearer "):]
		claims, err := ValidateToken(tokenStr)
		if err != nil {
			c.AbortWithStatusJSON(401, utils.Response{
				Success: false,
				Message: "missing token",
				Status:  http.StatusUnauthorized,
				Data: gin.H{
					"required_data": "Authorization Bearer",
				},
				Error:    "invalid token",
				Endpoint: c.FullPath(),
			})
			return
		}

		c.Set("claims", claims)
		c.Next()
	}
}

func GetClaims(ctx *gin.Context) *Claims {
	claimsValue, exists := ctx.Get("claims")
	if !exists {
		utils.RespondError(ctx, http.StatusUnauthorized, "claims missing in request context", "claims not exixts", nil)
		return nil
	}

	claims, ok := claimsValue.(*Claims)
	if !ok {
		utils.RespondError(ctx, http.StatusInternalServerError, "invalid claims type", "invalid claims type", nil)
		return nil
	}

	return claims
}
