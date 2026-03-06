#[cfg(test)]
mod tests {
    use crate::domain::user::models::user::{EmailAddress, Password, Role, Username};

    // ─── Username ─────────────────────────────────────────────────────────────

    #[test]
    fn username_valid_alphanumeric() {
        assert!(Username::new("validuser1").is_ok());
    }

    #[test]
    fn username_valid_with_underscore() {
        assert!(Username::new("valid_user1").is_ok());
    }

    #[test]
    fn username_valid_exactly_8_chars() {
        assert!(Username::new("abcdefgh").is_ok());
    }

    #[test]
    fn username_valid_exactly_24_chars() {
        assert!(Username::new("abcdefghijklmnopqrstuvwx").is_ok());
    }

    #[test]
    fn username_invalid_too_short() {
        assert!(Username::new("abc").is_err());
    }

    #[test]
    fn username_invalid_too_long() {
        assert!(Username::new("abcdefghijklmnopqrstuvwxy").is_err());
    }

    #[test]
    fn username_invalid_contains_space() {
        assert!(Username::new("invalid user").is_err());
    }

    #[test]
    fn username_invalid_contains_special_char() {
        assert!(Username::new("invalid@user").is_err());
    }

    #[test]
    fn username_trims_whitespace_then_validates() {
        // After trimming "  abc  " becomes "abc" (3 chars) → invalid
        assert!(Username::new("  abc  ").is_err());
    }

    #[test]
    fn username_trims_whitespace_valid() {
        assert!(Username::new("  validuser1  ").is_ok());
    }

    // ─── EmailAddress ─────────────────────────────────────────────────────────

    #[test]
    fn email_valid_simple() {
        assert!(EmailAddress::new("user@example.com").is_ok());
    }

    #[test]
    fn email_valid_subdomain() {
        assert!(EmailAddress::new("user@mail.example.com").is_ok());
    }

    #[test]
    fn email_valid_plus_sign() {
        assert!(EmailAddress::new("user+tag@example.com").is_ok());
    }

    #[test]
    fn email_invalid_missing_at() {
        assert!(EmailAddress::new("userexample.com").is_err());
    }

    #[test]
    fn email_invalid_missing_domain() {
        assert!(EmailAddress::new("user@").is_err());
    }

    #[test]
    fn email_invalid_missing_tld() {
        assert!(EmailAddress::new("user@example").is_err());
    }

    #[test]
    fn email_invalid_contains_space() {
        assert!(EmailAddress::new("us er@example.com").is_err());
    }

    #[test]
    fn email_trims_whitespace_then_validates_valid() {
        assert!(EmailAddress::new("  user@example.com  ").is_ok());
    }

    // ─── Password ─────────────────────────────────────────────────────────────

    #[test]
    fn password_valid_minimum_length() {
        assert!(Password::new("12345678").is_ok());
    }

    #[test]
    fn password_valid_with_special_chars() {
        assert!(Password::new("P@ssw0rd!").is_ok());
    }

    #[test]
    fn password_valid_exactly_72_chars() {
        let pw = "a".repeat(72);
        assert!(Password::new(&pw).is_ok());
    }

    #[test]
    fn password_invalid_too_short() {
        assert!(Password::new("1234567").is_err());
    }

    #[test]
    fn password_invalid_too_long() {
        let pw = "a".repeat(73);
        assert!(Password::new(&pw).is_err());
    }

    #[test]
    fn password_invalid_contains_space() {
        assert!(Password::new("invalid password").is_err());
    }

    #[test]
    fn password_trims_outer_whitespace_then_validates() {
        // " 1234567 " → trimmed to "1234567" (7 chars) → invalid
        assert!(Password::new(" 1234567 ").is_err());
    }

    // ─── Role ────────────────────────────────────────────────────────────────

    #[test]
    fn role_valid_user() {
        assert!(Role::new("User").is_ok());
    }

    #[test]
    fn role_valid_admin() {
        assert!(Role::new("Admin").is_ok());
    }

    #[test]
    fn role_invalid_unknown_variant() {
        assert!(Role::new("moderator").is_err());
    }

    #[test]
    fn role_lowercase_is_accepted_by_from_str() {
        // derive_more::FromStr is case-insensitive: "user" parses to Role::User
        assert!(Role::new("user").is_ok());
        assert!(Role::new("admin").is_ok());
    }

    #[test]
    fn role_invalid_empty_string() {
        assert!(Role::new("").is_err());
    }

    #[test]
    fn role_user_and_admin_are_different() {
        let user = Role::new("User").unwrap();
        let admin = Role::new("Admin").unwrap();
        assert_ne!(user, admin);
    }
}
