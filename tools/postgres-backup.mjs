import {spawn} from 'node:child_process';
import {createHash,randomUUID} from 'node:crypto';
import {createReadStream} from 'node:fs';
import {lstat,readFile,open,chmod} from 'node:fs/promises';
import {isAbsolute,resolve,dirname,basename,join} from 'node:path';
import {isIP} from 'node:net';
import {pathToFileURL} from 'node:url';
import pg from 'pg';

class BackupError extends Error{constructor(message,code='INVALID_INPUT'){super(message);this.code=code;}}
const fail=(message,code)=>{throw new BackupError(message,code);};
const identifier=s=>'"'+s.replaceAll('"','""')+'"';
const digest=value=>createHash('sha256').update(value).digest('hex');
const operatingEnvironment=()=>Object.fromEntries(['PATH','Path','SystemRoot','SYSTEMROOT','ComSpec','TEMP','TMP','USERPROFILE','APPDATA','LOCALAPPDATA'].filter(k=>process.env[k]).map(k=>[k,process.env[k]]));
function privateHost(host){
 if(host==='localhost'||host==='::1')return true;
 if(isIP(host)===4){const [a,b]=host.split('.').map(Number);return a===127||a===10||(a===172&&b>=16&&b<=31)||(a===192&&b===168);}
 return isIP(host)===6&&/^(fc|fd)[0-9a-f]{2}:/i.test(host);
}
export function parseConnection(env=process.env){
 try{
  const u=new URL(env.DATABASE_URL??''),host=u.hostname.replace(/^\[|\]$/g,''),database=decodeURIComponent(u.pathname.slice(1)),user=decodeURIComponent(u.username),password=decodeURIComponent(u.password),port=Number(u.port||5432);
  if(!['postgres:','postgresql:'].includes(u.protocol)||!privateHost(host)||!user||!password||!Number.isInteger(port)||port<1||port>65535||!/^[A-Za-z_][A-Za-z0-9_-]{0,62}$/.test(database)||['postgres','template0','template1'].includes(database)||u.hash)throw Error();
  if([...u.searchParams.keys()].some(k=>!['sslmode','sslrootcert'].includes(k)))throw Error();
  const loopback=host==='localhost'||host==='::1'||host.startsWith('127.'),sslmode=u.searchParams.get('sslmode')??(loopback?'disable':'require');
  if(!['disable','require','verify-ca','verify-full'].includes(sslmode)||(!loopback&&sslmode==='disable'))throw Error();
  const sslrootcert=u.searchParams.get('sslrootcert')??undefined;
  if(sslrootcert&&!isAbsolute(sslrootcert))throw Error();
  return {host,port,database,user,password,sslmode,sslrootcert};
 }catch{fail('DATABASE_URL inválida: use um banco de aplicação em localhost ou IP privado explícito.');}
}
async function native(command,args,env=operatingEnvironment()){
 return await new Promise((accept,reject)=>{
  const child=spawn(command,args,{env,windowsHide:true,stdio:['ignore','pipe','ignore']});let output='',failed=false;
  const timer=setTimeout(()=>{failed=true;child.kill();reject(new BackupError('Tempo de execução PostgreSQL excedido; arquivos e banco de ensaio foram preservados.','TIMEOUT'));},180000);
  child.stdout.on('data',chunk=>{if(output.length<100000)output+=chunk.toString();});
  child.on('error',()=>{clearTimeout(timer);if(!failed)reject(new BackupError('Ferramenta PostgreSQL indisponível.','TOOL_UNAVAILABLE'));});
  child.on('close',code=>{clearTimeout(timer);if(!failed)(code===0?accept(output):reject(new BackupError('Ferramenta PostgreSQL falhou; confira a configuração privada.','TOOL_FAILED')));});
 });
}
async function windowsPermissions(path,protect=false){
 const script=protect?
  "$p=$env:ESTUDA_AI_BACKUP_PRIVATE_PATH;$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User;$acl=[Security.AccessControl.FileSecurity]::new();$acl.SetAccessRuleProtection($true,$false);$acl.SetOwner($sid);$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','Allow'));[IO.File]::SetAccessControl($p,$acl)":
  "$p=$env:ESTUDA_AI_BACKUP_PRIVATE_PATH;$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value;$a=if(([IO.File]::GetAttributes($p) -band [IO.FileAttributes]::Directory)){[IO.Directory]::GetAccessControl($p)}else{[IO.File]::GetAccessControl($p)};$ok=($a.Owner -eq [Security.Principal.WindowsIdentity]::GetCurrent().Name);foreach($r in $a.Access){if($r.AccessControlType -eq 'Allow'){$v=$r.IdentityReference.Translate([Security.Principal.SecurityIdentifier]).Value;if($v -notin @($sid,'S-1-5-18','S-1-5-32-544')){$ok=$false}}};if(-not $ok){exit 2}";
 await native('powershell.exe',['-NoProfile','-NonInteractive','-Command',"$ErrorActionPreference='Stop';"+script],{...operatingEnvironment(),ESTUDA_AI_BACKUP_PRIVATE_PATH:path});
}
async function checkPermissions(path,stat){
 if(process.platform==='win32')await windowsPermissions(path);
 else if(stat.uid!==process.getuid()||(stat.mode&0o077)!==0)fail('A pasta/arquivo de backup deve pertencer ao usuário atual e ter acesso exclusivo.');
}
export async function validatePrivateDirectory(path){
 if(typeof path!=='string'||!isAbsolute(path)||path.startsWith('\\\\')||path.startsWith('//'))fail('Informe uma pasta privada absoluta existente.');
 const target=resolve(path);let current=target;
 const boundary=process.platform==='win32'&&process.env.LOCALAPPDATA?resolve(process.env.LOCALAPPDATA):undefined;
 let inspectGit=true;const insideBoundary=boundary&&(target===boundary||target.toLowerCase().startsWith(boundary.toLowerCase()+'\\'));
 try{
  for(;;){
   const stat=await lstat(current);if(!stat.isDirectory()||stat.isSymbolicLink())fail('O caminho de backup não pode conter links ou junctions.');
   if(/^onedrive(?:$|[ _-])/i.test(basename(current)))fail('Backups não podem ficar em pastas OneDrive.');
   if(inspectGit){try{await lstat(join(current,'.git'));fail('Backups não podem ficar dentro de um repositório Git.');}catch(error){if(error.code!=='ENOENT')throw error;}}
   if(insideBoundary&&current.toLowerCase()===boundary.toLowerCase())inspectGit=false;
   const parent=dirname(current);if(parent===current)break;current=parent;
  }
  await checkPermissions(target,await lstat(target));return target;
 }catch(error){if(error.code)fail('A pasta privada não está disponível.');throw error;}
}
async function protectedFile(path){
 if(!isAbsolute(path))fail('Informe o caminho absoluto do backup.');
 await validatePrivateDirectory(dirname(path));const stat=await lstat(path);
 if(!stat.isFile()||stat.isSymbolicLink()||stat.nlink!==1)fail('O backup deve ser arquivo regular, sem links.');
 await checkPermissions(path,stat);return path;
}
async function newPrivateFile(path,contents=''){
 const file=await open(path,'wx',0o600);try{if(process.platform==='win32')await windowsPermissions(path,true);else await chmod(path,0o600);await file.writeFile(contents);await file.sync();}finally{await file.close();}
}
async function hashFile(path){const hash=createHash('sha256');for await(const chunk of createReadStream(path))hash.update(chunk);return hash.digest('hex');}
function tool(name,bin){if(bin&&!isAbsolute(bin))fail('PG_BIN_DIRECTORY deve ser absoluto.');return bin?join(bin,name+(process.platform==='win32'?'.exe':'')):name;}
function nativeEnv(config,database=config.database){return {...operatingEnvironment(),PGHOST:config.host,PGPORT:String(config.port),PGDATABASE:database,PGUSER:config.user,PGPASSWORD:config.password,PGSSLMODE:config.sslmode,...(config.sslrootcert?{PGSSLROOTCERT:config.sslrootcert}:{}),PGCONNECT_TIMEOUT:'10'};}
async function connection(config,database=config.database){
 const ssl=config.sslmode==='disable'?false:{rejectUnauthorized:config.sslmode!=='require',...(config.sslrootcert?{ca:await readFile(config.sslrootcert,'utf8')}: {})};
 const client=new pg.Client({...config,database,ssl,connectionTimeoutMillis:10000,query_timeout:120000});await client.connect();await client.query("SET timezone='UTC'; SET datestyle='ISO, YMD'");return client;
}
async function schema(client){
 const relations=(await client.query(`SELECT n.nspname AS schema,c.relname AS name,c.relkind AS kind,
  coalesce((SELECT jsonb_agg(jsonb_build_object('name',a.attname,'type',format_type(a.atttypid,a.atttypmod),'required',a.attnotnull,'default',pg_get_expr(d.adbin,d.adrelid),'identity',a.attidentity,'generated',a.attgenerated) ORDER BY a.attnum) FROM pg_attribute a LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum WHERE a.attrelid=c.oid AND a.attnum>0 AND NOT a.attisdropped),'[]'::jsonb) AS columns,
  coalesce((SELECT jsonb_agg(jsonb_build_object('name',conname,'type',contype,'validated',convalidated,'noInherit',connoinherit,'deferrable',condeferrable,'initiallyDeferred',condeferred,'definition',pg_get_constraintdef(oid)) ORDER BY conname) FROM pg_constraint WHERE conrelid=c.oid),'[]'::jsonb) AS constraints,
  coalesce((SELECT jsonb_agg(pg_get_indexdef(indexrelid) ORDER BY pg_get_indexdef(indexrelid)) FROM pg_index WHERE indrelid=c.oid),'[]'::jsonb) AS indexes,
  CASE WHEN c.relkind IN ('v','m') THEN pg_get_viewdef(c.oid) ELSE NULL END AS definition
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname NOT LIKE 'pg_%' AND n.nspname<>'information_schema' AND c.relkind IN ('r','p','v','m','f') ORDER BY n.nspname,c.relname`)).rows;
 if(relations.some(r=>r.kind==='f'))fail('Bancos com foreign tables exigem uma estratégia de backup própria.');
 // pg_dump/restore may reparse equivalent IN/ARRAY casts differently. Compare
 // PostgreSQL's canonical planned expression, not its original spelling.
 // EXPLAIN without ANALYZE does not execute the query. Trusted immutable
 // functions may still be simplified by PostgreSQL during planning.
 for(const relation of relations){
  const table=identifier(relation.schema)+'.'+identifier(relation.name);
  for(const constraint of relation.constraints.filter(c=>c.type==='c')){
   const expression=(await client.query('SELECT pg_get_expr(conbin,conrelid) AS expression FROM pg_constraint WHERE conrelid=$1::regclass AND conname=$2',[table,constraint.name])).rows[0].expression;
   const plan=(await client.query('EXPLAIN (VERBOSE, FORMAT JSON, COSTS OFF) SELECT ('+expression+') AS verified_check FROM '+table)).rows[0]['QUERY PLAN'][0].Plan;
   if(!Array.isArray(plan.Output)||plan.Output.length!==1)fail('Não foi possível conferir a expressão canônica da constraint.');
   constraint.definition=plan.Output[0];
  }
 }
 const sequences=(await client.query(`SELECT n.nspname AS schema,c.relname AS name,s.seqtypid::regtype::text AS type,s.seqstart::text AS start,s.seqincrement::text AS increment,s.seqmin::text AS min,s.seqmax::text AS max,s.seqcache::text AS cache,s.seqcycle AS cycle FROM pg_sequence s JOIN pg_class c ON c.oid=s.seqrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname NOT LIKE 'pg_%' ORDER BY n.nspname,c.relname`)).rows;
 const extensions=(await client.query('SELECT extname AS name,extversion AS version FROM pg_extension ORDER BY extname')).rows;
 return {relations,sequences,extensions};
}
async function fingerprints(client,structure){
 const tables=[];
 for(const r of structure.relations.filter(r=>['r','p','m'].includes(r.kind))){
  const result=(await client.query(`SELECT count(*)::text AS count,md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text) COLLATE "C"),'')) AS fingerprint FROM ${identifier(r.schema)}.${identifier(r.name)} t`)).rows[0];
  tables.push({schema:r.schema,name:r.name,...result});
 }
 return tables;
}
async function sequenceSafety(client){
 const serials=(await client.query(`SELECT n.nspname AS schema,c.relname AS table,a.attname AS column,pg_get_serial_sequence(format('%I.%I',n.nspname,c.relname),a.attname) AS sequence FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace JOIN pg_attribute a ON a.attrelid=c.oid WHERE c.relkind IN ('r','p') AND n.nspname NOT LIKE 'pg_%' AND a.attnum>0 AND NOT a.attisdropped`)).rows.filter(r=>r.sequence);
 for(const r of serials){
  const position=(await client.query(`SELECT last_value::text AS value,is_called FROM ${r.sequence}`)).rows[0];
  const max=(await client.query(`SELECT max(${identifier(r.column)})::text AS value FROM ${identifier(r.schema)}.${identifier(r.table)}`)).rows[0].value;
  const increment=(await client.query('SELECT seqincrement::text AS value FROM pg_sequence WHERE seqrelid=$1::regclass',[r.sequence])).rows[0].value;
  // Default sequences in this app increase. Refuse unsupported decreasing/custom reuse.
  if(BigInt(increment)<=0n||(max!==null&&(BigInt(position.value)<BigInt(max)||(!position.is_called&&BigInt(position.value)<=BigInt(max)))))fail('Sequência restaurada incompatível com os registros.');
 }
 return serials.length;
}
export async function backupPostgres({env=process.env,outputDirectory=env.BACKUP_DIRECTORY,archivePath,pgBinDirectory=env.PG_BIN_DIRECTORY}={}){
 const config=parseConnection(env);let client;
 try{
  if(archivePath){if(!isAbsolute(archivePath)||!archivePath.endsWith('.dump'))fail('O backup deve ter caminho absoluto e extensão .dump.');await validatePrivateDirectory(dirname(archivePath));}
  else{const dir=await validatePrivateDirectory(outputDirectory);archivePath=join(dir,'estuda-ai-'+new Date().toISOString().replaceAll(':','-')+'-'+randomUUID()+'.dump');}
  for(const path of [archivePath,archivePath+'.manifest.json',archivePath+'.schema.sql']){try{await lstat(path);fail('O destino já existe; nada será sobrescrito.');}catch(error){if(error.code!=='ENOENT')throw error;}}
  const executable=tool('pg_dump',pgBinDirectory);await native(executable,['--version']);await native(tool('pg_restore',pgBinDirectory),['--version']);
  client=await connection(config);await client.query('BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY');
  const snapshot=(await client.query('SELECT pg_export_snapshot() AS id')).rows[0].id;
  const structure=await schema(client),tables=await fingerprints(client,structure);
  await newPrivateFile(archivePath);
  await native(executable,['--format=custom','--no-password','--no-owner','--no-acl','--snapshot='+snapshot,'--file='+archivePath],nativeEnv(config));
  await client.query('COMMIT');
  const schemaSqlPath=archivePath+'.schema.sql';await newPrivateFile(schemaSqlPath);
  await native(tool('pg_restore',pgBinDirectory),['--schema-only','--no-owner','--no-acl','--file='+schemaSqlPath,archivePath]);
  const manifest={version:1,format:'postgres-custom',createdAt:new Date().toISOString(),sha256:await hashFile(archivePath),schemaSqlSha256:await hashFile(schemaSqlPath),schemaSha256:digest(JSON.stringify(structure)),tables};
  await newPrivateFile(archivePath+'.manifest.json',JSON.stringify(manifest,null,2)+'\n');
  return {status:'passed',archivePath,schemaSqlPath,sha256:manifest.sha256,tables:tables.length,snapshot:'shared-read-only'};
 }catch(error){if(error instanceof BackupError)throw error;fail('Backup não concluído; original e arquivos parciais foram preservados.','BACKUP_FAILED');}
 finally{if(client){await client.query('ROLLBACK').catch(()=>{});await client.end().catch(()=>{});}}
}
export async function restoreCheck({env=process.env,archivePath,pgBinDirectory=env.PG_BIN_DIRECTORY}={}){
 const config=parseConnection(env);let admin,restored;let database;
 try{
  await protectedFile(archivePath);await protectedFile(archivePath+'.manifest.json');
  if((await lstat(archivePath+'.manifest.json')).size>10000000)fail('Manifesto inválido.');
  const manifest=JSON.parse(await readFile(archivePath+'.manifest.json','utf8'));
  if(manifest.version!==1||manifest.format!=='postgres-custom'||!Array.isArray(manifest.tables)||!/^[a-f0-9]{64}$/.test(manifest.sha256)||!/^[a-f0-9]{64}$/.test(manifest.schemaSha256)||await hashFile(archivePath)!==manifest.sha256)fail('Integridade do backup não confirmada; restauração recusada.','INTEGRITY_FAILED');
  if(manifest.schemaSqlSha256){await protectedFile(archivePath+'.schema.sql');if(await hashFile(archivePath+'.schema.sql')!==manifest.schemaSqlSha256)fail('Integridade do schema SQL não confirmada.','INTEGRITY_FAILED');}
  const executable=tool('pg_restore',pgBinDirectory);await native(executable,['--version']);await native(tool('pg_dump',pgBinDirectory),['--version']);await native(executable,['--list',archivePath]);
  admin=await connection(config);database='estuda_ai_restore_'+randomUUID().replaceAll('-','');
  // No destination argument, DROP, --clean, or replacement: CREATE refuses collisions.
  await admin.query(`CREATE DATABASE ${identifier(database)} TEMPLATE template0 ENCODING 'UTF8'`);
  await native(executable,['--exit-on-error','--single-transaction','--no-password','--no-owner','--no-acl','--dbname='+database,archivePath],nativeEnv(config,database));
  const schemaSqlPath=archivePath+'.restored-'+database+'.schema.sql';await newPrivateFile(schemaSqlPath);
  await native(tool('pg_dump',pgBinDirectory),['--schema-only','--no-password','--no-owner','--no-acl','--file='+schemaSqlPath],nativeEnv(config,database));
  restored=await connection(config,database);const structure=await schema(restored),tables=await fingerprints(restored,structure);
  if(digest(JSON.stringify(structure))!==manifest.schemaSha256||JSON.stringify(tables)!==JSON.stringify(manifest.tables))fail('Dados ou schema restaurados divergem do snapshot.');
  const sequences=await sequenceSafety(restored);
  return {status:'passed',database,schemaSqlPath,sha256:manifest.sha256,tables:tables.length,sequences,preserved:true};
 }catch(error){const safe=error instanceof BackupError?error:new BackupError('Ensaio de restauração não concluído; original preservado. Eventual banco UUID criado foi mantido para diagnóstico.','RESTORE_FAILED');safe.database=database;throw safe;}
 finally{await restored?.end().catch(()=>{});await admin?.end().catch(()=>{});}
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
 try{
  const [action,path,...extra]=process.argv.slice(2);if(extra.length||!['backup','restore-check'].includes(action))fail('Use backup [arquivo.dump] ou restore-check arquivo.dump.');
  const report=action==='backup'?await backupPostgres({archivePath:path}):await restoreCheck({archivePath:path});console.log(JSON.stringify(report,null,2));
 }catch(error){console.error(JSON.stringify({status:'failed',code:error.code,message:error.message,database:error.database}));process.exitCode=1;}
}
