# Trivy image scan

- Jenkins build: #7
- Image scanned: `hackathon-starter:7`
- Result: **Blocked by the vulnerability gate**
- Debian packages: 56 HIGH, 1 CRITICAL
- Node.js dependencies: 8 HIGH
- Critical finding: `CVE-2023-45853` in `zlib1g`
- Trivy status for this finding: `will_not_fix`

The Jenkins pipeline is configured to fail when it detects HIGH or CRITICAL
vulnerabilities. The detailed JSON report is archived with Jenkins build #7
as `tmp/trivy-report.json`.
