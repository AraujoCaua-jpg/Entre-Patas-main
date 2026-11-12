<?php
require_once __DIR__ . '/auth_common.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST, OPTIONS');
    resposta(405, ['erro' => 'Envie o login pelo aplicativo.']);
}
$dados = json_decode(file_get_contents('php://input'), true);
if (!is_array($dados) || !is_string($dados['email'] ?? null)
    || !is_string($dados['senha'] ?? null)
    || !filter_var(trim($dados['email']), FILTER_VALIDATE_EMAIL)
    || $dados['senha'] === '' || strlen($dados['senha']) > 4096) {
    resposta(400, ['erro' => 'Informe um e-mail válido e sua senha.']);
}
try {
    $consulta = banco()->prepare('SELECT * FROM cliente WHERE email = ? LIMIT 1');
    $consulta->execute([trim($dados['email'])]);
    $cliente = $consulta->fetch();
    // O mesmo erro é usado para e-mail inexistente, senha errada e conta inativa.
    $hash = $cliente['senha'] ?? '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.';
    $correta = password_verify($dados['senha'], $hash);
    if (!$cliente || !$correta || (int) $cliente['ativo'] !== 1) {
        resposta(401, ['erro' => 'E-mail ou senha incorretos, ou conta indisponível.']);
    }
    iniciar_sessao();
    if (!session_regenerate_id(true)) {
        throw new RuntimeException('Falha ao renovar sessão.');
    }
    $_SESSION = ['cliente_id' => (int) $cliente['id'], 'expira' => time() + 3600, 'senha_versao' => hash('sha256', $cliente['senha'])];
    $token = session_id();
    session_write_close();
    resposta(200, ['cliente' => cliente_publico($cliente), 'token' => $token]);
} catch (Throwable $erro) {
    error_log($erro->getMessage());
    resposta(500, ['erro' => 'Não foi possível entrar. Tente novamente.']);
}
