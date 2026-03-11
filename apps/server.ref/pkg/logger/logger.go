package logger

import (
	"fmt"
	"os"

	"github.com/rs/zerolog"
)

const (
	green   = "\033[97;42m"
	white   = "\033[90;47m"
	yellow  = "\033[90;43m"
	red     = "\033[97;41m"
	blue    = "\033[97;44m"
	magenta = "\033[97;45m"
	cyan    = "\033[97;46m"
	reset   = "\033[0m"
)

type Logger struct {
	log zerolog.Logger
}

func New(level string, pretty bool) *Logger {
	lvl, err := zerolog.ParseLevel(level)
	if err != nil {
		lvl = zerolog.InfoLevel
	}

	zerolog.SetGlobalLevel(lvl)
	zerolog.TimeFieldFormat = "2006/01/02 - 15:04:05"

	var lg zerolog.Logger
	if pretty {
		lg = zerolog.New(zerolog.ConsoleWriter{
			Out:        os.Stdout,
			TimeFormat: "2006/01/02 - 15:04:05",
			FormatLevel: func(i any) string {
				switch i {
				case "debug":
					return fmt.Sprintf("|%s DEBUG %s|", magenta, reset)
				case "info":
					return fmt.Sprintf("|%s INFO  %s|", green, reset)
				case "warn":
					return fmt.Sprintf("|%s WARN  %s|", yellow, reset)
				case "error":
					return fmt.Sprintf("|%s ERROR %s|", red, reset)
				case "fatal":
					return fmt.Sprintf("|%s FATAL %s|", red, reset)
				case "panic":
					return fmt.Sprintf("|%s PANIC %s|", red, reset)
				default:
					return fmt.Sprintf("|%s ????? %s|", white, reset)
				}
			},
			FormatMessage: func(i any) string {
				if i == nil {
					return ""
				}
				return fmt.Sprintf("%v", i)
			},
			FormatFieldName: func(i any) string {
				return fmt.Sprintf("%v=", i)
			},
			FormatFieldValue: func(i any) string {
				return fmt.Sprintf("%v", i)
			},
			FormatTimestamp: func(i any) string {
				return fmt.Sprintf("%v", i)
			},
			FormatCaller: func(i any) string {
				return ""
			},
			PartsOrder: []string{
				zerolog.TimestampFieldName,
				zerolog.LevelFieldName,
				zerolog.MessageFieldName,
			},
		}).With().Timestamp().Logger()
	} else {
		lg = zerolog.New(os.Stdout).With().Timestamp().Caller().Logger()
	}

	return &Logger{log: lg}
}

func (l *Logger) Debug() *zerolog.Event {
	return l.log.Debug()
}

func (l *Logger) Info() *zerolog.Event {
	return l.log.Info()
}

func (l *Logger) Warn() *zerolog.Event {
	return l.log.Warn()
}

func (l *Logger) Error() *zerolog.Event {
	return l.log.Error()
}

func (l *Logger) Fatal() *zerolog.Event {
	return l.log.Fatal()
}

func (l *Logger) Panic() *zerolog.Event {
	return l.log.Panic()
}

func (l *Logger) With() zerolog.Context {
	return l.log.With()
}

func (l *Logger) Zerolog() zerolog.Logger {
	return l.log
}
