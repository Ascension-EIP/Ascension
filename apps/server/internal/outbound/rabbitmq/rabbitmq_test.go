// @date 2026-11-13
// @file rabbitmq_test.go
// @brief Unit tests of the topology shared with the AI worker.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
package rabbitmq

import "testing"

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
