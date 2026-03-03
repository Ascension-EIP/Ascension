# Security Policy

## Supported Versions

Only the latest release on the `main` branch receives security fixes.

| Branch              |                  Supported                   |
| :------------------ | :------------------------------------------: |
| `main` (latest tag) |                      ✅                       |
| `dev`               | ⚠️ Active development — not production-ready |
| Older tags          |                      ❌                       |

---

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities by emailing the team directly at **security@ascension.app** (or open a [GitHub private security advisory](https://github.com/Ascension-EIP/Ascension/security/advisories/new)).

Include in your report:

- A clear description of the vulnerability and its potential impact.
- Steps to reproduce or a proof-of-concept.
- Affected component (`server`, `ai`, `mobile`, or infrastructure).
- Your contact details for follow-up.

We aim to acknowledge reports within **48 hours** and provide a resolution timeline within **7 days**.

---

## Security Architecture

For an overview of the security controls in place (TLS, JWT, RBAC, OWASP mitigations, GDPR compliance), see the [Context, Audit & Compliance document](docs/rncp/workshop/context-audit-compliance.md).
