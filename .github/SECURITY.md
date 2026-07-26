# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Transmute Framework, please report it responsibly.

**Email**: Open a [private security advisory](https://github.com/VoxTechnologies/transmute-framework/security/advisories/new) on GitHub.

Please include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt within 48 hours and provide a timeline for a fix.

## Scope

Transmute Framework is a Claude Code plugin (prompt engineering). Security concerns typically involve:
- Credential handling in generated `.env.local` files
- Gate enforcement bypasses
- Template injection in generated project files

## Supported Versions

| Version | Supported |
|---------|-----------|
| 3.x     | Yes       |
| 2.x     | No        |
| 1.x     | No        |
