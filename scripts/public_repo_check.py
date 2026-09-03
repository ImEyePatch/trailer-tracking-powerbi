#!/usr/bin/env python3
"""Very small pre-publish safety scan for this portfolio repository.

This is not a substitute for a dedicated secret scanner. It catches common
accidental disclosures that are especially relevant to Power BI/SQL projects.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()

SKIP_DIRS = {".git", "__pycache__", ".venv", "venv"}
SKIP_SUFFIXES = {".png", ".jpg", ".jpeg", ".gif", ".pdf", ".zip", ".7z", ".rar"}

PATTERNS = {
    "email": re.compile(r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", re.I),
    "ipv4": re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b"),
    "bearer token": re.compile(r"\bBearer\s+[A-Za-z0-9._~+/-]+=*", re.I),
    "basic auth literal": re.compile(r"Authorization\s*=\s*\"Basic\s+[A-Za-z0-9+/=]+\"", re.I),
    "password assignment": re.compile(r"\bpassword\b\s*[:=]\s*[\"'][^<\n][^\"'\n]{5,}[\"']", re.I),
    "api key assignment": re.compile(r"\b(api[_ -]?key|token|secret)\b\s*[:=]\s*[\"'][^<\n][^\"'\n]{7,}[\"']", re.I),
    "sharepoint tenant url": re.compile(r"https://[a-z0-9-]+\.sharepoint\.com", re.I),
}

ALLOW_EMAILS = {"example@example.com"}
ALLOW_URL_HOST_MARKERS = {"example.invalid"}

issues: list[tuple[Path, int, str, str]] = []

for path in ROOT.rglob("*"):
    if not path.is_file():
        continue
    if path.resolve() == Path(__file__).resolve():
        continue
    if any(part in SKIP_DIRS for part in path.parts):
        continue
    if path.suffix.lower() in SKIP_SUFFIXES:
        continue

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue

    for line_no, line in enumerate(text.splitlines(), start=1):
        for label, pattern in PATTERNS.items():
            for match in pattern.finditer(line):
                value = match.group(0)
                if label == "email" and value.lower() in ALLOW_EMAILS:
                    continue
                if "example.invalid" in value:
                    continue
                if "<PASSWORD>" in value or "<USERNAME>" in value or "<ACCOUNT_ID>" in value:
                    continue
                issues.append((path.relative_to(ROOT), line_no, label, value[:120]))

if issues:
    print("Potential public-repo issues found:\n")
    for path, line_no, label, value in issues:
        print(f"- {path}:{line_no}: {label}: {value}")
    print("\nReview each finding before publishing.")
    sys.exit(1)

print("No obvious secrets/identifiers detected by the basic portfolio scan.")
print("Still run a dedicated secret scanner and perform a manual review before publishing.")
