# Plano de recuperação em Supabase gerenciado — 15/11/2026

> Atualização: a restauração seletiva foi posteriormente executada e validada
> exclusivamente em `juqnompkixqltwjldzva`, com prova real de Auth e RLS.
> Consulte o [resultado gerenciado](recuperacao_gerenciada_2026-11-15.md).
> O texto abaixo preserva o planejamento anterior; as permissões/destino foram
> comprovados nessa execução, enquanto configurações externas continuam separadas.

## Veredito e alcance

O backup `pre-migracao-20261115-014557` é recuperável logicamente e o ensaio das
migrações passou. Não há defeito pendente conhecido de SQL 12/15/10 que impeça
solicitar autorização. **A execução online continua condicionada aos acessos de
recuperação e à custódia das configurações externas.** A restauração em um projeto
Supabase gerenciado ainda não foi executada nem certificada.

Este plano usa os relatórios de [restauração](backup_restauracao_atualizado_2026-11-15.md)
e [ensaio](ensaio_final_migracoes_2026-11-15.md) e a documentação oficial consultada
em 15/11/2026. Nesta revisão não houve conexão a bancos, criação de projeto,
restauração, migração, publicação ou repetição dos testes locais aprovados.

## Destino novo: procedimento previsto, ainda não executado

1. **Preparar um projeto novo autorizado**, com PostgreSQL 17 e identidade de
   destino registrada. Não apontar o aplicativo, domínio ou integrações de produção
   para ele durante a recuperação. Acesso pelo usuário administrativo `postgres`,
   conexão direta ou session pooler, credencial privada e TLS. Não reutilizar o
   vínculo CLI salvo do projeto original; identificar explicitamente o novo destino
   em cada operação. O fluxo oficial é
   restaurar papéis, schema e dados com parada em erro e transação única.
   [Guia oficial de restauração manual](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore#restore-backup-using-cli).
2. **Preservar os originais.** Em outra pasta externa privada, derivar do
   `database.dump` uma lista TOC e SQL separado em pre-data, data e post-data.
   `pg_restore --list`, `--use-list` e `--section` permitem essa seleção; o arquivo
   custom não deve ser entregue diretamente ao `psql`. Esta preparação e a lista
   final dependem do catálogo do novo destino e não foram executadas nesta revisão.
   [PostgreSQL 17: pg_restore](https://www.postgresql.org/docs/17/app-pgrestore.html).
3. **Tratar roles.sql como inventário, não reaplicá-lo inteiro.** Ele contém 16
   papéis, sem senhas; não foi identificado papel próprio da aplicação. O destino
   já fornece os papéis Supabase. Preservar suas credenciais e atributos; não
   recriar `supabase_admin`, importar o papel transitório `cli_login_postgres` ou
   repetir seus grants. Criar somente um papel customizado se a revisão identificar
   necessidade real. Registrar cada exclusão da cópia de trabalho.
   [Papéis gerenciados](https://supabase.com/docs/guides/database/postgres/roles).
4. **Reconciliar o dump com a base gerenciada.** Selecionar tabelas, funções,
   policies, índices, sequências e grants da aplicação em public/private. Preservar
   o DDL mantido pelo destino em auth/storage/realtime, extensões e schemas de
   plataforma. Não classificar objetos apenas pelo schema: `public.rls_auto_enable()` e o
   event trigger `ensure_rls` também exigem comparação com a plataforma do destino.
   Não copiar por cima seus marcadores de migração: o backup contém
   82 de Auth, 81 de Storage e 96 de Realtime. Restaurar os dados Auth e as
   customizações da aplicação, incluindo o trigger
   `on_entre_patas_auth_user_created ON auth.users`, que chama
   `private.criar_cliente_entre_patas()`. Incluir os estados das sequências usados
   pelas tabelas carregadas, inclusive quando o DDL da sequência é gerenciado,
   para evitar colisões de IDs nas próximas inserções.
   Essa seleção é uma adaptação necessária deste dump completo, não uma importação
   já comprovada no serviço online.
5. **Conferir owners e ACL antes de carregar.** Manter os owners privilegiados
   necessários às funções da aplicação. Comparar os defaults do novo projeto e
   revogar apenas concessões excedentes nos objetos da aplicação; depois aplicar
   seus grants revisados. Não usar `--no-owner`, `--no-acl` ou concessões amplas
   para esconder diferenças. Os objetos gerenciados ficam sob administração do
   destino; sua identidade global não precisa reproduzir OIDs do cluster antigo.
6. **Importar em uma sessão transacional**, com `ON_ERROR_STOP`, somente após
   revisar os arquivos de trabalho. O guia oficial usa `session_replication_role=replica`
   durante os dados. Confirmar essa permissão no destino, retornar a `origin`
   antes das provas e evitar que a carga de auth.users gere perfis duplicados.
   Instalar as customizações de trigger após a carga quando aplicável. Se owners,
   event triggers ou DDL protegido forem recusados, parar e revisar com o provedor;
   não executar a elevação de SUPERUSER usada apenas no clone local.
7. **Aceitar o destino somente após validar** dados da aplicação, vínculos Auth,
   FKs, sequências, funções, RLS e privilégios efetivos. Referências do snapshot:
   cliente 12, animal 11, adoção 2, questionário 7, Auth users/identities 4/4.
   Os 45 COPYs/417 registros são inventário do arquivo: a contagem global de um
   projeto novo pode diferir por seus componentes gerenciados. Somente depois de
   testar os serviços do destino propor mudança de URL/chave no aplicativo.

Este backup é **anterior às migrações 12/15/10**. O destino recuperado precisa de
uma versão de banco compatível com o Flutter antes de receber tráfego: reaplicar
somente migrações/correções especificamente autorizadas ou usar cliente compatível.
Não exigir 20/20 do SQL 16 em um snapshot que ainda não recebeu essas migrações.

Não usar limpeza global, reset, DROP de schemas gerenciados ou sobrescrita da
produção como parte desse procedimento. Toda futura ação online exige autorização.

## Configurações fora da recuperação SQL

O Supabase relaciona Auth/API, Edge, Storage, Realtime e ajustes da instância entre
os itens que exigem configuração separada em outro projeto.
[Escopo da recuperação de projeto](https://supabase.com/docs/guides/platform/clone-project).

| Componente | Evidência já registrada | Preparação do destino |
| --- | --- | --- |
| Auth | E-mail habilitado, cadastro permitido, confirmação automática; cópia privada de SMTP/OAuth não demonstrada | Conferir Site URL, redirects de login/recuperação, política de confirmação, templates, SMTP, provedores e controles de acesso. Preservar contas e hashes; prever nova autenticação |
| Chaves e conexão | roles.sql não guarda senhas | Usar credenciais e chaves do projeto novo. Flutter recebe apenas URL e chave pública; credenciais administrativas permanecem privadas |
| Edge Functions | Último inventário salvo: zero instaladas | Não há função online comprovada a copiar. O código local excluir-conta/SQL 20 é escopo separado; não ativá-lo como parte das migrações atuais |
| Secrets de Edge | Código local lê ACCOUNT_CLEANUP_SECRET e variáveis de plataforma | Caso a função seja autorizada futuramente, configurar o secret próprio no destino e usar as variáveis gerenciadas do projeto novo; não copiar chaves administrativas da origem |
| Storage | Zero buckets e objetos no snapshot | Nenhum arquivo Storage pendente nessa cópia; se houver conteúdo posterior, copiar os arquivos e conferir políticas/configuração separadamente |
| Imagens externas | Onze referências de animais, fora do Storage | O dump guarda URLs, não os arquivos; acesso às imagens não foi certificado por essa cópia |
| Realtime e extensões | Publicação e extensões no dump | Conferir publicação, parâmetros e extensões do destino. Não ativar jobs/webhooks externos sem revisão |

Secrets de Edge são configurados separadamente no Dashboard/CLI; os nomes
SUPABASE_ são fornecidos pela plataforma. O valor de ACCOUNT_CLEANUP_SECRET não
foi consultado nem guardado nesta revisão.
[Documentação de secrets](https://supabase.com/docs/guides/functions/secrets).

A extensão Vault está presente, mas o snapshot tem **zero vault.secrets**. Não
há motivo comprovado para copiar chave raiz nesta recuperação. Se for identificada
criptografia de colunas ou uso posterior de Vault/pgsodium, a chave raiz não está
no dump e requer o procedimento oficial privado, autorizado somente para o novo
destino. Não sobrescrever a chave de um projeto que já contenha dados cifrados.

## Permissões que ainda precisam de prova no destino gerenciado

- Operador e conexão administrativa ao novo projeto não foram verificados.
- A lista TOC final, os conflitos de DDL gerenciado, a carga Auth e a permissão
  de `session_replication_role` ainda não foram ensaiados nesse destino.
- A equivalência das ACLs de aplicação diante dos defaults reais do projeto novo
  ainda não foi demonstrada. A restauração local não elimina essa conferência.
- O Supabase oferece gestão de event triggers ao `postgres` por Supautils.
  Portanto, o erro de SUPERUSER do cluster local não prova impedimento online;
  ainda falta conferir os objetos e owners permitidos no projeto novo.
  [Documentação de event triggers](https://supabase.com/docs/guides/database/postgres/event-triggers).
- Auth/SMTP/redirects/secrets e recuperação operacional completa continuam sem
  custódia/teste comprovados. Não há tempo de recuperação ou RPO zero certificados.

## Se SQL 12, 15 ou 10 falhar

| Momento da falha | Ação segura |
| --- | --- |
| SQL 12 antes do COMMIT | Interromper; confirmar rollback da transação; revisar a causa antes de prosseguir |
| SQL 15 antes do COMMIT | SQL 12 já pode estar confirmado; preservar esse estado e revisar somente a etapa 15 |
| SQL 10 antes do COMMIT | SQL 12/15 permanecem; confirmar rollback do 10 e investigar o preflight/lock. Não reaplicar por tentativa |
| Conexão caiu ou COMMIT incerto | Inspecionar catálogo, índices, funções e transação antes de qualquer repetição |
| Problema após COMMIT | Suspender etapas seguintes, limitar novas gravações e guardar evidências sanitizadas; preparar correção pontual revisada |

SQL 16 apenas verifica; não desfaz nada. Preferir corrigir os objetos específicos
preservando pedidos e histórico. Se necessária recuperação integral, usar o novo
projeto previsto acima, reconciliar gravações posteriores ao snapshot e exigir
aprovação do corte. Não importar dados antigos sobre a produção para reverter DDL.

## Pendências reais e autorização

**Pode-se solicitar autorização condicionada; não se pode declarar recuperação
gerenciada completa já comprovada.** Antes de executar, confirmar operador/destino,
permissões, custódia privada das configurações, atualidade do backup e janela sem
gravações concorrentes. Contagens iguais não excluem alterações no conteúdo.

Permanecem também a regularização verificada dos responsáveis dos nove animais
sem Auth e o teste visual Flutter Web com duas contas. Essas pendências não são
falhas das migrações locais e não autorizam criar vínculos ou reativar usuários.
Os testes aprovados não foram repetidos. Nenhum arquivo SQL, backup ou código
Flutter foi alterado; somente o plano e sua referência no checklist foram preparados.
