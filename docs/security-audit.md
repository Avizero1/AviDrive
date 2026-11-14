# Security audit record

## Automated checks

| Check | Result | Evidence |
|---|---|---|
| Backend tests | ✅ | `mvn test` |
| Frontend dependency audit | ✅ | `npm audit --audit-level=high` — 0 vulnerabilities |
| Frontend build | ✅ | `npm run build` |
| Maven dependency tree | ✅ | `mvn dependency:tree` |
| OWASP Dependency-Check | ⏳ | Requires `NVD_API_KEY`; without it the NVD service rejects the request |

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
| Manual PC-1…PC-20 HTTP run | ⏳ | Local smoke launch was attempted, but the Windows harness could not keep the Spring process reachable; repeat on a running deployment |
