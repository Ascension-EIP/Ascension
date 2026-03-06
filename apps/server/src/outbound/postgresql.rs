use anyhow::{Context, anyhow};
use sqlx::{Executor, Row, Transaction};
use uuid::Uuid;

use crate::domain::user::models::user::{
    CreateUserOutput, EmailAddress, GetUserOutput, ListUserOutput, ListUsersOutput, Password, Role,
    UpdateUserOutput, Username,
};
use crate::domain::user::ports::{
    CreateUserData, DeleteUserData, GetUserData, ListUsersData, UpdateUserData, UserRepository,
    UserRepositoryError,
};

#[derive(Debug, Clone)]
pub struct Postgres {
    pool: sqlx::PgPool,
}

impl Postgres {
    pub fn new(pool: sqlx::PgPool) -> Postgres {
        Postgres { pool }
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

    async fn list_users(&self, req: &ListUsersData) -> Result<ListUsersOutput, sqlx::Error> {
        let rows = if let Some(per_page) = req.per_page {
            if per_page == 0 {
                sqlx::query("SELECT id, username, email, role FROM users ORDER BY id")
                    .fetch_all(&self.pool)
                    .await?
            } else {
                let page = req.page.unwrap_or(1);
                let offset = per_page.saturating_mul(page.saturating_sub(1)) as i64;
                let per_page = per_page as i64;
                sqlx::query(
                    "SELECT id, username, email, role FROM users ORDER BY id LIMIT $1 OFFSET $2",
                )
                .bind(per_page)
                .bind(offset)
                .fetch_all(&self.pool)
                .await?
            }
        } else {
            sqlx::query("SELECT id, username, email, role FROM users ORDER BY id")
                .fetch_all(&self.pool)
                .await?
        };

        let users = rows
            .into_iter()
            .map(|row| {
                let id: String = row.try_get("id")?;
                let username: String = row.try_get("username")?;
                let email: String = row.try_get("email")?;
                let role: String = row.try_get("role")?;

                let id = Uuid::parse_str(&id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let username =
                    Username::new(&username).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let email =
                    EmailAddress::new(&email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let role = Role::new(&role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;

                Ok(ListUserOutput::new(id, username, email, role))
            })
            .collect::<Result<Vec<ListUserOutput>, sqlx::Error>>()?;

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
        let email =
            EmailAddress::new(&query.email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let role = Role::new(&query.role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        Ok(GetUserOutput::new(parsed_id, username, email, role))
    }

    async fn update_user(&self, req: &UpdateUserData) -> Result<UpdateUserOutput, sqlx::Error> {
        let result: sqlx::postgres::PgQueryResult = sqlx::query!(
            "UPDATE users SET username = $1, email = $2, password_hash = $3, role = $4 WHERE id = $5",
            req.username.to_string(),
            req.email.to_string(),
            req.password_hash.to_string(),
            req.role.to_string(),
            req.id.to_string(),
        )
        .execute(&self.pool)
        .await?;
        if result.rows_affected() == 0 {
            return Err(sqlx::Error::RowNotFound);
        }
        Ok(UpdateUserOutput::new(req.id))
    }

    async fn delete_user(&self, req: &DeleteUserData) -> Result<(), sqlx::Error> {
        let result: sqlx::postgres::PgQueryResult =
            sqlx::query!("DELETE FROM users WHERE id = $1", req.id.to_string(),)
                .execute(&self.pool)
                .await?;
        if result.rows_affected() == 0 {
            return Err(sqlx::Error::RowNotFound);
        }
        Ok(())
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

        Ok(UpdateUserOutput::new(user.id))
    }

    async fn delete_user(&self, req: &DeleteUserData) -> Result<(), UserRepositoryError> {
        self.delete_user(req).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserRepositoryError::NotFoundId { id: req.id }
            } else {
                anyhow!(e)
                    .context(format!("failed to delete user with id {}", req.id))
                    .into()
            }
        })?;
        Ok(())
    }
}

fn is_unique_constraint_violation(err: &sqlx::Error) -> bool {
    if let sqlx::Error::Database(db_err) = err
        && db_err.is_unique_violation()
    {
        return true;
    }

    false
}
