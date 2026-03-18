package rabbitmq

import (
	"fmt"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/setup/config"
	"github.com/rabbitmq/amqp091-go"
)

type RabbitMQ struct {
	conn *amqp091.Connection
	ch   *amqp091.Channel
	cfg  *config.RabbitMQConfig
	qAI  amqp091.Queue
}

func New(cfg *config.RabbitMQConfig) (RabbitMQ, error) {
	conn, err := amqp091.Dial(cfg.DSN())
	if err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	ch, err := conn.Channel()
	if err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	qAI, err := ch.QueueDeclare(cfg.QueueAI, true, false, false, false, nil)
	if err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	err = ch.ExchangeDeclare(cfg.QueueServer, amqp091.ExchangeTopic, true, false, false, false, nil)
	if err != nil {
		return RabbitMQ{}, fmt.Errorf("RabbitMQ.New: %w", err)
	}

	return RabbitMQ{conn: conn, ch: ch, cfg: cfg, qAI: qAI}, nil
}
