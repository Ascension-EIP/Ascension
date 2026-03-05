use anyhow::{Context, anyhow};
use sqlx::postgres::PgPoolOptions;
use sqlx::{Executor, Transaction};
use uuid::Uuid;

use crate::domain::user::models::user::{CreateUserOutput, EmailAddress, GetUserOutput, ListUserOutput, ListUsersOutput, Password, Role, UpdateUserOutput, Username};
use crate::domain::user::ports::{
    CreateUserData, DeleteUserData, GetUserData, ListUsersData, UpdateUserData, UserRepository,
    UserRepositoryError,
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

    async fn list_users(&self, req: &ListUsersData) -> Result<ListUsersOutput,  sqlx::Error> {
        let query = sqlx::query!(
            "SELECT id, username, email, role FROM users"
            )
        .fetch_all(&self.pool)
        .await?;

        let users = query.iter().map(|row| {
            let id = Uuid::parse_str(&row.id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            let username = Username::new(&row.username).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            let email = EmailAddress::new(&row.email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
            let role = Role::new(&row.role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;

            Ok(ListUserOutput::new(id, username, email, role))
        }).collect::<Result<Vec<ListUserOutput>, sqlx::Error>>()?;
        Ok(ListUsersOutput::new(users))
    }

    async fn get_user(&self, id: Uuid) -> Result<GetUserOutput, sqlx::Error> {
        let query = sqlx::query!(
            "SELECT id, username, email, role FROM users WHERE id = $1",
            id.to_string()
        )
        .fetch_one(&self.pool)
        .await?;

        let parsed_id = Uuid::parse_str(&query.id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let username =
            Username::new(&query.username).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let email = EmailAddress::new(&query.email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let role = Role::new(&query.role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        Ok(GetUserOutput::new(parsed_id, username, email, role))
    }

    async fn update_user(&self, req: &UpdateUserData) -> Result<UpdateUserOutput,  sqlx::Error> {
        let _query = sqlx::query!(
            "UPDATE users SET username = $1, email = $2, password_hash = $3, role = $4 WHERE id = $5",
            req.username.to_string(),
            req.email.to_string(),
            req.password_hash.to_string(),
            req.role.to_string(),
            req.id.to_string(),
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(UpdateUserOutput::new(req.id))
    }

    async fn delete_user(&self, req: &DeleteUserData) -> Result<(),  sqlx::Error> {
        sqlx::query!(
            "DELETE FROM users WHERE id = $1",
            req.id.to_string(),
        )
        .fetch_one(&self.pool)
        .await?;
        Ok({})
    }
}

impl UserRepository for Postgres {
    async fn create_user(
        &self,
        req: &CreateUserData,
    ) -> Result<CreateUserOutput, UserRepositoryError> {
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

        Ok(CreateUserOutput { id })
    }

    async fn get_user(&self, req: &GetUserData) -> Result<GetUserOutput, UserRepositoryError> {
        let user = self.get_user(req.id).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserRepositoryError::NotFoundId { id: req.id }
            } else {
                anyhow!(e)
                    .context(format!("failed to get user with id {}", req.id))
                    .into()
            }
        })?;

        Ok(GetUserOutput::new(
            user.id,
            user.username,
            user.email,
            user.role,
        ))
    }

    async fn list_users(
        &self,
        req: &ListUsersData,
    ) -> Result<ListUsersOutput, UserRepositoryError> {
        let users = self.list_users(req).await.map_err(|e| {
            UserRepositoryError::Unknown(anyhow!(e).context("failed to list all users"))
        })?;
        Ok(users)
    }

    async fn update_user(
        &self,
        req: &UpdateUserData,
    ) -> Result<UpdateUserOutput, UserRepositoryError> {
        let user = self.update_user(req).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserRepositoryError::NotFoundId { id: req.id }
            } else if is_unique_constraint_violation(&e) {
                UserRepositoryError::DuplicateEmail {
                    email: req.email.clone(),
                }
            } else {
                anyhow!(e)
                    .context(format!("failed to update user with id {}", req.id))
                    .into()
            }
        })?;

        Ok(UpdateUserOutput::new(
            user.id,
        ))
    }

    async fn delete_user(&self, _req: &DeleteUserData) -> Result<(), UserRepositoryError> {
        self.delete_user(_req).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserRepositoryError::NotFoundId { id: _req.id }
            } else {
                anyhow!(e)
                    .context(format!("failed to delete user with id {}", _req.id))
                    .into()
            }
        })?;
        Ok({})
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
