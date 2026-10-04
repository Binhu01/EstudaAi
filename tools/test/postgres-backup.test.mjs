import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,readFile,chmod,symlink,link} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseConnection,validatePrivateDirectory,backupPostgres,restoreCheck} from '../postgres-backup.mjs';

const env={DATABASE_URL:'postgresql://test:secret-sentinel@127.0.0.1:55433/estuda_ai'};
async function privateDirectory(){
 const dir=await mkdtemp(join(tmpdir(),'estuda-ai-backup-test-'));await chmod(dir,0o700);
 if(process.platform==='win32')await promisify(execFile)('powershell.exe',['-NoProfile','-NonInteractive','-Command',"$ErrorActionPreference='Stop';$p=$env:ESTUDA_AI_BACKUP_TEST_DIRECTORY;$sid=[Security.Principal.WindowsIdentity]::GetCurrent().User;$acl=[Security.AccessControl.DirectorySecurity]::new();$acl.SetAccessRuleProtection($true,$false);$acl.SetOwner($sid);$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'));[IO.Directory]::SetAccessControl($p,$acl)"],{env:{...process.env,ESTUDA_AI_BACKUP_TEST_DIRECTORY:dir},windowsHide:true});
 return dir;
}
async function refuses(work){await assert.rejects(work,e=>e instanceof Error&&!e.message.includes('secret-sentinel'));}

test('database validation accepts loopback and explicit private addresses without weakening TLS',()=>{
 assert.equal(parseConnection(env).host,'127.0.0.1');
 assert.equal(parseConnection({DATABASE_URL:'postgresql://test:private@[::1]:5432/study'}).host,'::1');
 assert.equal(parseConnection({DATABASE_URL:'postgresql://test:private@10.20.30.40:5432/study?sslmode=verify-full'}).sslmode,'verify-full');
});
test('database validation refuses public, malformed and option-injection targets without disclosure',()=>{
 for(const value of ['', 'SECRET', 'https://test:secret-sentinel@127.0.0.1/study', 'postgresql://test:secret-sentinel@8.8.8.8/study', 'postgresql://test:secret-sentinel@database.example/study', 'postgresql://test:secret-sentinel@127.0.0.1/postgres', 'postgresql://test:secret-sentinel@127.0.0.1/study?options=-c%20search_path%3Dpublic']){
  assert.throws(()=>parseConnection({DATABASE_URL:value}),e=>e instanceof Error&&!e.message.includes('secret-sentinel'));
 }
});
test('private directory validation accepts an existing isolated directory',async()=>{const dir=await privateDirectory();assert.equal(await validatePrivateDirectory(dir),dir);});
test('private directory validation refuses missing and relative paths',async()=>{await refuses(()=>validatePrivateDirectory('relative/backups'));const dir=await privateDirectory();await refuses(()=>validatePrivateDirectory(join(dir,'missing')));});
test('private directory validation refuses OneDrive and Git checkout descendants',async()=>{
 const root=await privateDirectory();const synced=join(root,'OneDrive','backups');await mkdir(synced,{recursive:true,mode:0o700});await refuses(()=>validatePrivateDirectory(synced));
 const repo=join(root,'repo');await mkdir(repo);await writeFile(join(repo,'.git'),'gitdir: private');const output=join(repo,'backups');await mkdir(output,{mode:0o700});await refuses(()=>validatePrivateDirectory(output));
});
test('private directory validation refuses symbolic links in any path component',async()=>{
 const root=await privateDirectory(),target=join(root,'target'),link=join(root,'linked');await mkdir(target,{mode:0o700});await symlink(target,link,process.platform==='win32'?'junction':'dir');await refuses(()=>validatePrivateDirectory(link));
});
test('backup refuses an existing output before opening the database and preserves its contents',async()=>{
 const dir=await privateDirectory(),archive=join(dir,'existing.dump');await writeFile(archive,'preserve-me',{mode:0o600});await refuses(()=>backupPostgres({env,archivePath:archive}));assert.equal(await readFile(archive,'utf8'),'preserve-me');
});
test('restore-check refuses unsupported or symlink archives before accessing the database',async()=>{
 const dir=await privateDirectory(),archive=join(dir,'archive.dump');await writeFile(archive,'not-a-pg-archive',{mode:0o600});await refuses(()=>restoreCheck({env,archivePath:archive}));
 const linked=join(dir,'linked.dump');if(process.platform==='win32')await link(archive,linked);else await symlink(archive,linked);await refuses(()=>restoreCheck({env,archivePath:linked}));
});
test('backup refuses unavailable tools without leaking connection data',async()=>{const dir=await privateDirectory();await refuses(()=>backupPostgres({env,outputDirectory:dir,pgBinDirectory:join(dir,'not-found')}));});

test('private directory validation refuses permissions shared with other users',async()=>{
 const dir=await privateDirectory();
 if(process.platform==='win32')await promisify(execFile)('powershell.exe',['-NoProfile','-NonInteractive','-Command',"$ErrorActionPreference='Stop';$p=$env:ESTUDA_AI_BACKUP_TEST_DIRECTORY;$acl=[IO.Directory]::GetAccessControl($p);$everyone=[Security.Principal.SecurityIdentifier]::new('S-1-1-0');$acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($everyone,'ReadAndExecute','ContainerInherit,ObjectInherit','None','Allow'));[IO.Directory]::SetAccessControl($p,$acl)"],{env:{...process.env,ESTUDA_AI_BACKUP_TEST_DIRECTORY:dir},windowsHide:true});else await chmod(dir,0o755);
 await refuses(()=>validatePrivateDirectory(dir));
});
test('backup refuses an existing manifest even when the archive does not exist',async()=>{
 const dir=await privateDirectory(),archive=join(dir,'new.dump');await writeFile(archive+'.manifest.json','preserve-manifest',{mode:0o600});await refuses(()=>backupPostgres({env,archivePath:archive}));assert.equal(await readFile(archive+'.manifest.json','utf8'),'preserve-manifest');
});
test('restore-check identifies tampering before running PostgreSQL or creating a database',async()=>{
 const dir=await privateDirectory(),archive=join(dir,'tampered.dump');await writeFile(archive,'tampered-data',{mode:0o600});await writeFile(archive+'.manifest.json',JSON.stringify({version:1,format:'postgres-custom',tables:[],sha256:'a'.repeat(64),schemaSha256:'b'.repeat(64)}),{mode:0o600});
 await assert.rejects(()=>restoreCheck({env,archivePath:archive,pgBinDirectory:join(dir,'missing-tools')}),e=>e.code==='INTEGRITY_FAILED'&&!e.message.includes('secret-sentinel'));
});
test('private network connections cannot explicitly disable encryption',()=>{assert.throws(()=>parseConnection({DATABASE_URL:'postgresql://test:secret-sentinel@10.20.30.40/study?sslmode=disable'}));});

test('real archive preserves varchar-array checks, rows, and increasing sequences', {skip:!process.env.BACKUP_TEST_DATABASE_URL}, async t=>{
 const {default:pg}=await import('pg');const {randomUUID}=await import('node:crypto');
 const fixture='estuda_ai_backup_test_'+randomUUID().replaceAll('-','');let admin,source,restored;
 try{
  admin=new pg.Client({connectionString:process.env.BACKUP_TEST_DATABASE_URL});await admin.connect();await admin.query('CREATE DATABASE "'+fixture+'" TEMPLATE template0 ENCODING \'UTF8\'');
  const url=new URL(process.env.BACKUP_TEST_DATABASE_URL);url.pathname='/'+fixture;const testEnv={DATABASE_URL:url.href};source=new pg.Client({connectionString:url.href});await source.connect();
  await source.query(`CREATE TABLE "ArrayCheck"(id BIGSERIAL PRIMARY KEY,status VARCHAR(10) NOT NULL CHECK(status IN ('quiz','review')));INSERT INTO "ArrayCheck"(status) VALUES ('quiz');SELECT setval('"ArrayCheck_id_seq"',101,true)`);
  const backup=await backupPostgres({env:testEnv,outputDirectory:await privateDirectory(),pgBinDirectory:process.env.PG_BIN_DIRECTORY});
  const result=await restoreCheck({env:testEnv,archivePath:backup.archivePath,pgBinDirectory:process.env.PG_BIN_DIRECTORY});assert.equal(result.status,'passed');
  url.pathname='/'+result.database;restored=new pg.Client({connectionString:url.href});await restored.connect();assert.equal((await restored.query('SELECT status FROM "ArrayCheck"')).rows[0].status,'quiz');
  await assert.rejects(()=>restored.query("INSERT INTO \"ArrayCheck\"(status) VALUES ('invalid')"),e=>e.code==='23514');
  assert.equal((await restored.query('SELECT nextval(\'"ArrayCheck_id_seq"\')::text AS value')).rows[0].value,'103');
  const initial=JSON.parse(await readFile(backup.archivePath+'.manifest.json','utf8'));
  await restored.query(`ALTER TABLE "ArrayCheck" DROP CONSTRAINT "ArrayCheck_status_check", ADD CONSTRAINT "ArrayCheck_status_check" CHECK(status IN ('quiz','review','invalid'))`);
  const changed=await backupPostgres({env:{DATABASE_URL:url.href},outputDirectory:await privateDirectory(),pgBinDirectory:process.env.PG_BIN_DIRECTORY});
  const mutation=JSON.parse(await readFile(changed.archivePath+'.manifest.json','utf8'));
  assert.notEqual(mutation.schemaSha256,initial.schemaSha256,'A changed CHECK must not certify an identical schema');assert.deepEqual(mutation.tables,initial.tables);
  t.diagnostic('Dedicated fixture and restored UUID databases preserved: '+fixture+', '+result.database);
 }catch(error){throw new Error('Isolated PostgreSQL regression failed: '+(error.code??'validation')+'. Fixture preserved: '+fixture);}
 finally{await restored?.end().catch(()=>{});await source?.end().catch(()=>{});await admin?.end().catch(()=>{});}
});
