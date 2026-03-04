use anyhow::{Context, anyhow};
use sqlx::postgres::PgPoolOptions;
use sqlx::{Executor, Transaction};
use uuid::Uuid;

use crate::domain::user::models::user::{EmailAddress, Password, Role, User, Username};
use crate::domain::user::ports::{
    CreateUserData, DeleteUserData, UpdateUserData, UserRepository, UserRepositoryError,
};

#[derive(Debug, Clone)]
pub struct Postgres {
    pool: sqlx::PgPool,
}

impl Postgres {
    pub async fn new(path: &str) -> anyhow::Result<Postgres> {
        let pool = PgPoolOptions::new()
            .max_connections(50)
            .connect(path)
            .await
            .context(format!("could not connect to {}", path))?;

        Ok(Postgres { pool })
    }

    async fn save_user(
        &self,
        tx: &mut Transaction<'_, sqlx::Postgres>,
        username: &Username,
        email: &EmailAddress,
        password_hash: &Password,
        role: &Role,
    ) -> Result<Uuid, sqlx::Error> {
        let id = Uuid::new_v4();
        let query = sqlx::query!(
            "INSERT INTO users (id, username, email, password_hash, role) VALUES ($1, $2, $3, $4, $5)",
            id.to_string(),
            username.to_string(),
            email.to_string(),
            password_hash.to_string(),
            role.to_string(),
        );
        tx.execute(query).await?;
        Ok(id)
    }
}

impl UserRepository for Postgres {
    async fn create_user(&self, req: &CreateUserData) -> Result<User, UserRepositoryError> {
        let mut tx = self
            .pool
            .begin()
            .await
            .context("failed to start Postgres transaction")?;

        let id = self
            .save_user(
                &mut tx,
                &req.username,
                &req.email,
                &req.password_hash,
                &req.role,
            )
            .await
            .map_err(|e| {
                if is_unique_constraint_violation(&e) {
                    UserRepositoryError::DuplicateEmail {
                        email: req.email.clone(),
                    }
                } else {
                    anyhow!(e)
                        .context(format!("failed to save user with email {}", req.email))
                        .into()
                }
            })?;

        tx.commit()
            .await
            .context("failed to commit Postgres transaction")?;

        Ok(User::new(
            id,
            req.username.clone(),
            req.email.clone(),
            req.password_hash.clone(),
            req.role.clone(),
        ))
    }

    async fn list_users(&self) -> Result<Vec<User>, UserRepositoryError> {
        Ok(vec![])
    }

    async fn update_user(&self, req: &UpdateUserData) -> Result<User, UserRepositoryError> {
        Err(UserRepositoryError::DuplicateEmail {
            email: EmailAddress::new("caca@pipi.prout").unwrap(),
        })
    }

    async fn delete_user(&self, req: &DeleteUserData) -> Result<(), UserRepositoryError> {
        Err(UserRepositoryError::DuplicateEmail {
            email: EmailAddress::new("caca@pipi.prout").unwrap(),
        })
    }
}

fn is_unique_constraint_violation(err: &sqlx::Error) -> bool {
    if let sqlx::Error::Database(db_err) = err {
        if db_err.is_unique_violation() {
            return true;
        }
    }

    false
}
