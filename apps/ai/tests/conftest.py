# @date 2026-11-01
# @file conftest.py
# @brief Shared pytest configuration (custom markers).
# @project Ascension
# @author Gianni TUERO <gianni.tuero@epitech.eu>
# @copyright (c) 2026 Ascension
# @status done
def pytest_configure(config):
    config.addinivalue_line(
        "markers",
        "integration: needs a migrated PostgreSQL, read from TEST_POSTGRES_URL (skipped without it)",
    )
    config.addinivalue_line("markers", "functional: runs the CLI in sub-processes; no infrastructure, no network")
    config.addinivalue_line("markers", "e2e: needs RabbitMQ, PostgreSQL and RustFS (skipped when unreachable)")
