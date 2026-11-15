// @date 2026-11-13
// @file analysis.go
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, DimitriLaPoudre <lou.pellegrino@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rabbitmq

import (
	"context"
	"encoding/json"
	"time"

	"github.com/Ascension-EIP/Ascension/apps/server/internal/shared"
	"github.com/rabbitmq/amqp091-go"
)

func (q *RabbitMQ) PublishPoseDetectRequested(ctx context.Context, req shared.PoseDetectRequest) error {
	body, err := json.Marshal(req)
	if err != nil {
		return err
	}

	return q.ch.PublishWithContext(ctx,
		q.cfg.ExchangeEvent,
		routingKeyPoseDetectRequested,
		false, false,
		amqp091.Publishing{
			Timestamp:    time.Now(),
			Body:         body,
			ContentType:  "application/json",
			DeliveryMode: amqp091.Persistent,
		},
	)
}
