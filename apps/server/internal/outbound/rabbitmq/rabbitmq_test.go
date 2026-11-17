// @date 2026-11-13
// @file rabbitmq_test.go
// @brief Unit tests of the topology shared with the AI worker and of the broker connection errors.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rabbitmq

import (
	"net"
	"strings"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
)

// The AI worker declares the same queue (apps/ai/src/services/rabbitmq.py): any other
// argument makes RabbitMQ refuse the second declaration with PRECONDITION_FAILED.
func TestPoseDetectQueueMatchesTheWorker(t *testing.T) {
	if queuePoseDetect != "poses.detect" || routingKeyPoseDetectRequested != "pose.detect.requested" {
		t.Errorf("queue %q / routing key %q, want poses.detect / pose.detect.requested", queuePoseDetect, routingKeyPoseDetectRequested)
	}

	args := poseDetectQueueArgs()
	want := map[string]string{
		"x-dead-letter-exchange":    "events.dlx",
		"x-dead-letter-routing-key": "poses.detect.dlq",
	}
	if len(args) != len(want) {
		t.Fatalf("queue arguments = %v, want %v", args, want)
	}
	for key, value := range want {
		if args[key] != value {
			t.Errorf("argument %s = %v, want %s", key, args[key], value)
		}
	}
}

// freePort returns a local port nothing listens on.
func freePort(t *testing.T) int {
	t.Helper()

	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}
	port := l.Addr().(*net.TCPAddr).Port
	if err := l.Close(); err != nil {
		t.Fatalf("Close() error = %v", err)
	}

	return port
}

func TestNewFailsWithoutBroker(t *testing.T) {
	cfg := config.QueueConfig{Host: "127.0.0.1", Port: freePort(t), User: "guest", Password: "guest", ExchangeEvent: "events"}

	_, err := New(cfg)
	if err == nil {
		t.Fatal("New() error = nil, want the connection error")
	}
	if !strings.HasPrefix(err.Error(), "RabbitMQ.New:") {
		t.Errorf("New() error = %v, want it wrapped by RabbitMQ.New", err)
	}
}

// A server that closes the connection before the AMQP handshake is not a broker.
func TestNewFailsOnAServerThatIsNotABroker(t *testing.T) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("Listen() error = %v", err)
	}
	t.Cleanup(func() { _ = l.Close() })
	go func() {
		for {
			conn, err := l.Accept()
			if err != nil {
				return
			}
			_ = conn.SetDeadline(time.Now().Add(time.Second))
			_, _ = conn.Write([]byte("HTTP/1.1 400 Bad Request\r\n\r\n"))
			_ = conn.Close()
		}
	}()

	cfg := config.QueueConfig{Host: "127.0.0.1", Port: l.Addr().(*net.TCPAddr).Port, User: "guest", Password: "guest", ExchangeEvent: "events"}

	if _, err := New(cfg); err == nil {
		t.Fatal("New() error = nil, want the handshake error")
	}
}
