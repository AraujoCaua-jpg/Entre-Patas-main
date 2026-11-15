[CmdletBinding()]
param(
  [string]$BackupRoot = (Join-Path $env:USERPROFILE 'EntrePatas-Backups'),
  [switch]$CheckOnly
)

# Não cria credenciais, papéis, migrações ou conexões pelo Supabase CLI.
# Exige ferramentas PostgreSQL e PGPASSFILE preexistentes, fora do repositório.
# Nenhum comando de restauração ou limpeza está incluído neste script.
$ErrorActionPreference = 'Stop'
$projectRef = 'cyaxnaflvnjnpryryorr'
$workspaceRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent)).TrimEnd('\', '/')

function Test-InWorkspace([string]$Target) {
  $absoluteTarget = [IO.Path]::GetFullPath($Target)
  return $absoluteTarget.Equals($workspaceRoot, [StringComparison]::OrdinalIgnoreCase) -or
    $absoluteTarget.StartsWith($workspaceRoot + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase)
}

function Assert-NoReparsePoint([string]$Target) {
  # GetFullPath normaliza o texto, mas não resolve links. Conferir também cada
  # ancestral existente impede uma pasta externa de redirecionar para o repo.
  $ancestor = [IO.Path]::GetFullPath($Target)
  while ($ancestor) {
    if (Test-Path -LiteralPath $ancestor) {
      $entry = Get-Item -LiteralPath $ancestor -Force -ErrorAction Stop
      if (($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw 'Caminho de backup ou credencial contém link/reparse point. Use um caminho local direto fora do repositório.'
      }
    }
    $ancestor = [IO.Path]::GetDirectoryName($ancestor)
  }
}

function Invoke-PgCommand([string]$Program, [string[]]$CommandArguments) {
  # Não imprime stderr: erros do servidor podem conter detalhes confidenciais.
  $savedPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $resultText = (& $Program @CommandArguments 2>&1 | Out-String)
    $resultExit = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $savedPreference
  }
  if ($resultExit -ne 0) {
    throw 'Uma ferramenta PostgreSQL falhou. O arquivo parcial não foi validado; revisar em ambiente privado.'
  }
  return $resultText
}

$runDirectory = $null
$manifest = $null
$oldPgOptions = $env:PGOPTIONS
$oldPgAppName = $env:PGAPPNAME
try {
  # Primeiro validar tudo localmente. Falhas aqui não abrem conexão nem criam pasta.
  foreach ($overrideName in @('PGSERVICE', 'PGSERVICEFILE', 'PGHOSTADDR')) {
    if ([Environment]::GetEnvironmentVariable($overrideName, 'Process')) {
      throw 'Remova PGSERVICE, PGSERVICEFILE e PGHOSTADDR deste processo; essas configurações podem substituir o destino validado.'
    }
  }
  if (-not $env:PGPASSFILE -or -not (Test-Path -LiteralPath $env:PGPASSFILE -PathType Leaf)) {
    throw 'PGPASSFILE preexistente não configurado. Não enviar senha no chat ou em argumentos.'
  }
  if (Test-InWorkspace $env:PGPASSFILE) {
    throw 'PGPASSFILE precisa ficar fora do repositório, com acesso local restrito.'
  }
  Assert-NoReparsePoint $env:PGPASSFILE
  if ($env:PGPASSWORD) {
    throw 'Use PGPASSFILE; remova PGPASSWORD deste processo sem alterar a senha do banco.'
  }
  if (Test-InWorkspace $BackupRoot) {
    throw 'O destino do backup precisa ficar fora do repositório.'
  }
  Assert-NoReparsePoint $BackupRoot
  $hostName = ([string]$env:PGHOST).TrimEnd('.').ToLowerInvariant()
  $directHost = $hostName -eq ('db.' + $projectRef + '.supabase.co')
  $sessionPooler = $hostName -match '^[a-z0-9.-]+\.pooler\.supabase\.com$' -and
    ([string]$env:PGUSER).EndsWith('.' + $projectRef, [StringComparison]::OrdinalIgnoreCase)
  if (-not ($directHost -or $sessionPooler) -or $env:PGPORT -ne '5432' -or
      $env:PGDATABASE -ne 'postgres' -or -not $env:PGUSER) {
    throw 'Configurar explicitamente PGHOST/PGPORT/PGDATABASE/PGUSER para o projeto esperado, conexão direta ou pooler de sessão.'
  }
  if ($env:PGSSLMODE -ne 'verify-full') {
    throw 'PGSSLMODE deve ser verify-full, com certificado confiável configurado no libpq.'
  }
  $programs = @{}
  foreach ($program in @('psql', 'pg_dump', 'pg_dumpall', 'pg_restore')) {
    $found = Get-Command $program -CommandType Application -ErrorAction SilentlyContinue
    if (-not $found) { throw 'Instalar ferramentas PostgreSQL compatíveis antes de executar o backup.' }
    $programs[$program] = $found.Source
  }
  if ($CheckOnly) {
    Write-Output 'Pré-requisitos locais presentes. Nenhuma conexão aberta; TLS, credencial e recuperação ainda não validados.'
    return
  }

  $env:PGOPTIONS = '-c default_transaction_read_only=on'
  $env:PGAPPNAME = 'EntrePatasBackupReadOnly'
  $connectionSql = "select json_build_object('read_only',current_setting('transaction_read_only'),'server_version_num',current_setting('server_version_num'))::text"
  $connectionText = Invoke-PgCommand $programs['psql'] @('-w', '-X', '-v', 'ON_ERROR_STOP=1', '-A', '-t', '-c', $connectionSql)
  $connection = $connectionText.Trim() | ConvertFrom-Json
  if ($connection.read_only -ne 'on') { throw 'A conexão não confirmou transaction_read_only=on.' }
  $serverMajor = [math]::Floor(([int]$connection.server_version_num) / 10000)
  $versionText = Invoke-PgCommand $programs['pg_dump'] @('-w', '--version')
  if ($versionText -notmatch 'PostgreSQL\) (\d+)\.') { throw 'Não foi possível conferir a versão de pg_dump.' }
  if ([int]$Matches[1] -ne $serverMajor) { throw 'Usar pg_dump da mesma versão principal do servidor para este procedimento.' }

  $resolvedBackupRoot = [IO.Path]::GetFullPath($BackupRoot)
  if (-not (Test-Path -LiteralPath $resolvedBackupRoot)) {
    New-Item -ItemType Directory -Path $resolvedBackupRoot -ErrorAction Stop | Out-Null
  }
  $uniqueRunName = 'pre-migracao-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
  $runDirectory = Join-Path $resolvedBackupRoot $uniqueRunName
  New-Item -ItemType Directory -Path $runDirectory -ErrorAction Stop | Out-Null
  $manifest = [ordered]@{
    project_ref = $projectRef
    started_at_utc = [DateTime]::UtcNow.ToString('o')
    status = 'incompleto'
    transaction_read_only = $connection.read_only
    server_version_num = $connection.server_version_num
    restore_test_passed = $false
    storage_files_included = $false
    external_config_included = $false
  }
  $partial = Join-Path $runDirectory 'database.dump.partial'
  $complete = Join-Path $runDirectory 'database.dump'
  foreach ($target in @($partial, $complete, (Join-Path $runDirectory 'roles.sql'))) {
    if (Test-Path -LiteralPath $target) { throw 'Destino já existe. Nenhum backup será sobrescrito.' }
  }
  # --create inclui propriedades do banco no arquivo; não cria banco no servidor.
  Invoke-PgCommand $programs['pg_dump'] @('-w', '--format=custom', '--create', '--file', $partial) | Out-Null
  if ((Get-Item -LiteralPath $partial).Length -eq 0) { throw 'Arquivo de backup vazio.' }
  Invoke-PgCommand $programs['pg_dumpall'] @('-w', '--roles-only', '--no-role-passwords', '--file', (Join-Path $runDirectory 'roles.sql')) | Out-Null
  $contents = Invoke-PgCommand $programs['pg_restore'] @('-w', '--list', $partial)
  [IO.File]::WriteAllText((Join-Path $runDirectory 'contents.txt'), $contents, [Text.UTF8Encoding]::new($false))
  # Movimento apenas do arquivo novo dentro desta pasta, sem substituição/recursão.
  if (-not ([IO.Path]::GetFullPath($complete)).StartsWith($runDirectory + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase)) { throw 'Destino final inválido.' }
  Move-Item -LiteralPath $partial -Destination $complete -ErrorAction Stop
  $manifest.status = 'capturado_restauracao_pendente'
  $manifest.completed_at_utc = [DateTime]::UtcNow.ToString('o')
  $manifest.bytes = (Get-Item -LiteralPath $complete).Length
  $manifest.sha256 = (Get-FileHash -LiteralPath $complete -Algorithm SHA256).Hash
  Write-Output 'Backup capturado em nova pasta externa. Recuperação NÃO validada; restauração isolada obrigatória antes das migrações.'
} catch {
  if ($manifest) { $manifest.status = 'falhou_na_captura' }
  # Somente mensagens locais fixas do script; não reproduzir saída bruta do servidor.
  if ($_.Exception.Message -match '^(PGPASSFILE|O destino|PGSSLMODE|Configurar explicitamente|Instalar ferramentas|Use PGPASSFILE|Usar pg_dump|Uma ferramenta|Arquivo de backup|A conexão|Destino |Não foi possível|Remova PGSERVICE|Caminho de backup ou credencial)') {
    Write-Error $_.Exception.Message -ErrorAction Continue
  } else {
    Write-Error 'Captura interrompida. Revisar pré-requisitos e os arquivos parciais em ambiente privado; nenhum backup foi validado.' -ErrorAction Continue
  }
  exit 1
} finally {
  $env:PGOPTIONS = $oldPgOptions
  $env:PGAPPNAME = $oldPgAppName
  if ($manifest -and $runDirectory) {
    [IO.File]::WriteAllText((Join-Path $runDirectory 'manifest.json'), ($manifest | ConvertTo-Json -Depth 4), [Text.UTF8Encoding]::new($false))
  }
}
