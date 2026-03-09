use uuid::Uuid;

use crate::domain::user::entity::{
    email::Email, password::Password, role::Role, username::Username,
};

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct User {
    pub id: Uuid,
    pub username: Username,
    pub email: Email,
    pub password: Password,
    pub role: Role,
}

impl User {
    pub fn new(
        id: uuid::Uuid,
        username: Username,
        email: Email,
        password: Password,
        role: Role,
    ) -> Self {
        Self {
            id,
            username,
            email,
            password,
            role,
        }
    }
}
