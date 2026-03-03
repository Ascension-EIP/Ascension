# Skill: PR Domain Routing

## Pattern
Automatically route pull requests to domain-specific reviewers based on changed file paths.

## When to Use
- Multi-team projects where different domains own different directories
- PRs frequently touch multiple domains and need coordinated review

## How It Works
1. A GitHub Actions workflow triggers on `pull_request` events.
2. Changed files are matched against a routing table (regex → agent/team).
3. Labels (`squad:{agent}`) are applied to the PR.
4. A summary comment is posted (upserted via HTML marker to avoid duplicates).
5. Stale labels from prior runs are cleaned up on re-trigger.
6. Cross-domain PRs (>2 agents) escalate to a lead/architect reviewer.

## Key Implementation Details
- Use `actions/github-script@v7` — no external dependencies.
- Auto-create labels on first use (idempotent via 404 catch).
- Upsert comments with `<!-- marker -->` HTML comments to avoid duplicates.
- Use concurrency groups to prevent parallel runs on the same PR.
- Pair with `CODEOWNERS` for GitHub-native review assignment.

## Files
- `.github/workflows/squad-pr-review.yml` — workflow
- `CODEOWNERS` — GitHub-native reviewer mapping

## Customization
- Edit `ROUTING_RULES` array in the workflow to add/remove domains.
- Edit `CODEOWNERS` to map paths to actual GitHub org teams.
