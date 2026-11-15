# Backup e recuperação antes das migrações

> Atualização de 15/11/2026: o backup atualizado `pre-migracao-20261115-014557`
> foi restaurado em PostgreSQL 17 isolado. Dados, papéis, estrutura, ACL e Auth
> passaram; a revisão final das migrações pode avançar. Isso não autoriza instalar
> nada online. Procedimento, erros tratados e limites da recuperação gerenciada:
> [Restauração do backup atualizado](backup_restauracao_atualizado_2026-11-15.md).

## Histórico do primeiro ensaio

A inspeção de 14/11/2026 encontrou exports em `EntrePatas-Backups`, fora do
repositório. Os arquivos são legíveis e os blocos COPY terminam corretamente.
Isso não comprova recuperação completa: os componentes têm horários diferentes,
o export público possui dez animais e o catálogo inspecionado tinha onze.

A consulta oficial retornou zero backups listados e `pitr_enabled=false`.
`walg_enabled=true`, isoladamente, não confirma um ponto recuperável disponível.
Esses eram os resultados da inspeção inicial. O ensaio posterior recuperou os
dados antigos sobre uma base managed local, com divergências de ACL. Essas eram
as pendências do primeiro ensaio; a cópia atual foi validada separadamente no
relatório indicado acima. O histórico não deve ser usado como resultado da cópia nova.

O inventário sanitizado está em `.dart_tool/sql10_backup_inventory.json`; as
evidências da inspeção estão em [revisao_sql10_producao.md](revisao_sql10_producao.md).
Nenhum dump ou registro pessoal deve integrar o GitHub ou o relatório público.

## Preparar uma cópia consistente

O operador deve usar uma conexão PostgreSQL **já autorizada**, com credencial
armazenada em `PGPASSFILE` fora do repositório e acesso local restrito. Não passar
senha na linha de comando, URL registrada, `dart-define`, captura de tela ou chat.
Usar TLS com validação do servidor e cliente `pg_dump` compatível com sua versão.

Não usar `supabase db dump --remote` ou `--dry-run` sem senha preexistente: o
CLI 3.1.0 revisado pode criar um login temporário privilegiado antes do dump.
Management Query read-only permite inspecionar metadados; não substitui o dump.
Não criar papéis, resetar senha ou remover bloqueios de rede para contornar acesso.

Procedimento para uma janela aprovada de backup somente leitura:

1. Confirmar projeto/host, versão PostgreSQL e destino externo ao workspace.
   Definir `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSFILE`, `PGSSLMODE`
   e, quando necessário, `PGSSLROOTCERT` no ambiente privado do operador.
2. Congelar alterações de esquema durante a coleta; não executar migrações em
   paralelo. `pg_dump` obtém um snapshot consistente dos dados do banco.
3. Fazer **um único arquivo custom** do banco completo, sem filtrar `public` ou
   omitir Auth/private. Preservar funções, triggers, policies, grants e sequências.
   Conferir permissões e schemas incluídos; erro ou exclusão inesperada impede
   considerar a cópia completa.
4. Capturar separadamente papéis e memberships necessários à restauração, sem
   senhas de papéis; registrar dependências de versões/extensões e do ambiente
   gerenciado. Não importar papéis gerenciados indiscriminadamente em outro serviço.
5. Registrar horário UTC, versões, escopo, exit codes, tamanho e SHA-256 em
   inventário privado. Restringir acesso e criptografar a cópia em repouso.

Exemplo manual para revisão pelo operador, **não executado contra produção**. Os parâmetros
de conexão e o caminho de `PGPASSFILE` devem estar configurados no ambiente, sem
imprimir seus valores. O destino de cada rodada deve ser uma pasta nova externa:

```powershell
$backupRunDir = Join-Path $HOME ('EntrePatas-Backups/pre-migracao-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $backupRunDir -ErrorAction Stop | Out-Null
$previousPgOptions = $env:PGOPTIONS
try {
  $env:PGOPTIONS = '-c default_transaction_read_only=on'
  psql -X -v ON_ERROR_STOP=1 -Atc "select current_setting('transaction_read_only')"
  if ($LASTEXITCODE -ne 0) { throw 'Não foi possível confirmar a conexão read-only.' }
  # A saída acima deve ser on; não prosseguir se o resultado for diferente.
  pg_dump --format=custom --file (Join-Path $backupRunDir 'database.dump')
  if ($LASTEXITCODE -ne 0) { throw 'Dump incompleto: interromper e revisar.' }
  pg_dumpall --roles-only --no-role-passwords --file (Join-Path $backupRunDir 'roles.sql')
  if ($LASTEXITCODE -ne 0) { throw 'Captura de papéis incompleta: revisar permissões.' }
  pg_restore --list (Join-Path $backupRunDir 'database.dump') > (Join-Path $backupRunDir 'contents.txt')
  if ($LASTEXITCODE -ne 0) { throw 'Arquivo custom não foi reconhecido.' }
  Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $backupRunDir 'database.dump')
} finally {
  $env:PGOPTIONS = $previousPgOptions
}
```

Esse roteiro precisa de ferramentas PostgreSQL e credenciais existentes; não as
instala nem solicita automaticamente. `pg_restore --list` verifica o catálogo do
arquivo, **não demonstra restauração bem-sucedida**. Nenhum comando de restauração
está incluído para evitar apontamento acidental ao projeto online.

## Ensaio de recuperação obrigatório

Usar uma instância **nova e isolada**, sem apontar para produção ou substituir o
Supabase local de QA existente. Conferir explicitamente host/porta e identificação
do ambiente. Preparar versões compatíveis de PostgreSQL, extensões, papéis e
schemas gerenciados. O plano de restauração deve tratar objetos já fornecidos
pelo Supabase local; não improvisar `DROP`, `db reset`, `--clean` ou ignorar erros.

Restaurar com parada no primeiro erro e transação única quando compatível com o
conteúdo. Registrar cada etapa privada e seu exit code. Conferir:

- Tabelas, contagens e integridade dos vínculos, sem publicar registros pessoais.
- Dados Auth e vínculo único `cliente.auth_user_id`; trigger de cadastro existente.
- Schemas public/private, funções, owners, search_path, EXECUTEs, RLS e grants de coluna.
- PK/FKs, índices, identity/sequências e valor seguinte previsto, sem consumir IDs reais.
- Questionário, solicitações antigas e estados dos animais preservados.
- API/Auth locais funcionando com contas fictícias criadas apenas no ambiente isolado.
- Scripts novos e ciclo de adoção aprovados nesse ambiente recuperado.

Um dump do PostgreSQL não é cópia dos arquivos binários do Storage nem dos
secrets, configurações de Auth, domínio, Edge Functions ou serviços externos.
Inventariar e recuperar esses componentes por processo privado separado; não
colocar secrets no repositório. Nos arquivos antigos, `data.sql` já contém Auth:
não aplicar também `auth-data.sql` indiscriminadamente, gerando duplicações.

## Critério para liberar uma recomendação

Somente após novo backup completo, escopo conferido, hashes registrados e ensaio
de recuperação aprovado é possível apresentar a instalação para autorização.
Manter a janela e a cópia imediatamente anteriores à migração. Se houver erro
antes do COMMIT da migração, confirmar rollback. Depois do COMMIT, suspender novas
operações e preservar dados/evidências; elaborar reversão específica ou recuperação
aprovada que considere registros posteriores, sem restaurar por cima da produção
ou descartar dados automaticamente.

O script `scripts/backup_supabase_readonly.ps1` implementa a captura com guardas
adicionais: exige PGPASSFILE externo e preexistente, alvo fixo, TLS verify-full,
modo read-only, ausência de prompts e ferramentas compatíveis. Rejeita caminhos
com links/reparse points e configurações libpq que desviem o destino, e cria
somente uma nova pasta externa. Não cria credenciais nem executa restauração.

```powershell
# Apenas checagem local de pré-requisitos: não conecta nem captura dados.
powershell.exe -NoProfile -File scripts/backup_supabase_readonly.ps1 -CheckOnly

# Somente após configurar uma conexão existente de modo privado:
powershell.exe -NoProfile -File scripts/backup_supabase_readonly.ps1
```

Uma captura bem-sucedida gera manifest com `restore_test_passed=false` até um
ensaio separado. `--create` no pg_dump apenas inclui propriedades do banco no
arquivo; não autoriza restaurá-lo com criação/limpeza em um banco existente.

O ensaio de 15/11 revelou que os grants padrão da base Supabase podem ampliar os
privilégios dos objetos recriados. A preparação da instância isolada e a aplicação
de ACL/default ACL precisam reproduzir a origem; concessões menores do dump não
removem automaticamente concessões extras já herdadas na criação. Comparar
privilégios efetivos de anon/authenticated, colunas e RPCs, não apenas RLS ligada.
Enquanto houver diferenças, não usar essa instância como recuperação aprovada.

Esta documentação preserva o procedimento inicial. A cópia antiga foi restaurada
em ensaio híbrido e não foi aprovada. A validação atual, feita sem seed do QA e
com equivalência de ACL, está no novo relatório; ainda é necessário preparar a
recuperação no provedor e preservar as configurações externas antes da instalação.
