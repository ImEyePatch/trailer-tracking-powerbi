# Security and Publication Rules

This repository is intended to be safe for a public portfolio. The production project contained sensitive operational and authentication material, so this repo deliberately excludes those artifacts.

## Never commit

- production `.pbix`, `.pbit`, or unsanitized PBIP/TMDL exports;
- API usernames, passwords, account IDs, OAuth-style authorization credentials, API keys, cookies, or authorization headers;
- real SharePoint URLs or tenant/site paths;
- SQL server names, database names, connection strings, IP addresses, or internal DNS names;
- customer, carrier, vendor, employee, or partner identifiers that are not already public and approved for disclosure;
- real asset/trailer IDs, order/load IDs, trip IDs, phone numbers, emails, GPS coordinates, tracking links, or raw API payloads;
- screenshots that contain operational rows, IDs, map positions, customer names, or internal URLs;
- Power BI crash/frown packages, Query Diagnostics exports, PerformanceTraces, memory dumps, or copied formula dumps from production;
- `.env` files or credential configuration files.

## Why crash/diagnostic files are specifically banned

Power BI diagnostic and crash packages can serialize query formulas and source metadata. A package can therefore expose secrets even when the visible report looks sanitized.

## Public coding rule

Use placeholders such as:

- `https://example.invalid`
- `<USERNAME>`
- `<PASSWORD>`
- `<ACCOUNT_ID>`
- `<SQL_SERVER>`
- `<DATABASE>`

For a real deployment, store credentials in an approved secret/identity mechanism rather than hard-coding them into source-controlled M or Python.

## Before publishing

Run:

```bash
python scripts/public_repo_check.py .
```

Then inspect the repository manually and, if available, run a dedicated secret scanner such as GitHub secret scanning, gitleaks, or trufflehog.
