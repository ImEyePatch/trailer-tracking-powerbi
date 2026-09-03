# Public GitHub Sanitization Checklist

Use this checklist every time new material is added.

## Data

- [ ] No real trailer/asset IDs
- [ ] No real order/load/trip IDs
- [ ] No carrier/customer names
- [ ] No phone numbers or emails
- [ ] No GPS coordinates
- [ ] No live tracking URLs
- [ ] No raw API responses
- [ ] No operational exports

## Infrastructure

- [ ] No SQL server/database names
- [ ] No internal schemas/codes that reveal customers/contracts
- [ ] No SharePoint tenant/site/document paths
- [ ] No internal hostnames/IPs
- [ ] No account IDs

## Authentication

- [ ] No usernames
- [ ] No passwords
- [ ] No API keys/tokens
- [ ] No Authorization headers
- [ ] No `.env`

## Power BI

- [ ] No production PBIX/PBIT
- [ ] No unsanitized PBIP/TMDL export
- [ ] No Query Diagnostics files
- [ ] No Frown/crash packages
- [ ] No screenshots with internal rows/filters/URLs
- [ ] No copied formula dump from a production crash report

## Business confidentiality

- [ ] Production thresholds are generalized or approved
- [ ] Commercial/fee values are removed
- [ ] Customer-specific route/location aliases are removed
- [ ] Proprietary logic is reconstructed at a pattern level, not copied verbatim

## Ownership

- [ ] Material is mine to publish or has explicit publication approval
- [ ] Repository is presented as a sanitized reconstruction, not as an employer source-code release
