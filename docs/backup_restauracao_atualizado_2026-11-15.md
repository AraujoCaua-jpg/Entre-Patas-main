# Restauração do backup atualizado — 15/11/2026

## Resultado

**A recuperação lógica do banco foi validada em PostgreSQL 17.11 isolado.**
Os dados, definições, proprietários e permissões comparados ficaram equivalentes
ao backup. A segurança da aplicação também corresponde às evidências anteriores
da produção, sem as permissões extras encontradas no ensaio antigo.

Podemos avançar para a **revisão final** de SQL 12 → SQL 15 → SQL 10 → SQL 16.
Isso não autoriza instalação online nem certifica uma recuperação completa do
serviço gerenciado: configurações externas e o procedimento de restauração no
provedor ainda precisam ser preparados. Nenhuma conexão à produção foi feita
nesta rodada; nenhum SQL de migração foi aplicado, nem mesmo ao clone validado.

## Originais e evidências

Diretório externo: `%USERPROFILE%\EntrePatas-Backups\pre-migracao-20261115-014557`.

| Arquivo | Bytes | SHA-256 antes e depois |
| --- | ---: | --- |
| database.dump | 435.784 | `48d9b83e343e3fec1082c06b35ded2570ffc292498e97c411f1af6e9ff27a551` |
| roles.sql | 6.173 | `c23089dda195cd13161b4fdcc74b9b88e4399da22cb845d48e15bc7944b2aee7` |

Os dois hashes permaneceram iguais. Os arquivos foram montados somente para
leitura; nenhum dump foi copiado para o repositório e nenhum backup foi apagado.
As evidências completas, com o histórico de tentativas e sem registros pessoais
ou credenciais, estão na nova subpasta externa:

`validacao-2026-11-15T05-17-03-272Z-448a18/resultado.json`.

Os runners e metadados de trabalho estão em `.dart_tool/`, ignorada pelo Git.
O relatório anterior descreve **outro backup**, antigo, e permanece como
[histórico da tentativa não aprovada](backup_validacao_2026-11-15.md).

## Isolamento demonstrado

- Imagem PostgreSQL: `public.ecr.aws/supabase/postgres:17.11.0.019`.
- Cluster novo, criado com `initdb`, sem executar os scripts de inicialização
  automática do Supabase e sem copiar schemas ou dados do QA.
- Contêiner final: `ep-backup-current-mwhdbs9u-6ee410-db`.
- Rede nova: `ep-backup-current-mwhdbs9u-6ee410-net`, com `internal=true`.
- Volume novo: `ep-backup-current-mwhdbs9u-6ee410-data`.
- Banco final: `entre_patas_final`, criado a partir de `template0`.
- Nenhuma porta publicada; nenhum objeto de conexão externa no arquivo exigiu
  execução. A publicação `supabase_realtime` foi restaurada como objeto local.
- Os 14 contêineres anteriores continuaram presentes; o banco de QA
  `supabase_db_EntrePatas-Restore-Test` continuou em execução.

Ao terminar, somente os novos serviços deste ensaio foram parados. Volumes,
contêineres e evidências foram preservados. O primeiro cluster de diagnóstico
também foi parado, sem exclusão de seus arquivos.

## Verificações executadas

As comparações de dados e catálogo abaixo foram realizadas **antes** de criar a
conta fictícia usada na prova Auth.

| Teste | Resultado | Evidência |
| --- | --- | --- |
| Restauração completa | PASSOU | Execução final transacional com parada em erro; sem omitir owners ou ACLs |
| Conteúdo de todas as tabelas exportadas | PASSOU | 45 blocos COPY, 417 linhas; contagens, colunas e fingerprints ordenados iguais ao original |
| Estrutura, proprietários e ACLs | PASSOU | 642 blocos de objetos equivalentes; zero diferenças finais |
| Papéis, atributos e memberships | PASSOU | 16 papéis; 70 comandos de papéis/concessões equivalentes ao roles.sql |
| Sequências | PASSOU | Sete estados de sequência iguais ao arquivo |
| Funções | PASSOU | 64 funções fora das extensões; nove contratos/definições da aplicação iguais à auditoria anterior |
| Triggers | PASSOU | 13 triggers e sete event triggers preservados pelo DDL comparado |
| RLS e políticas da aplicação | PASSOU | Quatro tabelas com RLS ativa; dez políticas; mesmas regras da origem |
| Default ACL | PASSOU | 24 objetos; os comandos de concessão coincidem com o arquivo |
| Privilégios efetivos da aplicação | PASSOU | Oito entradas de tabela e 72 entradas de coluna iguais ao baseline; sem permissões extras |
| Integridade referencial | PASSOU | 37 FKs verificadas, zero órfãos |
| Unicidade de vínculos | PASSOU | Zero duplicidades de vínculo Auth ou questionário; todos os quatro usuários Auth têm perfil |
| Cadastro, login e consulta Auth | PASSOU | Conta exclusivamente fictícia: HTTP 200 / 200 / 200 |
| Trigger de cadastro restaurado | PASSOU | Exatamente um perfil ativo criado para a conta fictícia |
| Preservação das contas originais | PASSOU | Fingerprints dos usuários, identities e perfis originais iguais após a prova Auth |
| Preservação dos backups | PASSOU | Hashes dos dois originais iguais no começo e no fim |

A contagem de catálogo é de 46 tabelas, incluindo uma fornecida por extensão;
o DDL explícito do arquivo cria 45 tabelas. Isso não é perda nem duplicação de
dados. Os 45 blocos COPY foram comparados individualmente.

Na comparação textual de estrutura, somente a ordem dos mesmos destinatários
de uma política e a ordem dos mesmos comandos de ACL foram normalizadas.
Não foram descartadas diferenças de regras, privilégios ou proprietários.
O baseline de políticas foi consultado com `search_path=public`, para evitar
diferenças de apresentação entre `auth.uid()` e `uid()`.

## Contagens comparadas à auditoria anterior

| Objeto | Evidência anterior de produção | Restaurado |
| --- | ---: | ---: |
| public.cliente | 12 | 12 |
| public.animal | 11 | 11 |
| public.adocao | 2 | 2 |
| public.questionario | 7 | 7 |
| auth.users | 4 | 4 |
| auth.identities | 4 | 4 |
| storage.buckets | 0 | 0 |
| storage.objects | 0 | 0 |

O export antigo tinha dez animais. A cópia atual recuperou os onze esperados.
Os nove animais cujos responsáveis não têm vínculo Auth continuam nessa
situação; nenhum vínculo, usuário ou registro real foi regularizado pelo teste.

## Erros encontrados e procedimento que funcionou

Um `pg_restore` genérico, sem preparar o destino, **não foi suficiente**.
As tentativas malsucedidas estão registradas nas evidências e não foram
contadas como aprovações. Os ajustes abaixo são exclusivamente do clone local.

1. **Grantor dos papéis.** O arquivo usa `GRANTED BY supabase_admin`. Inicializar
   com outro superusuário bootstrap provocou `42501`. O cluster final foi criado
   com `supabase_admin` como bootstrap, OID 10. Na execução do roles.sql, apenas
   seu `CREATE ROLE supabase_admin` já satisfeito foi omitido; seus `ALTER ROLE`
   originais e todos os grants foram executados. A comparação posterior dos 70
   comandos confirmou a equivalência. O arquivo original não foi alterado.
2. **Proprietário de event trigger.** PostgreSQL exige superusuário para atribuir
   o event trigger `ensure_rls` ao papel `postgres`. O arquivo descreve esse papel
   como NOSUPERUSER. No clone, ele recebeu SUPERUSER apenas durante o restore e
   seus atributos originais foram reaplicados imediatamente, inclusive em caso
   de erro. Ao final foi verificado `postgres.rolsuper=false`.
3. **Extensões e permissões iniciais.** Criar todas as extensões como bootstrap
   atribuiu proprietários diferentes a 49 funções e duas views. Alterar seus
   owners depois corrigia o catálogo de aplicação, mas deixava três diferenças
   de representação de ACL em relação a `pg_init_privs`. Essa tentativa não foi
   adotada como resultado final. Em outro banco novo, o SQL extraído do arquivo
   original foi executado em transação única, usando `SET ROLE postgres` apenas
   ao criar `pgcrypto`, `uuid-ossp` e `pg_stat_statements`, seguido de `RESET ROLE`.
   `supabase_vault` permaneceu no contexto original de `supabase_admin`. Não houve
   edição de catálogo nem descarte de ACLs. Os 642 blocos então coincidiram.

Esse procedimento usa `psql` com `ON_ERROR_STOP`, restauração transacional e
preserva as concessões do arquivo. Os ajustes de contexto foram feitos em
memória; `database.dump` e `roles.sql` permaneceram intactos. Não utilizar
`--no-owner`, `--no-acl` ou ignorar erros como forma de obter uma aprovação.

Também ocorreram erros do runner: socket padrão da imagem apontava para TCP,
comparação de OID textual com número e um cast incorreto em consulta de
privilégios. Foram corrigidos e as provas correspondentes foram repetidas.
Esses erros não indicam perda de dados do arquivo.

**Não aplicar as elevações locais de privilégio em produção.** Recuperar um
projeto Supabase gerenciado exige um destino autorizado e o procedimento
compatível com os papéis e permissões do provedor.

## Limitações e requisitos de recuperação

- `roles.sql` não contém senhas de papéis. As credenciais dos serviços do destino
  precisam ser configuradas separadamente. Na prova Auth foram usados somente
  senha PostgreSQL e JWT novos, gerados para o clone.
- Não foram usadas senhas dos quatro usuários restaurados para tentar login.
  Seus registros Auth foram recuperados integralmente e permaneceram iguais;
  a prova de autenticação utilizou uma conta fictícia adicional.
- O dump não contém entradas de criação/propriedades/ACL do banco nem configurações
  da instância. Recriação do banco, rede, TLS, parâmetros e dependências gerenciadas
  continuam parte do procedimento do destino, inclusive replicação lógica.
- O SQL não substitui o inventário de Site URL, redirects, SMTP, OAuth, templates,
  captcha, hooks, chaves de assinatura/API e secrets de Edge Functions. Esses
  itens devem ser preservados por meio privado, fora do GitHub.
- Não há buckets nem objetos Storage no snapshot. Imagens hospedadas em URLs
  externas não são incorporadas ao dump; a disponibilidade delas depende dos
  respectivos serviços. Não foi feito download de dados externos nesta rodada.
- A constraint `realtime.messages_payload_exclusive` já está `NOT VALID` no
  arquivo e foi preservada assim. Não foi validada nem alterada automaticamente.
- A restauração no provedor de produção, com as restrições reais de administração,
  não foi executada. A prova certifica a recuperação lógica neste ambiente PG17,
  e não um rollback instantâneo do serviço online completo.

## Ordem e próximos passos

1. Revisar SQL 12, SQL 15 e SQL 10 com os preflights e pós-verificações existentes.
   A sequência proposta continua **12 → 15 → 10 → 16**; SQL 16 somente lê o estado
   esperado depois das migrações. Nenhum deles foi aplicado nesta rodada.
2. Usar outro clone para o ensaio das migrações, preservando as evidências deste
   restore e os arquivos originais.
3. Confirmar o destino e as permissões disponíveis para recuperação gerenciada,
   além da custódia privada das configurações externas. Este clone não autoriza
   executar comandos de elevação no projeto online.
4. Antes de uma futura instalação, obter autorização explícita, repetir preflight
   e conferir a atualidade do backup. Planejar janela sem gravações concorrentes.
5. Se houver falha, interromper as próximas migrações e examinar a transação e os
   pós-checks. Não reaplicar cegamente o SQL 10 nem sobrescrever o banco online
   com dados antigos. Recuperar primeiro em um destino novo, repetir integridade,
   ACL e Auth, e reconciliar eventuais gravações posteriores antes de um corte
   autorizado. Reversão pontual também exige revisão do SQL específico afetado.

Nenhum commit, push, deploy, redefinição de senha online ou alteração de registros
reais foi executado. Somente documentação e artefatos locais de validação foram
criados nesta rodada; o código Flutter e os scripts de migração não mudaram.
