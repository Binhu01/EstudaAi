param([Parameter(Mandatory=$true)][ValidateSet('Init','Start','Status','Stop')][string]$Action,[int]$Port=55433,[string]$DataRoot)
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$tooling=[IO.Path]::GetFullPath((Join-Path $repo '.tooling'))
if(-not $DataRoot){$DataRoot=Join-Path $tooling 'pg-local'}elseif(-not[IO.Path]::IsPathRooted($DataRoot)){$DataRoot=Join-Path $repo $DataRoot}
$cluster=[IO.Path]::GetFullPath($DataRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
if(-not$cluster.StartsWith($tooling+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)){throw 'DataRoot must be inside this worktree .tooling directory.'}
if($Port-lt1024-or$Port-gt65535){throw 'Invalid local port.'}
$ancestor=$cluster
while($ancestor-and$ancestor-ne$repo){if((Test-Path -LiteralPath $ancestor)-and((Get-Item -LiteralPath $ancestor).Attributes-band[IO.FileAttributes]::ReparsePoint)){throw 'Cluster path cannot contain a junction or symbolic link.'};$ancestor=Split-Path -Parent $ancestor}
$bin='C:\Program Files\PostgreSQL\18\bin'
foreach($name in @('initdb.exe','pg_ctl.exe','psql.exe','createdb.exe')){if(-not(Test-Path -LiteralPath (Join-Path $bin $name))){throw 'PostgreSQL18 binaries unavailable.'}}
$data=Join-Path $cluster 'data';$marker=Join-Path $cluster '.estuda-ai-cluster.json';$passwordFile=Join-Path $cluster 'password.txt'
function Protect-Secret([string]$Path){
 $acl=[Security.AccessControl.FileSecurity]::new();$acl.SetAccessRuleProtection($true,$false)
 $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new([Security.Principal.WindowsIdentity]::GetCurrent().User,'FullControl','Allow'))
 [IO.File]::SetAccessControl($Path,$acl)
}
function Verify-Marker{
 if(-not(Test-Path -LiteralPath $marker)-or-not(Test-Path -LiteralPath $passwordFile)-or-not(Test-Path -LiteralPath (Join-Path $data 'PG_VERSION'))){throw 'Cluster identity missing; foreign data is untouched.'}
 $m=Get-Content -LiteralPath $marker -Raw|ConvertFrom-Json
 if($m.version-ne1-or$m.repo-ne$repo-or$m.root-ne$cluster-or$m.data-ne$data-or$m.port-ne$Port-or$m.user-ne'estuda_ai_local'){throw 'Cluster identity or port mismatch; nothing changed.'}
 foreach($path in @($data,$passwordFile,$marker)){if((Get-Item -LiteralPath $path).Attributes-band[IO.FileAttributes]::ReparsePoint){throw 'Cluster identity path cannot be a link.'}}
}
function Free-Port{
 $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,$Port)
 try{$listener.Start()}catch{throw 'Port occupied; the existing service is untouched.'}finally{$listener.Stop()}
}
function Query([string]$Sql,[string]$Database='postgres'){
 $old=$env:PGPASSWORD
 try{$env:PGPASSWORD=[IO.File]::ReadAllText($passwordFile).Trim();$result=& (Join-Path $bin 'psql.exe') -X -w -h 127.0.0.1 -p $Port -U estuda_ai_local -d $Database -At -v ON_ERROR_STOP=1 -c $Sql 2>&1;if($LASTEXITCODE-ne0){throw 'Local connection failed; see the private server log.'};return $result}finally{$env:PGPASSWORD=$old}
}
function Verify-Running{
 $observed=Query "SELECT current_setting('data_directory')"
 if([IO.Path]::GetFullPath($observed.Trim())-ne$data){throw 'Running PostgreSQL identity mismatch; process is untouched.'}
}
if($Action-eq'Init'){
 if(Test-Path -LiteralPath $marker){Verify-Marker;Write-Output 'Already initialized; data, password and .env preserved.';exit 0}
 if((Test-Path -LiteralPath $cluster)-and@(Get-ChildItem -LiteralPath $cluster -Force).Count-gt0){throw 'Directory contains unrecognized data; initialization refused.'}
 Free-Port;New-Item -ItemType Directory -Path $cluster -Force|Out-Null
 $bytes=New-Object byte[] 32;$rng=[Security.Cryptography.RandomNumberGenerator]::Create();$rng.GetBytes($bytes);$rng.Dispose();$password=-join($bytes|ForEach-Object{$_.ToString('x2')})
 [IO.File]::WriteAllText($passwordFile,$password,[Text.UTF8Encoding]::new($false));Protect-Secret $passwordFile
 & (Join-Path $bin 'initdb.exe') -D $data -U estuda_ai_local -A scram-sha-256 "--pwfile=$passwordFile" -E UTF8 --locale=C --no-instructions *> (Join-Path $cluster 'init.log')
 if($LASTEXITCODE-ne0){throw 'Initialization failed; private init.log retained. No existing cluster changed.'}
 Add-Content -LiteralPath (Join-Path $data 'postgresql.conf') -Value "`nlisten_addresses = '127.0.0.1'`nport = $Port`npassword_encryption = 'scram-sha-256'"
 $identity=@{version=1;repo=$repo;root=$cluster;data=$data;port=$Port;user='estuda_ai_local'}|ConvertTo-Json
 [IO.File]::WriteAllText($marker,$identity,[Text.UTF8Encoding]::new($false))
 $starter=[IO.File]::ReadAllText((Join-Path $repo '.env.example'))-replace '(?m)^DATABASE_URL=.*$',"DATABASE_URL=postgresql://estuda_ai_local:${password}@127.0.0.1:${Port}/estuda_ai"
 $localEnv=Join-Path $cluster 'database.env';[IO.File]::WriteAllText($localEnv,$starter,[Text.UTF8Encoding]::new($false));Protect-Secret $localEnv
 Write-Output 'Initialized local cluster. Private configuration: database.env inside DataRoot. Existing .env untouched. Run Start, then migrate explicitly.';exit 0
}
Verify-Marker
$pidFile=Join-Path $data 'postmaster.pid'
if($Action-eq'Status'){
 if(Test-Path -LiteralPath $pidFile){Verify-Running;Write-Output "Running on 127.0.0.1:$Port (verified cluster)."}else{Write-Output 'Initialized and stopped.'};exit 0
}
if($Action-eq'Stop'){
 if(-not(Test-Path -LiteralPath $pidFile)){Write-Output 'Already stopped.';exit 0}
 Verify-Running;& (Join-Path $bin 'pg_ctl.exe') stop -D $data -m fast -w -t 30 *> (Join-Path $cluster 'stop.log')
 if($LASTEXITCODE-ne0){throw 'Local cluster stop failed; data retained.'};Write-Output 'Stopped; persistent data retained.';exit 0
}
if(Test-Path -LiteralPath $pidFile){Verify-Running;Write-Output 'Already running (verified cluster).';exit 0}
Free-Port
$serverLog=Join-Path $cluster 'server.log'
# Redirect native handles to files so PostgreSQL cannot retain the caller's pipe.
$arguments=@('start','-D',('"'+$data+'"'),'-l',('"'+$serverLog+'"'),'-w','-t','30')
$process=Start-Process -FilePath (Join-Path $bin 'pg_ctl.exe') -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $cluster 'start.log') -RedirectStandardError (Join-Path $cluster 'start-error.log')
$handle=$process.Handle
if(-not$process.WaitForExit(45000)-or$process.ExitCode-ne0){throw 'Local cluster start failed; data retained.'}
Verify-Running
if((Query "SELECT count(*) FROM pg_database WHERE datname = 'estuda_ai'").Trim()-eq'0'){
 $old=$env:PGPASSWORD
 try{$env:PGPASSWORD=[IO.File]::ReadAllText($passwordFile).Trim();& (Join-Path $bin 'createdb.exe') -w -h 127.0.0.1 -p $Port -U estuda_ai_local -T template0 estuda_ai *> (Join-Path $cluster 'createdb.log');if($LASTEXITCODE-ne0){throw 'Local database creation failed; data retained.'}}finally{$env:PGPASSWORD=$old}
}
Write-Output "Running on 127.0.0.1:$Port; database estuda_ai ready for explicit migrations."
