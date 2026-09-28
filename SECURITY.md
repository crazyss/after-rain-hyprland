# Security

## Reporting

For a vulnerability, open a private security advisory on the GitHub repository.
Do not publish credentials, host details or exploit data in a public issue.

## Repository safeguards

Run `scripts/scan-secrets.sh` before publishing. It scans both the working tree
and reachable Git history, and rejects personal commit email addresses. Never
commit `.env` files, tokens, hostnames, private service addresses or
machine-specific `local.conf`.

Rainlight runs a shell only after an explicit `>` prefix. Its calculator uses an
AST allowlist and never calls Python `eval`. Remote themes are not executed by
the installer.
