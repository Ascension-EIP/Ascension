use anyhow::{Context, Result};
use http::Method;
use minio::s3::client::ClientBuilder;
use minio::s3::creds::StaticProvider;
use minio::s3::http::BaseUrl;
use minio::s3::types::S3Api;
use std::time::Duration;

/// Minimal MinIO/S3 presigned URL generator using the `minio` crate.
#[derive(Debug, Clone)]
pub struct MinioClient {
    pub endpoint: String,
    pub access_key: String,
    pub secret_key: String,
    pub bucket: String,
}

impl MinioClient {
    pub fn new(endpoint: &str, access_key: &str, secret_key: &str, bucket: &str) -> Self {
        Self {
            endpoint: endpoint.to_string(),
            access_key: access_key.to_string(),
            secret_key: secret_key.to_string(),
            bucket: bucket.to_string(),
        }
    }

    fn build_client(&self) -> Result<minio::s3::Client> {
        let base_url: BaseUrl = self
            .endpoint
            .parse()
            .context("invalid MinIO endpoint URL")?;
        let provider = StaticProvider::new(&self.access_key, &self.secret_key, None);
        ClientBuilder::new(base_url)
            .provider(Some(Box::new(provider)))
            .build()
            .context("failed to build MinIO client")
    }

    /// Ensure the configured bucket exists (creates it if missing).
    pub async fn ensure_bucket(&self) -> Result<()> {
        let client = self.build_client()?;
        let exists = client
            .bucket_exists(&self.bucket)
            .send()
            .await
            .context("failed to check bucket existence")?;
        if !exists.exists {
            client
                .create_bucket(&self.bucket)
                .send()
                .await
                .context("failed to create bucket")?;
            tracing::info!("Created MinIO bucket '{}'", self.bucket);
        }
        Ok(())
    }

    /// Generate a presigned PUT URL valid for `expires_in`.
    pub async fn presign_put(
        &self,
        object_key: &str,
        expires_in: Duration,
    ) -> Result<String> {
        let client = self.build_client()?;
        let expiry_secs = expires_in.as_secs() as u32;

        let resp = client
            .get_presigned_object_url(&self.bucket, object_key, Method::PUT)
            .expiry_seconds(expiry_secs)
            .send()
            .await
            .context("failed to generate presigned PUT URL")?;

        Ok(resp.url)
    }
}
