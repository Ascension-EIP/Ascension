// @date 2026-11-13
// @file config.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package config

import (
	"fmt"
	"net/url"
	"time"

	"github.com/caarlos0/env/v11"
)

type (
	Config struct {
		DB      DBConfig      `envPrefix:"POSTGRES_"`
		Storage StorageConfig `envPrefix:"STORAGE_"`
		Queue   QueueConfig   `envPrefix:"QUEUE_"`
		Video   VideoConfig   `envPrefix:"VIDEO_"`
		Auth    AuthConfig    `envPrefix:"AUTH_"`
		HTTP    HTTPConfig
		Log     LogConfig `envPrefix:"LOG_"`
	}

	DBConfig struct {
		Host     string `env:"HOST" envDefault:"localhost"`
		Port     int    `env:"PORT" envDefault:"5432"`
		Name     string `env:"DB,unset,required"`
		User     string `env:"USER,unset,required"`
		Password string `env:"PASSWORD,unset,required"`
		Params   string `env:"PARAMS" envDefault:"sslmode=disable"`
	}

	StorageConfig struct {
		Endpoint        string        `env:"ENDPOINT,unset,required"`
		Region          string        `env:"REGION,unset,required"`
		AccessKeyID     string        `env:"ID,unset,required"`
		SecretAccessKey string        `env:"SECRET,unset,required"`
		BucketName      string        `env:"BUCKET,required"`
		UploadExp       time.Duration `env:"UPLOAD_EXP" envDefault:"1h"`
		DownloadExp     time.Duration `env:"DOWNLAOD_EXP" envDefault:"1h"`
	}

	QueueConfig struct {
		Host          string `env:"HOST" envDefault:"localhost"`
		Port          int    `env:"PORT" envDefault:"5672"`
		User          string `env:"USER,unset,required"`
		Password      string `env:"PASS,unset,required"`
		TLS           bool   `env:"TLS" envDefault:"false"`
		ExchangeEvent string `env:"EXCHANGE_EVENT" envDefault:"events"`
	}

	VideoConfig struct {
		Retention time.Duration `env:"RETENTION" envDefault:"8760h"`
	}

	AuthConfig struct {
		JWT     JWTConfig     `envPrefix:"JWT_"`
		Session SessionConfig `envPrefix:"SESSION_"`
	}

	JWTConfig struct {
		Exp    time.Duration `env:"EXP" envDefault:"15m"`
		Secret string        `env:"SECRET" envDefault:"jwt_secret"`
	}

	SessionConfig struct {
		Exp         time.Duration `env:"EXP" envDefault:"168h"`
		RememberExp time.Duration `env:"REMEMBER_EXP" envDefault:"720h"`
		Secret      string        `env:"SECRET" envDefault:"session_secret"`
	}

	HTTPConfig struct {
		Port  int  `env:"PORT" envDefault:"8080"`
		HTTPS bool `env:"HTTPS" envDefault:"false"`
	}

	LogConfig struct {
		Pretty bool   `env:"PRETTY" envDefault:"false"`
		Level  string `env:"LEVEL" envDefault:"info"`
	}
)

func (c *DBConfig) DSN() string {
	u := url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(c.User, c.Password),
		Host:     fmt.Sprintf("%s:%d", c.Host, c.Port),
		Path:     "/" + c.Name,
		RawQuery: c.Params,
	}
	return u.String()
}

func (c *QueueConfig) DSN() string {
	scheme := "amqp"
	if c.TLS {
		scheme += "s"
	}
	u := url.URL{
		Scheme: scheme,
		User:   url.UserPassword(c.User, c.Password),
		Host:   fmt.Sprintf("%s:%d", c.Host, c.Port),
		Path:   "/",
	}
	return u.String()
}

func Load() (Config, error) {
	cfg := Config{}
	if err := env.Parse(&cfg); err != nil {
		return Config{}, err
	}
	return cfg, nil
}
