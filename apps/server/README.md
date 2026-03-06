> **Last updated:** 6th March 2026  
> **Version:** 1.1  
> **Authors:** Gianni TUERO  
> **Status:** In Progress  
> {.is-warning}

---

# Server

This is the server repository for Ascension. It contains the code for the server, which is responsible for handling all the app logic and communication with the clients. The server is built using Rust.

## Running the server

```sh
cargo run
```

## Running the tests

The tests do not require a running database — they use an in-memory mock repository.
The `SQLX_OFFLINE=true` flag is required because `sqlx::query!` macros check queries against
the database at compile time; the offline mode uses the cached query metadata in `.sqlx/` instead.

```sh
SQLX_OFFLINE=true cargo test
```

## Developer guides

- [Architecture overview](../../docs/developer_guide/server/architecture.md)
- [How to add a route](../../docs/developer_guide/server/adding-a-route.md)
- [How to implement a CRUD](../../docs/developer_guide/server/implementing-a-crud.md)
