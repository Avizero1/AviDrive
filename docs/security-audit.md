# Security audit record

## Automated checks

| Check | Result | Evidence |
|---|---|---|
| Backend tests | ✅ | `mvn test` |
| Frontend dependency audit | ✅ | `npm audit --audit-level=high` — 0 vulnerabilities |
| Frontend build | ✅ | `npm run build` |
| Maven dependency tree | ✅ | `mvn dependency:tree` |
| OWASP Dependency-Check | ⏳ | `NVD_API_KEY` is missing; `mvn -Psecurity-audit verify -DskipTests -q` timed out without producing a report |
| Local HTTP smoke | ✅ | `scripts/security-smoke.ps1`: health 200, protected 401, invalid public token 404, hostile CORS denied, security headers present |

Run the Maven dependency audit with a configured key:

```powershell
$env:NVD_API_KEY = 'your-key'
mvn org.owasp:dependency-check-maven:check `
  "-Dnvd.api.key=$env:NVD_API_KEY" `
  "-DfailBuildOnCVSS=7"
```

## Static PC checklist

| Area | Result | Evidence |
|---|---|---|
| Unauthenticated API access | ✅ | JWT filter rejects protected requests with 401 |
| Blocked account access | ✅ | JWT filter returns 423 |
| Admin route role guard | ✅ | USER rejected from `/api/admin/**` |
| Public password access token | ✅ | Random token, SHA-256 at rest, 15-minute expiry |
| Public unlock brute force | ✅ | Five failures per IP/link per 15 minutes, then 429 |
| Public link file/folder IDOR | ✅ | Published file/tree containment checks |
| File download ownership | ✅ | Owner filtering before resource access |
| Upload path traversal | ✅ | Relative path validation and normalized destination |
| ZIP traversal | ✅ | Sanitized ZIP entry names |
| Range response correctness | ✅ | Stream skips to requested offset |
| Security headers | ✅ | CSP, frame denial, nosniff, referrer, permissions, HSTS |
| CORS origin | ✅ | Configured frontend origin only |
| JWT secret handling | ✅ | Startup replaces default placeholder with random 256-bit secret |
| Request size limits | ✅ | Header and Tomcat form-post limits configured |
| Storage path containment | ✅ | Download/content/preview reject paths outside `storage/files` |
| Stored-file write/archive containment | ✅ | Edit, ZIP export and public download validate stored paths before filesystem access |
| Manual PC-1…PC-20 HTTP run | ⏳ | Reproducible smoke subset passes; full authenticated/public abuse matrix still requires test fixtures and deployment |

## Latest rerun — 2026-11-14

- `mvn test` — ✅
- `scripts/security-smoke.ps1` — ✅ (`health=200`, protected `401`, invalid public token `404`, hostile CORS denied, security headers present)
- `npm audit --audit-level=high` — ✅, 0 vulnerabilities
- `npm run build` — ✅
- `mvn -Psecurity-audit verify -DskipTests -q` — ⏳ timeout; no dependency-check report generated because `NVD_API_KEY` is not configured

## Latest code hardening — 2026-11-14

- Authenticated file editing now validates the stored path before writing and sizing.
- ZIP export validates each stored path before copying it into an archive.
- Public-link downloads use the same storage-root containment check.
- `mvn test` and `git diff --check` — ✅ after these changes.
