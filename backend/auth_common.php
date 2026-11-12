<?php
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
$origem = $_SERVER['HTTP_ORIGIN'] ?? '';
if (preg_match('~^http://(localhost|127\.0\.0\.1)(:\d+)?$~', $origem)) {
    header("Access-Control-Allow-Origin: $origem");
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function resposta($status, $dados) {
    http_response_code($status);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    exit;
}

function banco() {
    return new PDO(
        'mysql:host=localhost;dbname=entrepatas;charset=utf8mb4',
        getenv('DB_USER') ?: 'root',
        getenv('DB_PASSWORD') ?: '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
         PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
         PDO::ATTR_EMULATE_PREPARES => false]
    );
}

function cliente_publico($cliente) {
    unset($cliente['senha']);
    $cliente['id'] = (int) $cliente['id'];
    $cliente['larDeAdocao'] = (bool) $cliente['larDeAdocao'];
    $cliente['ativo'] = (bool) $cliente['ativo'];
    return $cliente;
}

function iniciar_sessao() {
    // O identificador é transportado no cabeçalho Authorization, nunca na URL.
    if (!session_start([
        'use_cookies' => 0,
        'use_only_cookies' => 0,
        'use_strict_mode' => 1,
        'use_trans_sid' => 0,
        'gc_maxlifetime' => 3600,
    ])) {
        throw new RuntimeException('Não foi possível iniciar a sessão.');
    }
}

function exigir_sessao() {
    $headers = function_exists('getallheaders') ? array_change_key_case(getallheaders()) : [];
    $cabecalho = $_SERVER['HTTP_AUTHORIZATION']
        ?? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? $headers['authorization'] ?? '';
    if (!preg_match('/^Bearer ([a-zA-Z0-9,-]{22,128})$/D', $cabecalho, $resultado)) {
        resposta(401, ['erro' => 'Entre novamente para continuar.']);
    }
    session_id($resultado[1]);
    iniciar_sessao();
    if (empty($_SESSION['cliente_id']) || ($_SESSION['expira'] ?? 0) <= time()) {
        $_SESSION = [];
        session_destroy();
        resposta(401, ['erro' => 'Sua sessão expirou. Entre novamente.']);
    }
    $consulta = banco()->prepare('SELECT * FROM cliente WHERE id = ? AND ativo = 1');
    $consulta->execute([$_SESSION['cliente_id']]);
    $cliente = $consulta->fetch();
    if (!$cliente) {
        $_SESSION = [];
        session_destroy();
        resposta(401, ['erro' => 'Entre novamente para continuar.']);
    }
    return $cliente;
}
