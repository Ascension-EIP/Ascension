use derive_more::Display;
use regex::Regex;
use std::sync::LazyLock;
use thiserror::Error;

#[derive(Clone, Display, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Username(String);

#[derive(Clone, Debug, Error)]
#[error("{0} is not a valid username")]
pub struct UsernameInvalidError(String);

static USERNAME_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^[a-zA-Z0-9_]{8,24}$").unwrap());

impl Username {
    pub fn new(raw: &str) -> Result<Self, UsernameInvalidError> {
        let trimmed = raw.trim();
        if !USERNAME_RE.is_match(trimmed) {
            Err(UsernameInvalidError(trimmed.to_string()))
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}
