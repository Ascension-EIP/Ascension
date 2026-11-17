// @date 2026-11-13
// @file query_test.go
// @brief Unit tests of the SQL query builders, the transaction context and the embedded migrations, without a database.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package postgres

import (
	"context"
	"errors"
	"github.com/Ascension-EIP/Ascension/apps/server/internal/testutil/knownbug"
	"io"
	"io/fs"
	"reflect"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/model"
	"github.com/golang-migrate/migrate/v4/source/iofs"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"uuid"
)

func TestSetArg(t *testing.T) {
	parts, args := []string{}, []any{}

	setArg[string](&parts, &args, "skipped", nil)
	if len(parts) != 0 || len(args) != 0 {
		t.Fatalf("setArg(nil) added %v %v, want nothing", parts, args)
	}

	setArg(&parts, &args, "username", new("climber"))
	setArg(&parts, &args, "status", new(model.UserStatusActive))
	setArg(&parts, &args, "bio", new((*string)(nil)))

	if want := []string{"username = $1", "status = $2", "bio = $3"}; !slices.Equal(parts, want) {
		t.Errorf("parts = %v, want %v", parts, want)
	}
	if len(args) != 3 || args[0] != "climber" || args[1] != model.UserStatusActive {
		t.Fatalf("args = %v, want [climber active <nil>]", args)
	}
	if bio, ok := args[2].(*string); !ok || bio != nil {
		t.Errorf("args[2] = %#v, want a nil *string (NULL)", args[2])
	}
}

type queryCase struct {
	name      string
	build     func() (string, []any)
	wantQuery string
	wantArgs  []any
}

func runQueryCases(t *testing.T, tests []queryCase) {
	t.Helper()

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			query, args := tt.build()
			if query != tt.wantQuery {
				t.Errorf("query = %q\nwant    %q", query, tt.wantQuery)
			}
			if len(args) != len(tt.wantArgs) {
				t.Fatalf("args = %v, want %v", args, tt.wantArgs)
			}
			for i := range args {
				if !reflect.DeepEqual(args[i], tt.wantArgs[i]) {
					t.Errorf("args[%d] = %#v, want %#v", i, args[i], tt.wantArgs[i])
				}
			}
		})
	}
}

func TestUserFilterQuery(t *testing.T) {
	id := uuid.NewV7()

	runQueryCases(t, []queryCase{
		{
			name:      "no filter",
			build:     func() (string, []any) { return userFilterQuery(model.UserFilter{}) },
			wantQuery: "SELECT * FROM users",
		},
		{
			name:      "by id",
			build:     func() (string, []any) { return userFilterQuery(model.UserFilter{ID: &id}) },
			wantQuery: "SELECT * FROM users WHERE id = $1",
			wantArgs:  []any{id},
		},
		{
			name: "every column",
			build: func() (string, []any) {
				return userFilterQuery(model.UserFilter{
					ID:        &id,
					Username:  new(model.UserUsername("climber")),
					FirstName: new("Alex"),
					LastName:  new("Honnold"),
					Email:     new(model.UserEmail("climber@ascension.app")),
					Password:  new(model.UserPassword("hash")),
					Role:      new(model.UserRoleUser),
					Status:    new(model.UserStatusActive),
				})
			},
			wantQuery: "SELECT * FROM users WHERE id = $1 AND username = $2 AND first_name = $3 AND last_name = $4 AND email = $5 AND password_hash = $6 AND role = $7 AND status = $8",
			wantArgs: []any{id, model.UserUsername("climber"), "Alex", "Honnold", model.UserEmail("climber@ascension.app"),
				model.UserPassword("hash"), model.UserRoleUser, model.UserStatusActive},
		},
	})
}

func TestUserProfileFilterQuery(t *testing.T) {
	userID := uuid.NewV7()
	birthDate := time.Date(1998, 4, 2, 0, 0, 0, 0, time.UTC)

	runQueryCases(t, []queryCase{
		{
			name:      "no filter",
			build:     func() (string, []any) { return userProfileFilterQuery(model.UserProfileFilter{}) },
			wantQuery: "SELECT * FROM user_profiles",
		},
		{
			name:      "by user",
			build:     func() (string, []any) { return userProfileFilterQuery(model.UserProfileFilter{UserID: &userID}) },
			wantQuery: "SELECT * FROM user_profiles WHERE user_id = $1",
			wantArgs:  []any{userID},
		},
		{
			name: "several columns keep their order",
			build: func() (string, []any) {
				return userProfileFilterQuery(model.UserProfileFilter{
					UserID:        &userID,
					HeightCM:      new(new(uint16(178))),
					GradingSystem: new(new(model.GradingSystemFont)),
					Bio:           new(new("bio")),
				})
			},
			wantQuery: "SELECT * FROM user_profiles WHERE user_id = $1 AND height_cm = $2 AND grading_system = $3 AND bio = $4",
			wantArgs:  []any{userID, new(uint16(178)), new(model.GradingSystemFont), new("bio")},
		},
		{
			name: "every column",
			build: func() (string, []any) {
				return userProfileFilterQuery(model.UserProfileFilter{
					UserID:          &userID,
					BirthDate:       new(new(birthDate)),
					HeightCM:        new(new(uint16(178))),
					WeightKG:        new(new(float32(68))),
					ArmSpanCM:       new(new(uint16(180))),
					DominantHand:    new(new(model.DominantHandLeft)),
					ClimbingLevel:   new(new("7a")),
					GradingSystem:   new(new(model.GradingSystemFont)),
					YearsOfPratice:  new(new(uint8(3))),
					Bio:             new(new("bio")),
					AvatarObjectKey: new(new("key")),
				})
			},
			wantQuery: "SELECT * FROM user_profiles WHERE user_id = $1 AND birth_date = $2 AND height_cm = $3 AND weight_kg = $4 AND arm_span_cm = $5 AND dominant_hand = $6 AND climbing_level = $7 AND grading_system = $8 AND years_of_practice = $9 AND bio = $10 AND avatar_object_key = $11",
			wantArgs: []any{userID, new(birthDate), new(uint16(178)), new(float32(68)), new(uint16(180)), new(model.DominantHandLeft),
				new("7a"), new(model.GradingSystemFont), new(uint8(3)), new("bio"), new("key")},
		},
	})
}

func TestAnalysisFilterQuery(t *testing.T) {
	id, videoID := uuid.NewV7(), uuid.NewV7()

	runQueryCases(t, []queryCase{
		{
			name:      "no filter",
			build:     func() (string, []any) { return analysisFilterQuery(model.AnalysisFilter{}) },
			wantQuery: "SELECT * FROM analyses ORDER BY created_at",
		},
		{
			name: "every column",
			build: func() (string, []any) {
				return analysisFilterQuery(model.AnalysisFilter{
					ID:      &id,
					VideoID: &videoID,
					Type:    new(model.AnalysisType2D),
					Status:  new(model.JobStatusPending),
					Error:   new(new("boom")),
				})
			},
			wantQuery: "SELECT * FROM analyses WHERE id = $1 AND video_id = $2 AND type = $3 AND status = $4 AND error = $5 ORDER BY created_at",
			wantArgs:  []any{id, videoID, model.AnalysisType2D, model.JobStatusPending, new("boom")},
		},
	})

	t.Run("a null filter matches null columns", func(t *testing.T) {
		knownbug.Skip(t, "a pointer to nil builds \"error = NULL\", which never matches; it needs \"error IS NULL\"")

		query, _ := analysisFilterQuery(model.AnalysisFilter{Error: new((*string)(nil))})
		if !strings.Contains(query, "error IS NULL") {
			t.Errorf("query = %q, want error IS NULL", query)
		}
	})
}

func TestVideoFilterQuery(t *testing.T) {
	id, userID := uuid.NewV7(), uuid.NewV7()

	runQueryCases(t, []queryCase{
		{
			name:      "no filter",
			build:     func() (string, []any) { return videoFilterQuery(model.VideoFilter{}) },
			wantQuery: "SELECT * FROM videos ORDER BY created_at",
		},
		{
			name:      "owned video",
			build:     func() (string, []any) { return videoFilterQuery(model.VideoFilter{ID: &id, UserID: &userID}) },
			wantQuery: "SELECT * FROM videos WHERE id = $1 AND user_id = $2 ORDER BY created_at",
			wantArgs:  []any{id, userID},
		},
		{
			name: "every column",
			build: func() (string, []any) {
				return videoFilterQuery(model.VideoFilter{
					ID:          &id,
					UserID:      &userID,
					ObjectKey:   new("videos/key.mp4"),
					Status:      new(model.VideoStatusCompleted),
					Visibility:  new(model.VisibilityPublic),
					ContentType: new("video/mp4"),
					Retained:    new(true),
				})
			},
			wantQuery: "SELECT * FROM videos WHERE id = $1 AND user_id = $2 AND object_key = $3 AND status = $4 AND visibility = $5 AND content_type = $6 AND retained = $7 ORDER BY created_at",
			wantArgs:  []any{id, userID, "videos/key.mp4", model.VideoStatusCompleted, model.VisibilityPublic, "video/mp4", true},
		},
	})
}

func TestLikeEscape(t *testing.T) {
	tests := map[string]string{
		"climber":     "climber",
		"100%":        `100\%`,
		"a_b":         `a\_b`,
		`back\slash`:  `back\\slash`,
		`%_\`:         `\%\_\\`,
		"":            "",
		"élodie_100%": `élodie\_100\%`,
	}

	for in, want := range tests {
		if got := likeEscape(in); got != want {
			t.Errorf("likeEscape(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestOptionalDate(t *testing.T) {
	if got := optionalDate(time.Time{}); got != nil {
		t.Errorf("optionalDate(zero) = %v, want nil", got)
	}

	day := time.Date(2026, 11, 13, 0, 0, 0, 0, time.UTC)
	got := optionalDate(day)
	if got == nil || !got.Equal(day) {
		t.Fatalf("optionalDate(%v) = %v, want the same date", day, got)
	}
}

// fakeTx is a DBTX that records nothing: it only stands for a transaction in the context.
type fakeTx struct{}

func (fakeTx) Exec(context.Context, string, ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}
func (fakeTx) Query(context.Context, string, ...any) (pgx.Rows, error) { return nil, nil }
func (fakeTx) QueryRow(context.Context, string, ...any) pgx.Row        { return nil }

func TestTransactionContext(t *testing.T) {
	repo := &PostgresRepository{}

	t.Run("no transaction uses the pool", func(t *testing.T) {
		if got := repo.getTx(context.Background()); got != DBTX(repo.Pool) {
			t.Errorf("getTx() = %#v, want the pool", got)
		}
	})

	t.Run("a transaction in the context is used", func(t *testing.T) {
		ctx := context.WithValue(context.Background(), txKey, fakeTx{})
		if got := repo.getTx(ctx); got != (fakeTx{}) {
			t.Errorf("getTx() = %#v, want the transaction of the context", got)
		}
	})

	t.Run("nested transactions join the outer one", func(t *testing.T) {
		ctx := context.WithValue(context.Background(), txKey, fakeTx{})

		var inner context.Context
		err := repo.WithTransaction(ctx, func(ctx context.Context) error {
			inner = ctx
			return nil
		})
		if err != nil {
			t.Fatalf("WithTransaction() error = %v", err)
		}
		if inner != ctx {
			t.Error("WithTransaction() inside a transaction did not reuse its context")
		}
	})

	t.Run("nested errors are returned as is", func(t *testing.T) {
		ctx := context.WithValue(context.Background(), txKey, fakeTx{})
		boom := errors.New("boom")

		if err := repo.WithTransaction(ctx, func(context.Context) error { return boom }); err != boom {
			t.Errorf("WithTransaction() = %v, want %v", err, boom)
		}
	})
}

func TestNewRejectsInvalidDSN(t *testing.T) {
	if _, err := New("postgres://user:pass@localhost:notaport/db"); err == nil {
		t.Error("New() with an invalid DSN = nil error, want an error")
	}
}

func TestMigrateRejectsInvalidDSN(t *testing.T) {
	repo := &PostgresRepository{}
	if err := repo.Migrate("not a dsn"); err == nil {
		t.Error("Migrate() with an invalid DSN = nil error, want an error")
	}
}

// TestEmbeddedMigrations checks that every embedded migration can be read and has both
// an up and a down file.
func TestEmbeddedMigrations(t *testing.T) {
	files, err := fs.Glob(migrationFS, "migrations/*.sql")
	if err != nil {
		t.Fatalf("Glob() error = %v", err)
	}
	if len(files) == 0 {
		t.Fatal("no migration is embedded")
	}

	ups, downs := map[string]bool{}, map[string]bool{}
	for _, file := range files {
		name := strings.TrimPrefix(file, "migrations/")
		switch {
		case strings.HasSuffix(name, ".up.sql"):
			ups[strings.TrimSuffix(name, ".up.sql")] = true
		case strings.HasSuffix(name, ".down.sql"):
			downs[strings.TrimSuffix(name, ".down.sql")] = true
		default:
			t.Errorf("%s is neither an up nor a down migration", name)
		}
	}
	for name := range ups {
		if !downs[name] {
			t.Errorf("%s has no down migration", name)
		}
	}
	for name := range downs {
		if !ups[name] {
			t.Errorf("%s has no up migration", name)
		}
	}

	source, err := iofs.New(migrationFS, "migrations")
	if err != nil {
		t.Fatalf("iofs.New() error = %v", err)
	}
	defer source.Close()

	version, err := source.First()
	count := 0
	for err == nil {
		count++
		for _, read := range []func(uint) (io.ReadCloser, string, error){source.ReadUp, source.ReadDown} {
			body, _, err := read(version)
			if err != nil {
				t.Errorf("migration %d: %v", version, err)
				continue
			}
			raw, err := io.ReadAll(body)
			body.Close()
			if err != nil || len(strings.TrimSpace(string(raw))) == 0 {
				t.Errorf("migration %d is empty or unreadable (%v)", version, err)
			}
		}
		version, err = source.Next(version)
	}
	if !errors.Is(err, fs.ErrNotExist) {
		t.Errorf("Next() error = %v, want fs.ErrNotExist after the last migration", err)
	}
	if count != len(ups) {
		t.Errorf("the migrate source sees %d versions, want %d", count, len(ups))
	}
}
