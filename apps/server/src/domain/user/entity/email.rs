use derive_more::Display;
use regex::Regex;
use std::sync::LazyLock;
use thiserror::Error;

#[derive(Clone, Display, Debug, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct Email(String);

#[derive(Clone, Debug, Error)]
#[error("{0} is not a valid email address")]
pub struct EmailInvalidError(String);

static EMAIL_RE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^[^\s@]+@[^\s@]+\.[^\s@]+$").unwrap());

impl Email {
    pub fn new(raw: &str) -> Result<Self, EmailInvalidError> {
        let trimmed = raw.trim();
        if !EMAIL_RE.is_match(trimmed) {
            Err(EmailInvalidError(trimmed.to_string()))
        } else {
            Ok(Self(trimmed.to_string()))
        }
    }
}
