use anyhow::{Context, anyhow};
use async_trait::async_trait;
use sqlx::{Executor, Transaction};
use uuid::Uuid;

use crate::domain::user::{
    entity::{
        email::Email, new_user::NewUser, pagination::Pagination, password::Password, role::Role,
        user::User, username::Username,
    },
    error::UserError,
    outbound::UserRepository,
};

#[derive(Debug, Clone)]
pub struct Postgres {
    pool: sqlx::PgPool,
}

struct UserFilter {
    offset: usize,
    limit: usize,
}

impl Postgres {
    pub fn new(pool: sqlx::PgPool) -> Postgres {
        Postgres { pool }
    }

    async fn save_user(
        &self,
        tx: &mut Transaction<'_, sqlx::Postgres>,
        username: &Username,
        email: &Email,
        password_hash: &Password,
        role: &Role,
    ) -> Result<User, sqlx::Error> {
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
        Ok(User::new(
            id,
            username.clone(),
            email.clone(),
            password_hash.clone(),
            role.clone(),
        ))
    }

    async fn get_user(&self, id: &Uuid) -> Result<User, sqlx::Error> {
        let query = sqlx::query!(
            "SELECT id, username, email, role FROM users WHERE id = $1",
            id.to_string()
        )
        .fetch_one(&self.pool)
        .await?;

        let parsed_id = Uuid::parse_str(&query.id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let username =
            Username::new(&query.username).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let password = Password::new("ouiouioui").map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let email = Email::new(&query.email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        let role = Role::new(&query.role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
        Ok(User::new(parsed_id, username, email, password, role))
    }

    async fn filter_users(&self, req: &UserFilter) -> Result<Vec<User>, sqlx::Error> {
        let rows = sqlx::query!(
            "SELECT id, username, email, role FROM users ORDER BY id LIMIT $1 OFFSET $2",
            req.limit as i32,
            req.offset as i32,
        )
        .fetch_all(&self.pool)
        .await?;
        let users = rows
            .into_iter()
            .map(|row| {
                let id = Uuid::parse_str(&row.id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let username =
                    Username::new(&row.username).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let email = Email::new(&row.email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let password =
                    Password::new("ouiouioui").map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let role = Role::new(&row.role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;

                Ok(User::new(id, username, email, password, role))
            })
            .collect::<Result<Vec<User>, sqlx::Error>>()?;
        Ok(users)
    }

    async fn get_all_users(&self) -> Result<Vec<User>, sqlx::Error> {
        let rows = sqlx::query!("SELECT id, username, email, role FROM users ORDER BY id")
            .fetch_all(&self.pool)
            .await?;
        let users = rows
            .into_iter()
            .map(|row| {
                let id = Uuid::parse_str(&row.id).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let username =
                    Username::new(&row.username).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let email = Email::new(&row.email).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let password =
                    Password::new("ouiouioui").map_err(|e| sqlx::Error::Decode(Box::new(e)))?;
                let role = Role::new(&row.role).map_err(|e| sqlx::Error::Decode(Box::new(e)))?;

                Ok(User::new(id, username, email, password, role))
            })
            .collect::<Result<Vec<User>, sqlx::Error>>()?;
        Ok(users)
    }

    async fn update_user(&self, req: &User) -> Result<User, sqlx::Error> {
        let result: sqlx::postgres::PgQueryResult = sqlx::query!(
            "UPDATE users SET username = $1, email = $2, password_hash = $3, role = $4 WHERE id = $5",
            req.username.to_string(),
            req.email.to_string(),
            req.password.to_string(),
            req.role.to_string(),
            req.id.to_string(),
        )
        .execute(&self.pool)
        .await?;
        if result.rows_affected() == 0 {
            return Err(sqlx::Error::RowNotFound);
        }
        Ok(req.clone())
    }

    async fn delete_user(&self, req: &Uuid) -> Result<(), sqlx::Error> {
        let result: sqlx::postgres::PgQueryResult =
            sqlx::query!("DELETE FROM users WHERE id = $1", req.to_string(),)
                .execute(&self.pool)
                .await?;
        if result.rows_affected() == 0 {
            return Err(sqlx::Error::RowNotFound);
        }
        Ok(())
    }
}

#[async_trait]
impl UserRepository for Postgres {
    async fn create_user(&self, req: &NewUser) -> Result<User, UserError> {
        let mut tx = self
            .pool
            .begin()
            .await
            .context("failed to start Postgres transaction")?;

        let user = self
            .save_user(&mut tx, &req.username, &req.email, &req.password, &req.role)
            .await
            .map_err(|e| {
                if is_unique_constraint_violation(&e) {
                    UserError::DuplicateEmail(req.email.clone())
                } else {
                    anyhow!(e)
                        .context(format!("failed to save user with email {}", req.email))
                        .into()
                }
            })?;

        tx.commit()
            .await
            .context("failed to commit Postgres transaction")?;

        Ok(user)
    }

    async fn get_user(&self, req: &Uuid) -> Result<User, UserError> {
        let user = self.get_user(req).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserError::UserNotFound(req.clone())
            } else {
                anyhow!(e)
                    .context(format!("failed to get user with id {}", req))
                    .into()
            }
        })?;

        Ok(user)
    }

    async fn list_users(&self, req: &Pagination) -> Result<Vec<User>, UserError> {
        let users = if let Some(per_page) = req.per_page
            && per_page > 0
        {
            let page = req.page.unwrap_or(1);
            let offset = per_page.saturating_mul(page.saturating_sub(1));
            let user_filter = UserFilter {
                offset,
                limit: per_page,
            };
            self.filter_users(&user_filter).await
        } else {
            self.get_all_users().await
        }
        .map_err(|e| UserError::Unknown(anyhow!(e).context("failed to list all users")))?;
        Ok(users)
    }

    async fn update_user(&self, req: &User) -> Result<User, UserError> {
        let user = self.update_user(req).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserError::UserNotFound(req.id)
            } else if is_unique_constraint_violation(&e) {
                UserError::DuplicateEmail(req.email.clone())
            } else {
                anyhow!(e)
                    .context(format!("failed to update user with id {}", req.id))
                    .into()
            }
        })?;

        Ok(user)
    }

    async fn delete_user(&self, req: &Uuid) -> Result<(), UserError> {
        self.delete_user(req).await.map_err(|e| {
            if matches!(e, sqlx::Error::RowNotFound) {
                UserError::UserNotFound(req.clone())
            } else {
                anyhow!(e)
                    .context(format!("failed to delete user with id {}", req))
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
