use derive_more::Display;
use std::str::FromStr;
use thiserror::Error;

#[derive(Clone, Display, Debug, PartialEq, PartialOrd, Eq, Ord, Hash)]
pub enum Role {
    Admin,
    User,
}

#[derive(Clone, Debug, Error)]
#[error("{0} is not a valid role")]
pub struct RoleInvalidError(String);

impl FromStr for Role {
    type Err = RoleInvalidError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.to_lowercase().as_str() {
            "admin" => Ok(Role::Admin),
            "user" => Ok(Role::User),
            _ => Err(RoleInvalidError(s.to_string())),
        }
    }
}

impl Role {
    pub fn new(role: &str) -> Result<Self, RoleInvalidError> {
        Role::from_str(role)
    }
}
