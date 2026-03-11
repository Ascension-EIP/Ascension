use derive_more::Display;
use regex::Regex;
use std::sync::LazyLock;
use thiserror::Error;

#[derive(Clone, Display, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Password(String);

#[derive(Clone, Debug, Error)]
#[error("{0} is not a valid password")]
pub struct PasswordInvalidError(String);

static PASSWORD_RE: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"^[^\s]{8,72}$").unwrap());

impl Password {
    pub fn new(raw: &str) -> Result<Self, PasswordInvalidError> {
        let trimmed = raw.trim();
        if !PASSWORD_RE.is_match(trimmed) {
            Err(PasswordInvalidError(trimmed.to_string()))
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}
