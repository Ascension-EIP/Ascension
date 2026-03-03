# Session Log: Conda Docs Update

**Date:** 2026-03-03T15:56:55
**Agent:** Darius (Docs)
**Requester:** Gianni TUERO

## Summary
Synchronized AI environment documentation to the conda-based workflow defined in `apps/ai/moon.yml`, replacing stale package/setup wording and documenting canonical moon commands (`ai:setup`, `ai:install`, `ai:dev`, `ai:lint`, `ai:test`, `ai:build`).

## Work Completed
- Added a dedicated local setup section to `docs/developer_guide/ai/README.md` with conda + moon commands.
- Updated `docs/rncp/audit/stack-summary.md` to reference `environment.yml` + `pyproject.toml` instead of `requirements.txt`.
- Updated `docs/rncp/prototype-pool.md` dependency note to conda environment management.
- Merged decision inbox item into `.squad/decisions.md` and removed merged inbox file.
- Appended relevant cross-agent updates to Darius and Quentin histories.

## Validation
- `apps/ai/moon.yml` uses `conda env create --name ascension-ai --file environment.yml --force` for setup.
- All new setup examples in docs now match this conda-first workflow.
