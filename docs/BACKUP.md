# Backup e ensaio de restauração

O utilitário `tools/postgres-backup.mjs` cria um arquivo PostgreSQL custom (`pg_dump -Fc`) e verifica sua restauração em **um banco novo com UUID**. Nunca escolhe um banco existente como destino, não usa `--clean`, não substitui arquivos e não exclui bancos. O banco original é lido; os bancos de ensaio e seus arquivos permanecem disponíveis.

## Configuração privada

Use Node 24 e `pg_dump`/`pg_restore` da versão compatível com o servidor. No Windows validado, os executáveis estão em `C:/Program Files/PostgreSQL/18/bin`. A conexão vem de `DATABASE_URL` em ambiente privado; a senha vai para o processo PostgreSQL por variável de ambiente, sem aparecer em argumentos ou relatórios. Nenhuma integração Firebase/OpenAI é chamada.

O utilitário aceita localhost ou IP privado explícito. Recusa nomes externos, endereços públicos, bancos administrativos e opções de conexão desconhecidas. Fora de loopback exige TLS; `sslmode=verify-full` e `sslrootcert` absoluto permitem verificar o certificado. Hosts gerenciados públicos precisam de um acesso privado apropriado e validação própria no destino.

`BACKUP_DIRECTORY` deve apontar para uma pasta absoluta já existente, privada, fora de projetos Git e OneDrive, sem symlinks/junctions. No Windows, `LOCALAPPDATA` é o limite de pasta privada: repositórios dentro dele são recusados, sem tratar um `.git` no perfil inteiro como parte do aplicativo. A pasta deve pertencer ao usuário atual; somente o usuário, SYSTEM e Administrators podem ter acesso. Os arquivos criados recebem acesso exclusivo do usuário. Em Linux, a pasta/arquivo deve pertencer ao usuário atual e negar acesso a grupo/outros (`700`/`600`).

A pasta usada nesta validação é `C:/Users/glaub/AppData/Local/EstudaAi/backups`, criada com ACL privada. Em outra instalação, crie uma pasta nova com essas permissões; não enfraqueça as permissões nem altere automaticamente uma pasta compartilhada preexistente.

```powershell
$env:BACKUP_DIRECTORY='C:/Users/glaub/AppData/Local/EstudaAi/backups'
$env:PG_BIN_DIRECTORY='C:/Program Files/PostgreSQL/18/bin'
node --env-file='C:/Users/glaub/AppData/Local/EstudaAi/backend.env' tools/postgres-backup.mjs backup
```

O comando retorna o caminho gerado. Também pode receber um caminho absoluto novo terminado em `.dump`. Se o dump, manifesto ou schema SQL correspondente já existir, recusa a operação e preserva o arquivo. Não copie credenciais para esses arquivos nem para o Git.

## O que o backup verifica

Uma transação read-only exporta o snapshot e o compartilha com `pg_dump --snapshot`. O manifesto recebe contagens e fingerprints de todas as tabelas desse **mesmo snapshot**; não compara o arquivo com o banco vivo em um instante posterior. Isso evita divergências falsas quando alunos respondem durante o backup.

São produzidos três arquivos privados:

- `.dump`: arquivo custom com schema, dados e sequências.
- `.dump.manifest.json`: SHA256 do arquivo e do schema SQL, hash do schema canônico, contagens/fingerprints de tabelas. Não contém registros, senhas ou conversas.
- `.dump.schema.sql`: schema SQL extraído do próprio arquivo, preservado para diagnóstico.

A leitura compara colunas, tipos, defaults, nullability, índices, views, parâmetros de sequências, extensões e constraints com seus atributos `validated`, `noInherit`, `deferrable` e `initiallyDeferred`. Para CHECK, PostgreSQL pode reescrever casts equivalentes durante dump/restore. O utilitário usa `pg_get_expr` e `EXPLAIN VERBOSE` sem ANALYZE para obter a expressão canônica do próprio PostgreSQL, mantendo os demais atributos. Não remove casts/constraints por regex. EXPLAIN não executa a consulta, embora funções IMMUTABLE confiáveis possam ser simplificadas durante o planejamento.

Esse utilitário é destinado ao schema de aplicação confiável. Bancos com foreign tables são recusados. Fingerprints de linhas servem à comparação da restauração; SHA256 verifica corrupção dos arquivos, não substitui assinatura nem proteção de acesso. A agregação de fingerprints lê todas as linhas e precisa ser dimensionada/testada novamente para volumes comerciais grandes.

## Ensaio seguro

```powershell
node --env-file='C:/Users/glaub/AppData/Local/EstudaAi/backend.env' tools/postgres-backup.mjs restore-check 'C:/pasta-privada/arquivo.dump'
```

O ensaio confere permissões, arquivo regular sem links, manifesto e SHA256 antes de criar qualquer banco. Cria apenas `estuda_ai_restore_<UUID>`, usando `CREATE DATABASE`, que recusa colisões. A role configurada precisa já permitir essa criação; o utilitário não concede privilégios.

`pg_restore --exit-on-error --single-transaction --no-owner --no-acl` restaura o conteúdo. Em seguida o utilitário compara schema e dados ao manifesto do snapshot e verifica que as sequências crescentes vinculadas às colunas não podem gerar um próximo valor já ocupado. Não exige igualdade com valores atuais do banco original: sequências PostgreSQL não seguem snapshots MVCC. Um schema SQL adicional do banco restaurado também é guardado junto ao arquivo, com UUID no nome, sem modificar os SQLs originais.

Código 0 confirma sucesso. Código 1 confirma recusa/falha com mensagem segura; erros de banco e processos não revelam credenciais. Uma tentativa que já criou o banco de ensaio informa seu nome seguro e o preserva para diagnóstico. Arquivos incompletos permanecem privados e não recebem confirmação de backup válido.

O ensaio prova recuperação em um destino separado. Trocar a aplicação para um banco restaurado, alterar DNS e remover os bancos de teste são decisões operacionais posteriores; nenhuma dessas ações é automática.

## Evidência de 04/10/2026

As 13 regressões locais passaram; a regressão adicional PostgreSQL18 foi ativada explicitamente e a suíte completa desse utilitário passou **14/14**. Cobertura: conexões recusadas, TLS, pasta relativa/ausente/Git/OneDrive, junction/link de arquivo, permissões compartilhadas, destinos já existentes, ferramentas ausentes e corrupção detectada antes de executar PostgreSQL.

A repetição final da suíte completa de ferramentas com o ensaio real ativado passou **54/54**, sem testes ignorados.

A regressão real reproduziu CHECK `status IN ('quiz','review')` em VARCHAR: falhou antes da canonicalização e passou depois. Também mudou a CHECK para admitir outro valor e confirmou hash de schema diferente com dados idênticos. Fixture isolada adicional verificou dados UTF8/NUMERIC, PRIMARY KEY, UNIQUE, NOT NULL, FOREIGN KEY, CHECK e sequência restaurada de 101 para próximo valor 102.

O banco real do aplicativo foi copiado e restaurado com sucesso: **7 tabelas**, comparação integral dos registros por contagem/fingerprint e **1 sequência**. O original foi preservado. Arquivos privados:

- Dump: `estuda-ai-2026-10-04T14-02-06.739Z-c9a6b6aa-4f39-4e7a-b8a2-fecf35145eb9.dump` na pasta privada acima.
- SHA256: `d7a86d1612e8706770a0d687b44a807797084d562b427d398be29b4fdceb7ab6`.
- Banco recuperado mantido: `estuda_ai_restore_e9dc56442ad1437196368c6bd665bddf`.

A execução normal `node --test tools/test/postgres-backup.test.mjs` roda 13 testes e deixa o ensaio real desativado. Para ativá-lo, forneça `BACKUP_TEST_DATABASE_URL` de um banco de aplicação privado e `PG_BIN_DIRECTORY`, sem publicar valores; o teste cria seus próprios bancos UUID e os preserva. Nenhum destino remoto ou rotina de retenção foi contratado/agendado.

## Operação no destino

Antes de migrar, gere backup e execute o ensaio. No destino escolhido, defina uma cópia externa criptografada, frequência, retenção e teste periódico de recuperação; mantenha uma cópia anterior à migração. A execução local não configura armazenamento externo, agenda nem exclusão de versões antigas. As contas do Firebase e suas credenciais são recursos separados do PostgreSQL e precisam de procedimentos próprios.

Referências oficiais: [pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html), [pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html) e [backup PostgreSQL](https://www.postgresql.org/docs/current/backup.html).
