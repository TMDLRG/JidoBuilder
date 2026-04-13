# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in JidoBuilder, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, email **mpolzin@zimzap.com** with:

1. A description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

You will receive acknowledgment within 48 hours. We aim to provide a fix or mitigation within 7 days of confirmation.

## Security Measures

JidoBuilder uses the following security measures:

- **Dependabot** — automated vulnerability alerts and dependency updates
- **Encrypted secrets** — API keys stored via Cloak/AES-256 encryption
- **Authentication** — bcrypt password hashing via `pbkdf2_elixir`
- **CSRF protection** — Phoenix built-in CSRF tokens on all forms
- **Input validation** — Ecto changesets validate all user input
- **No hardcoded secrets** — all credentials via environment variables or encrypted storage
