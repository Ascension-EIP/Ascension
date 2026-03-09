use anyhow::{Context, Result};
use lapin::{
    BasicProperties, Channel, Connection, ConnectionProperties,
    options::{BasicPublishOptions, ExchangeDeclareOptions, QueueDeclareOptions},
    types::FieldTable,
};
use serde::Serialize;

pub const QUEUE: &str = "vision.skeleton";
pub const EXCHANGE: &str = "ascension.events";

#[derive(Debug, Clone)]
pub struct RabbitMqPublisher {
    channel: Channel,
}

impl RabbitMqPublisher {
    pub async fn connect(url: &str) -> Result<Self> {
        let conn = Connection::connect(url, ConnectionProperties::default())
            .await
            .context("failed to connect to RabbitMQ")?;

        let channel = conn
            .create_channel()
            .await
            .context("failed to create RabbitMQ channel")?;

        // Declare the queue (durable, matching the AI worker)
        channel
            .queue_declare(
                QUEUE,
                QueueDeclareOptions {
                    durable: true,
                    ..Default::default()
                },
                FieldTable::default(),
            )
            .await
            .context("failed to declare queue")?;

        // Declare the topic exchange for completion events
        channel
            .exchange_declare(
                EXCHANGE,
                lapin::ExchangeKind::Topic,
                ExchangeDeclareOptions {
                    durable: true,
                    ..Default::default()
                },
                FieldTable::default(),
            )
            .await
            .context("failed to declare exchange")?;

        Ok(Self { channel })
    }

    /// Publish a JSON-serialisable payload to the vision.skeleton queue.
    pub async fn publish_analysis_job<T: Serialize>(&self, payload: &T) -> Result<()> {
        let body = serde_json::to_vec(payload).context("failed to serialize job payload")?;

        self.channel
            .basic_publish(
                "",
                QUEUE,
                BasicPublishOptions::default(),
                &body,
                BasicProperties::default()
                    .with_content_type("application/json".into())
                    .with_delivery_mode(2), // persistent
            )
            .await
            .context("failed to publish message")?
            .await
            .context("failed to confirm message")?;

        Ok(())
    }
}
