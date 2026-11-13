// @date 2026-11-14
// @file config_test.go
// @brief Unit tests of the environment configuration: required variables, defaults and DSNs.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package config

import (
	"net/url"
	"os"
	"strings"
	"testing"
	"time"
)

// requiredEnv holds every variable Load cannot do without.
var requiredEnv = map[string]string{
	"POSTGRES_DB":       "ascension",
	"POSTGRES_USER":     "ascension",
	"POSTGRES_PASSWORD": "db-password",
	"STORAGE_ENDPOINT":  "http://localhost:9000",
	"STORAGE_REGION":    "eu-west-1",
	"STORAGE_ID":        "access-key",
	"STORAGE_SECRET":    "secret-key",
	"STORAGE_BUCKET":    "videos",
	"QUEUE_USER":        "guest",
	"QUEUE_PASS":        "guest-password",
}

// optionalEnv holds the variables that have a default, cleared so the host environment
// does not leak into the tests.
var optionalEnv = []string{
	"POSTGRES_HOST", "POSTGRES_PORT", "POSTGRES_PARAMS",
	"STORAGE_UPLOAD_EXP", "STORAGE_DOWNLOAD_EXP",
	"QUEUE_HOST", "QUEUE_PORT", "QUEUE_TLS", "QUEUE_EXCHANGE_EVENT",
	"VIDEO_RETENTION",
	"AUTH_JWT_EXP", "AUTH_JWT_SECRET", "AUTH_SESSION_EXP", "AUTH_SESSION_REMEMBER_EXP", "AUTH_SESSION_SECRET",
	"PORT", "HTTPS",
	"LOG_PRETTY", "LOG_LEVEL",
}

// unsetEnv removes the variable for the test and restores it afterwards.
func unsetEnv(t *testing.T, key string) {
	t.Helper()

	t.Setenv(key, "")
	if err := os.Unsetenv(key); err != nil {
		t.Fatalf("Unsetenv(%s) error = %v", key, err)
	}
}

// setRequiredEnv sets the required variables and clears the optional ones.
func setRequiredEnv(t *testing.T) {
	t.Helper()

	for _, key := range optionalEnv {
		unsetEnv(t, key)
	}
	for key, value := range requiredEnv {
		t.Setenv(key, value)
	}
}

func TestLoadDefaults(t *testing.T) {
	setRequiredEnv(t)

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	checks := []struct {
		name string
		got  any
		want any
	}{
		{"DB.Host", cfg.DB.Host, "localhost"},
		{"DB.Port", cfg.DB.Port, 5432},
		{"DB.Name", cfg.DB.Name, "ascension"},
		{"DB.Params", cfg.DB.Params, "sslmode=disable"},
		{"Storage.BucketName", cfg.Storage.BucketName, "videos"},
		{"Storage.UploadExp", cfg.Storage.UploadExp, time.Hour},
		{"Storage.DownloadExp", cfg.Storage.DownloadExp, time.Hour},
		{"Queue.Host", cfg.Queue.Host, "localhost"},
		{"Queue.Port", cfg.Queue.Port, 5672},
		{"Queue.TLS", cfg.Queue.TLS, false},
		{"Queue.ExchangeEvent", cfg.Queue.ExchangeEvent, "events"},
		{"Video.Retention", cfg.Video.Retention, 8760 * time.Hour},
		{"Auth.JWT.Exp", cfg.Auth.JWT.Exp, 15 * time.Minute},
		{"Auth.Session.Exp", cfg.Auth.Session.Exp, 168 * time.Hour},
		{"Auth.Session.RememberExp", cfg.Auth.Session.RememberExp, 720 * time.Hour},
		{"HTTP.Port", cfg.HTTP.Port, 8080},
		{"HTTP.HTTPS", cfg.HTTP.HTTPS, false},
		{"Log.Pretty", cfg.Log.Pretty, false},
		{"Log.Level", cfg.Log.Level, "info"},
	}
	for _, check := range checks {
		if check.got != check.want {
			t.Errorf("%s = %v, want %v", check.name, check.got, check.want)
		}
	}
}

func TestLoadOverrides(t *testing.T) {
	setRequiredEnv(t)
	t.Setenv("POSTGRES_HOST", "db.internal")
	t.Setenv("POSTGRES_PORT", "6543")
	t.Setenv("STORAGE_UPLOAD_EXP", "15m")
	t.Setenv("STORAGE_DOWNLOAD_EXP", "2h")
	t.Setenv("QUEUE_TLS", "true")
	t.Setenv("AUTH_JWT_SECRET", "a-real-secret")
	t.Setenv("PORT", "9090")
	t.Setenv("LOG_LEVEL", "debug")
	t.Setenv("LOG_PRETTY", "true")

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	if cfg.DB.Host != "db.internal" || cfg.DB.Port != 6543 {
		t.Errorf("DB = %s:%d, want db.internal:6543", cfg.DB.Host, cfg.DB.Port)
	}
	if cfg.Storage.UploadExp != 15*time.Minute || cfg.Storage.DownloadExp != 2*time.Hour {
		t.Errorf("Storage expiries = %v / %v, want 15m / 2h", cfg.Storage.UploadExp, cfg.Storage.DownloadExp)
	}
	if !cfg.Queue.TLS {
		t.Error("Queue.TLS = false, want true")
	}
	if cfg.Auth.JWT.Secret != "a-real-secret" {
		t.Errorf("Auth.JWT.Secret = %q, want a-real-secret", cfg.Auth.JWT.Secret)
	}
	if cfg.HTTP.Port != 9090 {
		t.Errorf("HTTP.Port = %d, want 9090", cfg.HTTP.Port)
	}
	if cfg.Log.Level != "debug" || !cfg.Log.Pretty {
		t.Errorf("Log = %+v, want debug and pretty", cfg.Log)
	}
}

// The secrets are tagged "unset": Load removes them from the environment so that child
// processes and crash dumps do not see them.
func TestLoadUnsetsTheSecrets(t *testing.T) {
	setRequiredEnv(t)

	if _, err := Load(); err != nil {
		t.Fatalf("Load() error = %v", err)
	}

	for _, key := range []string{"POSTGRES_PASSWORD", "STORAGE_SECRET", "STORAGE_ID", "QUEUE_PASS"} {
		if value, ok := os.LookupEnv(key); ok {
			t.Errorf("%s = %q after Load, want it unset", key, value)
		}
	}
	if _, ok := os.LookupEnv("STORAGE_BUCKET"); !ok {
		t.Error("STORAGE_BUCKET was unset, want it kept: it is not a secret")
	}
}

func TestLoadRequiresVariables(t *testing.T) {
	for key := range requiredEnv {
		t.Run(key, func(t *testing.T) {
			setRequiredEnv(t)
			unsetEnv(t, key)

			_, err := Load()
			if err == nil {
				t.Fatalf("Load() error = nil, want an error for the missing %s", key)
			}
			if !strings.Contains(err.Error(), key) {
				t.Errorf("Load() error = %v, want it to name %s", err, key)
			}
		})
	}
}

func TestLoadRejectsInvalidValues(t *testing.T) {
	for key, value := range map[string]string{
		"POSTGRES_PORT":      "not-a-port",
		"STORAGE_UPLOAD_EXP": "one hour",
		"QUEUE_TLS":          "maybe",
		"PORT":               "80a",
	} {
		t.Run(key, func(t *testing.T) {
			setRequiredEnv(t)
			t.Setenv(key, value)

			if _, err := Load(); err == nil {
				t.Fatalf("Load() error = nil, want an error for %s=%q", key, value)
			}
		})
	}
}

func TestDBConfigDSN(t *testing.T) {
	cfg := DBConfig{Host: "db", Port: 5432, Name: "ascension", User: "app", Password: "p@ss:/word?", Params: "sslmode=require"}

	dsn := cfg.DSN()

	u, err := url.Parse(dsn)
	if err != nil {
		t.Fatalf("Parse(%q) error = %v", dsn, err)
	}
	if u.Scheme != "postgres" || u.Host != "db:5432" || u.Path != "/ascension" || u.RawQuery != "sslmode=require" {
		t.Errorf("DSN = %q, want postgres://…@db:5432/ascension?sslmode=require", dsn)
	}
	if password, _ := u.User.Password(); u.User.Username() != "app" || password != "p@ss:/word?" {
		t.Errorf("DSN user = %v, want app with the password escaped and round-tripped", u.User)
	}
}

func TestQueueConfigDSN(t *testing.T) {
	tests := []struct {
		name string
		tls  bool
		want string
	}{
		{name: "plain", tls: false, want: "amqp://guest:pa%2Fss@rabbit:5672/"},
		{name: "tls", tls: true, want: "amqps://guest:pa%2Fss@rabbit:5672/"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := QueueConfig{Host: "rabbit", Port: 5672, User: "guest", Password: "pa/ss", TLS: tt.tls}

			if got := cfg.DSN(); got != tt.want {
				t.Errorf("DSN() = %q, want %q", got, tt.want)
			}
		})
	}
}
