$ErrorActionPreference = 'Stop'

$xamppPath = 'C:\xampp'
$phpIniPath = Join-Path $xamppPath 'php\php.ini'
$sendmailIniPath = Join-Path $xamppPath 'sendmail\sendmail.ini'
$apacheRulesPath = Join-Path $xamppPath 'htdocs\entrepatas-api\.htaccess'

foreach ($configPath in @($phpIniPath, $sendmailIniPath)) {
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "Arquivo nao encontrado: $configPath"
    }
}
if (-not (Test-Path -LiteralPath (Split-Path $apacheRulesPath))) {
    throw 'A pasta entrepatas-api nao foi encontrada no XAMPP.'
}

$gmailAddress = (Read-Host 'Digite seu Gmail remetente').Trim()
if ($gmailAddress -notmatch '^[a-zA-Z0-9._%+-]+@gmail\.com$') {
    throw 'Informe seu endereco completo terminado em @gmail.com.'
}
$appSecret = Read-Host 'Cole a senha de app do Google (ela ficara oculta)' -AsSecureString
$secretPointer = [IntPtr]::Zero
$plainSecret = $null
try {
    $secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($appSecret)
    $plainSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer) -replace '\s', ''
    if ($plainSecret -notmatch '^[a-zA-Z]{16}$') {
        throw 'A senha de app deve conter as 16 letras fornecidas pelo Google. Nao use a senha normal da conta.'
    }

    function Set-IniValue([string]$contents, [string]$key, [string]$value) {
        $pattern = '(?m)^[ \t]*' + [regex]::Escape($key) + '[ \t]*=.*$'
        $line = "$key=$value"
        if ([regex]::IsMatch($contents, $pattern)) {
            return [regex]::Replace($contents, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $line })
        }
        return $contents + "`r`n$line`r`n"
    }

    $sendmailConfig = [IO.File]::ReadAllText($sendmailIniPath)
    foreach ($setting in @(
        @('smtp_server','smtp.gmail.com'),
        @('smtp_port','587'),
        @('smtp_ssl','tls'),
        @('auth_username',$gmailAddress),
        @('auth_password',$plainSecret),
        @('force_sender',$gmailAddress),
        @('debug_logfile','')
    )) {
        $sendmailConfig = Set-IniValue $sendmailConfig $setting[0] $setting[1]
    }

    $phpConfig = [IO.File]::ReadAllText($phpIniPath)
    $sendmailLine = 'sendmail_path = "\"C:\xampp\sendmail\sendmail.exe\" -t"'
    $pattern = '(?m)^[; \t]*sendmail_path[ \t]*=.*$'
    if (-not [regex]::IsMatch($phpConfig, $pattern)) {
        throw 'Diretiva sendmail_path nao encontrada no php.ini. Nenhuma configuracao foi gravada.'
    }
    $phpConfig = [regex]::Replace($phpConfig, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $sendmailLine })

    $apacheRules = if (Test-Path -LiteralPath $apacheRulesPath) { [IO.File]::ReadAllText($apacheRulesPath) } else { '' }
    $apacheRules = [regex]::Replace($apacheRules, '(?m)^SetEnv RECOVERY_(MAIL_ENABLED|FROM)[ \t]+.*\r?\n?', '')
    $apacheRules += "`r`nSetEnv RECOVERY_MAIL_ENABLED 1`r`nSetEnv RECOVERY_FROM $gmailAddress`r`n"

    $backupTag = Get-Date -Format 'yyyyMMdd-HHmmss'
    foreach ($configPath in @($phpIniPath, $sendmailIniPath, $apacheRulesPath)) {
        if (Test-Path -LiteralPath $configPath) {
            Copy-Item -LiteralPath $configPath -Destination "$configPath.backup-$backupTag"
        }
    }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($sendmailIniPath, $sendmailConfig, $encoding)
    [IO.File]::WriteAllText($phpIniPath, $phpConfig, $encoding)
    [IO.File]::WriteAllText($apacheRulesPath, $apacheRules, $encoding)
    Write-Host 'Configuracao salva somente no XAMPP. Nenhuma senha foi colocada no projeto.'
    Write-Host 'No painel do XAMPP: pare e inicie o Apache. Depois teste Esqueci minha senha no aplicativo.'
    Write-Host 'O destinatario precisa ser um email real de uma conta ativa no banco. Confira tambem a pasta Spam.'
} finally {
    if ($secretPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
    }
    $plainSecret = $null
    $sendmailConfig = $null
    if ($appSecret) { $appSecret.Dispose() }
}
