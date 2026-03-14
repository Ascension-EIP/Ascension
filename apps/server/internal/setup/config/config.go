package config

import (
	"fmt"
	"net/url"
	"time"

	"github.com/caarlos0/env/v11"
)

type (
	Config struct {
		DB    DBConfig    `envPrefix:"DB_"`
		MinIO MinIOConfig `envPrefix:"MINIO_"`
		Auth  AuthConfig  `envPrefix:"AUTH_"`
		HTTP  HTTPConfig
		Log   LogConfig `envPrefix:"LOG_"`
	}

	DBConfig struct {
		Host      string `env:"HOST" envDefault:"localhost"`
		Port      int    `env:"PORT" envDefault:"5432"`
		Name      string `env:"NAME,unset,required"`
		User      string `env:"USER,unset,required"`
		Password  string `env:"PASS,unset,required"`
		Params    string `env:"PARAMS" envDefault:"sslmode=disable"`
		Migration string `env:"MIGRATION"`
	}

	MinIOConfig struct {
		Endpoint    string        `env:"ENDPOINT,unset,required"`
		ID          string        `env:"ID,unset,required"`
		Secret      string        `env:"SECRET,unset,required"`
		BucketName  string        `env:"BUCKET,required"`
		SSL         bool          `env:"SSL" envDefault:"false"`
		UploadExp   time.Duration `env:"UPLOAD_EXP" envDefault:"1h"`
		DownloadExp time.Duration `env:"DOWNLAOD_EXP" envDefault:"1h"`
	}

	AuthConfig struct {
		JWT     JWTConfig     `envPrefix:"JWT_"`
		Session SessionConfig `envPrefix:"SESSION_"`
	}

	JWTConfig struct {
		Exp    time.Duration `env:"EXP" envDefault:"15m"`
		Secret string        `env:"SECRET" envDefault:"user_session"`
	}

	SessionConfig struct {
		Exp         time.Duration `env:"EXP" envDefault:"168h"`
		RememberExp time.Duration `env:"REMEMBER_EXP" envDefault:"720h"`
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

func (c DBConfig) DSN() string {
	u := &url.URL{
		Scheme:   "postgres",
		User:     url.UserPassword(c.User, c.Password),
		Host:     fmt.Sprintf("%s:%d", c.Host, c.Port),
		Path:     "/" + c.Name,
		RawQuery: c.Params,
	}
	return u.String()
}

func Load() (*Config, error) {
	cfg := &Config{}
	if err := env.Parse(cfg); err != nil {
		return nil, err
	}
	return cfg, nil
}
