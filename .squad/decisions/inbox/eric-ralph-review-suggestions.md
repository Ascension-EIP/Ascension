## 2026-03-03: Ralph CHANGES_REQUESTED policy — suggestions before implementation
**By:** Eric (Lead)
**Requested by:** Gianni TUERO

### Context
Ralph’s prior PR review behavior emphasized comment-only follow-up on `CHANGES_REQUESTED`, which did not provide a concrete fix proposal workflow.

### Decision
For future Ralph-driven review cycles:
- When PR review feedback includes `CHANGES_REQUESTED`, Ralph should request a clear suggested fix patch/plan (Copilot-style suggestion workflow).
- Ralph must NOT apply fixes automatically.
- Ralph must NOT auto-commit.
- Ralph must NOT auto-push.
- Any implementation action requires explicit user confirmation after suggestions are presented.

### Scope
Surgical policy update limited to Ralph section trigger/categorization/step logic in `.github/agents/squad.agent.md`.

### Non-Change
Ralph’s non-stop monitoring loop remains intact (continuous work-check cycle behavior unchanged).
