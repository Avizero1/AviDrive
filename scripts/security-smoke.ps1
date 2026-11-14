$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$db = Join-Path $env:TEMP 'avidrive-security-smoke.db'
$log = Join-Path $env:TEMP 'avidrive-security-smoke.log'
$err = Join-Path $env:TEMP 'avidrive-security-smoke.err.log'
Remove-Item $db,$log,$err -Force -ErrorAction SilentlyContinue
Push-Location $root
$process = $null
try {
  New-Item -ItemType Directory -Force (Join-Path $root 'data') | Out-Null
  $env:DB_PATH = $db
  $env:SPRING_DATASOURCE_URL = "jdbc:sqlite:$db"
  $env:SPRING_JPA_DATABASE_PLATFORM = 'org.hibernate.community.dialect.SQLiteDialect'
  mvn -q -DskipTests package
  $jar = Get-ChildItem (Join-Path $root 'target\*.jar') | Where-Object { $_.Name -notlike '*-plain.jar' } | Select-Object -First 1
  if (-not $jar) { throw 'Boot jar was not produced' }
  $process = Start-Process java -ArgumentList @('-jar',$jar.FullName) -WorkingDirectory $root -RedirectStandardOutput $log -RedirectStandardError $err -PassThru
  $ready = $false
  1..30 | ForEach-Object { if (-not $ready) { Start-Sleep -Milliseconds 500; try { $health=Invoke-WebRequest 'http://127.0.0.1:8080/api/health' -UseBasicParsing; $ready=$true } catch {} } }
  if (-not $ready) { throw "Backend did not become ready. See $log and $err" }
  if ($health.StatusCode -ne 200) { throw "Health expected 200, got $($health.StatusCode)" }
  if (-not $health.Headers['Content-Security-Policy']) { throw 'Missing Content-Security-Policy' }
  if (-not $health.Headers['X-Content-Type-Options']) { throw 'Missing X-Content-Type-Options' }
  try { Invoke-WebRequest 'http://127.0.0.1:8080/api/profile' -UseBasicParsing | Out-Null; throw 'Protected endpoint unexpectedly succeeded' } catch { if ($_.Exception.Response.StatusCode.value__ -ne 401) { throw "Protected endpoint expected 401, got $($_.Exception.Response.StatusCode.value__)" } }
  Write-Output 'security smoke: PASS (health=200, protected endpoint=401, security headers present)'
} finally { if ($process) { Stop-Process $process.Id -Force -ErrorAction SilentlyContinue }; Pop-Location }
