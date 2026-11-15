package rabbitmq

import (
	"context"
	"time"

	"github.com/rabbitmq/amqp091-go"
)

func (q *RabbitMQ) PublishPoseAdviceRequested(ctx context.Context, body []byte) error {
	if err := q.ch.PublishWithContext(ctx,
		q.cfg.ExchangeEvent,
		routingKeyPoseAdviceRequested,
		false, false,
		amqp091.Publishing{
			Timestamp:    time.Now(),
			Body:         body,
			ContentType:  "application/json",
			DeliveryMode: amqp091.Persistent,
		},
	); err != nil {
		return err
	}

	return nil
}
