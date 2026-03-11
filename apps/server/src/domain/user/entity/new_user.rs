use crate::domain::user::entity::{
    email::Email, password::Password, role::Role, username::Username,
};

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct NewUser {
    pub username: Username,
    pub email: Email,
    pub password: Password,
    pub role: Role,
}

#[allow(dead_code)]
impl NewUser {
    pub fn new(username: Username, email: Email, password: Password, role: Role) -> Self {
        Self {
            username,
            email,
            password,
            role,
        }
    }
}
