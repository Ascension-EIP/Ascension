// @date 2026-11-13
// @file rabbitmq.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rabbitmq

import (
	"fmt"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/rabbitmq/amqp091-go"
)

// Topology shared with the AI worker (apps/ai/src/services/rabbitmq.py and
// schemas/routing_key.schema.json). The worker declares the same objects with the same
// arguments: both sides declare them, so a job published before the worker ever started
// waits in its queue instead of being dropped.
const (
	RoutingKeyPoseDetectRequested = "pose.detect.requested"
	QueuePoseDetect               = "poses.detect"
	deadLetterExchange            = "events.dlx"
)

type RabbitMQ struct {
	conn *amqp091.Connection
	ch   *amqp091.Channel
	cfg  config.RabbitMQConfig
}

func New(cfg config.RabbitMQConfig) (RabbitMQ, error) {
	conn, err := amqp091.Dial(cfg.DSN())
	if err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	if err := declareTopology(ch, cfg.Exchange); err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	return RabbitMQ{conn: conn, ch: ch, cfg: cfg}, nil
}

// declareTopology declares the exchange and the pose detection queue exactly as the AI
// worker does: different arguments would make RabbitMQ refuse the declaration.
func declareTopology(ch *amqp091.Channel, exchange string) error {
	if err := ch.ExchangeDeclare(exchange, amqp091.ExchangeTopic, true, false, false, false, nil); err != nil {
		return fmt.Errorf("declare exchange %s: %w", exchange, err)
	}
	if _, err := ch.QueueDeclare(QueuePoseDetect, true, false, false, false, poseDetectQueueArgs()); err != nil {
		return fmt.Errorf("declare queue %s: %w", QueuePoseDetect, err)
	}
	if err := ch.QueueBind(QueuePoseDetect, RoutingKeyPoseDetectRequested, exchange, false, nil); err != nil {
		return fmt.Errorf("bind queue %s: %w", QueuePoseDetect, err)
	}
	return nil
}

// poseDetectQueueArgs are the arguments of the pose detection queue: a job the worker
// rejects for good goes to the "poses.detect.dlq" queue through the dead-letter exchange.
func poseDetectQueueArgs() amqp091.Table {
	return amqp091.Table{
		"x-dead-letter-exchange":    deadLetterExchange,
		"x-dead-letter-routing-key": QueuePoseDetect + ".dlq",
	}
}
