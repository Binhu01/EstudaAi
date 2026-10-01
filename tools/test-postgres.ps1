param([int]$Port = 55432)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$testRoot = [IO.Path]::GetFullPath((Join-Path $root '.tooling/pg-integration'))
$run = [IO.Path]::GetFullPath((Join-Path $testRoot ([Guid]::NewGuid().ToString('N'))))
if (-not $run.StartsWith($testRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid test path.' }
$bin = 'C:\Program Files\PostgreSQL\18\bin'
foreach ($name in @('initdb.exe','pg_ctl.exe','createdb.exe','psql.exe')) { if (-not (Test-Path -LiteralPath (Join-Path $bin $name))) { throw 'PostgreSQL test binaries unavailable.' } }
if ($Port -lt 1024 -or $Port -gt 65535) { throw 'Invalid test port.' }
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
try { $listener.Start() } catch { throw 'Test port is occupied; existing PostgreSQL is untouched.' } finally { $listener.Stop() }
foreach ($parent in @((Join-Path $root '.tooling'),$testRoot)) {
  if ((Test-Path -LiteralPath $parent) -and ((Get-Item -LiteralPath $parent).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Test parent must not be a junction.' }
}
New-Item -ItemType Directory -Path $run -Force | Out-Null
$data = Join-Path $run 'data'
$log = Join-Path $run 'server.log'
$passwordFile = Join-Path ([IO.Path]::GetTempPath()) ('estuda-ai-pg-' + [Guid]::NewGuid().ToString('N') + '.txt')
$bytes = New-Object byte[] 32
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$rng.Dispose()
$password = -join ($bytes | ForEach-Object { $_.ToString('x2') })
$originalPassword = $env:PGPASSWORD
$originalTestUrl = $env:TEST_DATABASE_URL
$originalDatabaseUrl = $env:DATABASE_URL
$exitCode = 1
Push-Location $root
try {
  [IO.File]::WriteAllText($passwordFile,$password,[Text.UTF8Encoding]::new($false))
  $acl = [Security.AccessControl.FileSecurity]::new()
  $acl.SetAccessRuleProtection($true,$false)
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.WindowsIdentity]::GetCurrent().User,'FullControl','Allow'))
  [IO.File]::SetAccessControl($passwordFile,$acl)
  & (Join-Path $bin 'initdb.exe') -D $data -U estuda_ai_test -A scram-sha-256 "--pwfile=$passwordFile" -E UTF8 --locale=C --no-instructions *> (Join-Path $run 'init.log')
  if ($LASTEXITCODE -ne 0) { throw 'Temporary PostgreSQL initialization failed; see test log.' }
  Remove-Item -LiteralPath $passwordFile -Force
  & (Join-Path $bin 'pg_ctl.exe') start -D $data -l $log -w -t 60 -o "-h127.0.0.1 -p$Port"
  if ($LASTEXITCODE -ne 0) { throw 'Temporary PostgreSQL startup failed; existing service untouched.' }
  $env:PGPASSWORD = $password
  $observed = & (Join-Path $bin 'psql.exe') -X -w -h 127.0.0.1 -p $Port -U estuda_ai_test -d postgres -At -v ON_ERROR_STOP=1 -c "SELECT current_setting('data_directory')"
  if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($observed.Trim()) -ne [IO.Path]::GetFullPath($data)) { throw 'PostgreSQL cluster identity mismatch.' }
  & (Join-Path $bin 'createdb.exe') -w -h 127.0.0.1 -p $Port -U estuda_ai_test -T template0 estuda_ai_integration_test
  if ($LASTEXITCODE -ne 0) { throw 'Failed to create dedicated integration database.' }
  $env:TEST_DATABASE_URL = "postgresql://estuda_ai_test:${password}@127.0.0.1:${Port}/estuda_ai_integration_test"
  $env:DATABASE_URL = $env:TEST_DATABASE_URL
  & npm.cmd run db:generate
  if ($LASTEXITCODE -ne 0) { throw 'Prisma generation failed.' }
  & npm.cmd run test:integration -w apps/api
  $exitCode = $LASTEXITCODE
} finally {
  if (Test-Path -LiteralPath $passwordFile) { Remove-Item -LiteralPath $passwordFile -Force }
  if (Test-Path -LiteralPath (Join-Path $data 'postmaster.pid')) {
    & (Join-Path $bin 'pg_ctl.exe') stop -D $data -m fast -w -t 30
    if ($LASTEXITCODE -ne 0) { $exitCode = 1; Write-Warning 'Temporary cluster did not stop. Test directory retained.' }
  }
  $env:PGPASSWORD = $originalPassword
  $env:TEST_DATABASE_URL = $originalTestUrl
  $env:DATABASE_URL = $originalDatabaseUrl
  Pop-Location
}
Write-Output 'Temporary PostgreSQL test finished; isolated logs retained under .tooling/pg-integration.'
exit $exitCode
