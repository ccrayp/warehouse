package config

import (
	"os"
	"strconv"
)

type Config struct {
	JWT struct {
		SecretKey string
	}
	Database struct {
		Host string
		Port int
		Name string
	}
	User struct {
		AdminLogin        string
		AdminPassword     string
		ModeratorLogin    string
		ModeratorPassword string
		ManagerLogin      string
		ManagerPassword   string
	}
}

func LoadConfig() *Config {
	c := &Config{}

	c.JWT.SecretKey = os.Getenv("JWT_SECRET_KEY")

	c.Database.Host = os.Getenv("DATABASE_HOST")
	c.Database.Port, _ = strconv.Atoi(os.Getenv("DATABASE_PORT"))
	c.Database.Name = os.Getenv("DATABASE_NAME")

	c.User.AdminLogin = os.Getenv("USER_ADMIN_LOGIN")
	c.User.AdminPassword = os.Getenv("USER_ADMIN_PASSWORD")
	c.User.ModeratorLogin = os.Getenv("USER_MODERATOR_LOGIN")
	c.User.ModeratorPassword = os.Getenv("USER_MODERATOR_PASSWORD")
	c.User.ManagerLogin = os.Getenv("USER_MANAGER_LOGIN")
	c.User.ManagerPassword = os.Getenv("USER_MANAGER_PASSWORD")

	return c
}
