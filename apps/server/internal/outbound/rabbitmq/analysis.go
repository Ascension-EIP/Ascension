// @date 2026-11-13
// @file analysis.go
// @brief File description.
// @project Ascension
// @author DimitriLaPoudre <lou.pellegrino@epitech.eu>, Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rabbitmq

import (
	"context"
	"time"

	"github.com/rabbitmq/amqp091-go"
)

func (q *RabbitMQ) PublishPoseDetectRequested(ctx context.Context, body []byte) error {
	if err := q.ch.PublishWithContext(ctx,
		q.cfg.ExchangeEvent,
		routingKeyPoseDetectRequested,
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
