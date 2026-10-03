param([int]$Port=55434)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$parent=[IO.Path]::GetFullPath((Join-Path $repo '.tooling/pg-local-test'))
$run=[IO.Path]::GetFullPath((Join-Path $parent ([Guid]::NewGuid().ToString('N'))))
$helper=Join-Path $PSScriptRoot 'local-postgres.ps1'
$bin='C:\Program Files\PostgreSQL\18\bin'
if(-not(Test-Path -LiteralPath $helper)){throw 'Local PostgreSQL helper is absent (expected RED before implementation).'}
foreach($p in @((Join-Path $repo '.tooling'),$parent)){if((Test-Path -LiteralPath $p)-and((Get-Item -LiteralPath $p).Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'Test parent must not be a junction.'}}
if(-not $run.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Test path escaped its root.'}
New-Item -ItemType Directory -Path $run -Force|Out-Null
$cluster=Join-Path $run 'cluster'
$envPath=Join-Path $repo '.env';$envBefore=if(Test-Path -LiteralPath $envPath){(Get-FileHash -LiteralPath $envPath).Hash}else{$null}
function Call-Local([string]$Action,[string]$Path=$cluster,[bool]$ShouldPass=$true){
 $callId=[Guid]::NewGuid().ToString('N')
 $args=@('-NoProfile','-ExecutionPolicy','Bypass','-File',('"'+$helper+'"'),'-Action',$Action,'-DataRoot',('"'+$Path+'"'),'-Port',"$Port")
 $p=Start-Process powershell.exe -ArgumentList $args -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $run "$callId-out.log") -RedirectStandardError (Join-Path $run "$callId-error.log")
 $handle=$p.Handle
 if(-not$p.WaitForExit(60000)){throw 'Local helper test timed out; isolated cluster retained.'}
 $ok=$p.ExitCode-eq0
 if($ok-ne$ShouldPass){throw "Unexpected local helper result for $Action; output retained privately."}
}
function Query([string]$Sql){
 $old=$env:PGPASSWORD
 try{$env:PGPASSWORD=[IO.File]::ReadAllText((Join-Path $cluster 'password.txt')).Trim();$result=& (Join-Path $bin 'psql.exe') -X -w -h 127.0.0.1 -p $Port -U estuda_ai_local -d estuda_ai -At -v ON_ERROR_STOP=1 -c $Sql 2>&1;if($LASTEXITCODE-ne0){throw 'Test SQL failed.'};return $result}finally{$env:PGPASSWORD=$old}
}
try{
 Call-Local Init; $passwordHash=(Get-FileHash -LiteralPath (Join-Path $cluster 'password.txt')).Hash
 Call-Local Init; if((Get-FileHash -LiteralPath (Join-Path $cluster 'password.txt')).Hash-ne$passwordHash){throw 'Repeated Init changed the password.'}
 Call-Local Start
 if([IO.Path]::GetFullPath((Query "SELECT current_setting('data_directory')").Trim())-ne[IO.Path]::GetFullPath((Join-Path $cluster 'data'))){throw 'Test cluster identity mismatch.'}
 Query 'CREATE TABLE routine_sentinel (value text); INSERT INTO routine_sentinel VALUES (''preserved'')'|Out-Null
 Call-Local Stop;Call-Local Start
 if((Query 'SELECT value FROM routine_sentinel').Trim()-ne'preserved'){throw 'Restart lost persistent data.'}
 Call-Local Status;Call-Local Stop
 $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
 try{$listener.Start();Call-Local Start $cluster $false}finally{$listener.Stop()}
 Call-Local Init (Join-Path $repo 'artifacts/outside-tooling') $false
 $foreign=Join-Path $run 'foreign';New-Item -ItemType Directory -Path (Join-Path $foreign 'data') -Force|Out-Null;[IO.File]::WriteAllText((Join-Path $foreign 'data/PG_VERSION'),'18')
 Call-Local Stop $foreign $false;Call-Local Init $foreign $false
 $envAfter=if(Test-Path -LiteralPath $envPath){(Get-FileHash -LiteralPath $envPath).Hash}else{$null}
 if($envBefore-ne$envAfter){throw 'Existing .env changed.'}
 $replica=Join-Path $run 'replica';New-Item -ItemType Directory -Path (Join-Path $replica 'tools') -Force|Out-Null
 Copy-Item -LiteralPath $helper -Destination (Join-Path $replica 'tools/local-postgres.ps1')
 Copy-Item -LiteralPath (Join-Path $repo '.env.example') -Destination (Join-Path $replica '.env.example')
 $replicaEnv=Join-Path $replica '.env';[IO.File]::WriteAllText($replicaEnv,'EXISTING_SETTING=preserved')
 $savedHelper=$helper;$helper=Join-Path $replica 'tools/local-postgres.ps1'
 try{Call-Local Init (Join-Path $replica '.tooling/cluster');if([IO.File]::ReadAllText($replicaEnv)-ne'EXISTING_SETTING=preserved'){throw 'Preexisting .env was overwritten.'}}finally{$helper=$savedHelper}
 Write-Output 'PASS: init idempotent, restart preserves data, port/path/foreign cluster refused, .env preserved.'
}finally{
 if(Test-Path -LiteralPath (Join-Path $cluster 'data/postmaster.pid')){Call-Local Stop}
 # Only this exact UUID test directory, with its verified marker, is removable.
 $marker=Join-Path $cluster '.estuda-ai-cluster.json'
 if(Test-Path -LiteralPath $marker){$identity=Get-Content -LiteralPath $marker -Raw|ConvertFrom-Json;if($identity.root-ne$cluster-or-not$run.StartsWith($parent+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'Cleanup identity mismatch.'};Remove-Item -LiteralPath $run -Recurse -Force}
}
