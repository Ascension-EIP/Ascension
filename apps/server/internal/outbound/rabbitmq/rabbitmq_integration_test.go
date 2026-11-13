// @date 2026-11-14
// @file rabbitmq_integration_test.go
// @brief Integration tests of the message flow to the AI worker against a real RabbitMQ, skipped without TEST_RABBITMQ_URL.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rabbitmq

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"os"
	"strconv"
	"testing"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/rabbitmq/amqp091-go"
)

// EnvURL names the variable holding the address of a throwaway RabbitMQ,
// e.g. amqp://ascension:ascension@localhost:5672/. The tests purge the job queues.
const EnvURL = "TEST_RABBITMQ_URL"

// deadLetterQueue is the queue the worker binds to the dead-letter exchange
// for the rejected pose detection jobs (apps/ai/src/services/rabbitmq.py).
const deadLetterQueue = queuePoseDetect + ".dlq"

// brokerConfig returns the configuration of the test broker, with an exchange of the
// test's own, or skips the test when no broker is given.
func brokerConfig(t *testing.T) config.QueueConfig {
	t.Helper()

	raw := os.Getenv(EnvURL)
	if raw == "" {
		t.Skipf("%s is not set: skipping the RabbitMQ integration test", EnvURL)
	}
	u, err := url.Parse(raw)
	if err != nil {
		t.Fatalf("parse %s: %v", EnvURL, err)
	}
	port, err := strconv.Atoi(u.Port())
	if err != nil {
		t.Fatalf("%s has no port: %v", EnvURL, err)
	}
	password, _ := u.User.Password()

	return config.QueueConfig{
		Host:          u.Hostname(),
		Port:          port,
		User:          u.User.Username(),
		Password:      password,
		TLS:           u.Scheme == "amqps",
		ExchangeEvent: fmt.Sprintf("events-test-%d", time.Now().UnixNano()),
	}
}

// connect opens the server's connection, declares its topology and closes it at the end of the test.
func connect(t *testing.T, cfg config.QueueConfig) RabbitMQ {
	t.Helper()

	queue, err := New(cfg)
	if err != nil {
		t.Fatalf("New() error = %v", err)
	}
	t.Cleanup(func() { _ = queue.conn.Close() })

	return queue
}

// channel opens a second channel on the connection, as a consumer would.
func channel(t *testing.T, queue RabbitMQ) *amqp091.Channel {
	t.Helper()

	ch, err := queue.conn.Channel()
	if err != nil {
		t.Fatalf("open channel: %v", err)
	}
	t.Cleanup(func() { _ = ch.Close() })

	return ch
}

// declareWorkerDeadLetters declares the dead-letter exchange and queue as the worker does.
func declareWorkerDeadLetters(t *testing.T, ch *amqp091.Channel) {
	t.Helper()

	if err := ch.ExchangeDeclare(deadLetterExchange, amqp091.ExchangeDirect, true, false, false, false, nil); err != nil {
		t.Fatalf("declare %s: %v", deadLetterExchange, err)
	}
	if _, err := ch.QueueDeclare(deadLetterQueue, true, false, false, false, nil); err != nil {
		t.Fatalf("declare %s: %v", deadLetterQueue, err)
	}
	if err := ch.QueueBind(deadLetterQueue, deadLetterQueue, deadLetterExchange, false, nil); err != nil {
		t.Fatalf("bind %s: %v", deadLetterQueue, err)
	}
}

func purge(t *testing.T, ch *amqp091.Channel, queues ...string) {
	t.Helper()

	for _, name := range queues {
		if _, err := ch.QueuePurge(name, false); err != nil {
			t.Fatalf("purge %s: %v", name, err)
		}
	}
}

// get waits up to 5 s for a message on the queue.
func get(t *testing.T, ch *amqp091.Channel, queue string) amqp091.Delivery {
	t.Helper()

	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		msg, ok, err := ch.Get(queue, false)
		if err != nil {
			t.Fatalf("get from %s: %v", queue, err)
		}
		if ok {
			return msg
		}
		time.Sleep(50 * time.Millisecond)
	}
	t.Fatalf("no message on %s after 5s", queue)

	return amqp091.Delivery{}
}

func TestPublishPoseDetectRequestedReachesTheWorkerQueue(t *testing.T) {
	queue := connect(t, brokerConfig(t))
	ch := channel(t, queue)
	purge(t, ch, queuePoseDetect)

	body := []byte(`{"job_id":"018e6e5a-abcd-7ef0-1234-567890abcdef","object_key":"users/42/video.mp4"}`)
	if err := queue.PublishPoseDetectRequested(context.Background(), body); err != nil {
		t.Fatalf("PublishPoseDetectRequested() error = %v", err)
	}

	msg := get(t, ch, queuePoseDetect)
	if err := msg.Ack(false); err != nil {
		t.Fatalf("ack: %v", err)
	}
	if string(msg.Body) != string(body) {
		t.Errorf("body = %s, want %s", msg.Body, body)
	}
	if msg.Exchange != queue.cfg.ExchangeEvent || msg.RoutingKey != routingKeyPoseDetectRequested {
		t.Errorf("published to %q with %q, want %q with %q", msg.Exchange, msg.RoutingKey, queue.cfg.ExchangeEvent, routingKeyPoseDetectRequested)
	}
	if msg.ContentType != "application/json" {
		t.Errorf("content type = %q, want application/json", msg.ContentType)
	}
	if msg.DeliveryMode != amqp091.Persistent {
		t.Errorf("delivery mode = %d, want persistent: a broker restart would lose the job", msg.DeliveryMode)
	}
	if msg.Timestamp.IsZero() {
		t.Error("timestamp not set")
	}
}

// TestWorkerDeclarationIsAccepted declares the job queue a second time, as the worker does when it
// starts after the server: RabbitMQ accepts it only when every argument is the same.
func TestWorkerDeclarationIsAccepted(t *testing.T) {
	queue := connect(t, brokerConfig(t))

	if _, err := channel(t, queue).QueueDeclare(queuePoseDetect, true, false, false, false, poseDetectQueueArgs()); err != nil {
		t.Fatalf("worker declaration refused: %v", err)
	}

	// The check is real: other arguments are refused, and RabbitMQ closes the channel.
	_, err := channel(t, queue).QueueDeclare(queuePoseDetect, true, false, false, false, nil)
	var amqpErr *amqp091.Error
	if !errors.As(err, &amqpErr) || amqpErr.Code != amqp091.PreconditionFailed {
		t.Errorf("declaration without the dead-letter arguments: error = %v, want PRECONDITION_FAILED", err)
	}

	// Connecting again redeclares the same topology without error.
	connect(t, queue.cfg)
}

// TestRejectedJobGoesToTheDeadLetterQueue rejects a job as the worker does after a failure:
// the dead-letter arguments of the queue route it to the worker's dead-letter queue.
func TestRejectedJobGoesToTheDeadLetterQueue(t *testing.T) {
	queue := connect(t, brokerConfig(t))
	ch := channel(t, queue)
	declareWorkerDeadLetters(t, ch)
	purge(t, ch, queuePoseDetect, deadLetterQueue)

	body := []byte(`{"job_id":"018e6e5a-dead-7ef0-1234-567890abcdef","object_key":"users/42/broken.mp4"}`)
	if err := queue.PublishPoseDetectRequested(context.Background(), body); err != nil {
		t.Fatalf("PublishPoseDetectRequested() error = %v", err)
	}
	if err := get(t, ch, queuePoseDetect).Nack(false, false); err != nil {
		t.Fatalf("nack: %v", err)
	}

	dead := get(t, ch, deadLetterQueue)
	if err := dead.Ack(false); err != nil {
		t.Fatalf("ack: %v", err)
	}
	if string(dead.Body) != string(body) {
		t.Errorf("dead-lettered body = %s, want %s", dead.Body, body)
	}
}
