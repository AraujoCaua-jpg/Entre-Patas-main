<?php
require_once __DIR__ . '/auth_common.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST, OPTIONS');
    resposta(405, ['erro' => 'Método não permitido.']);
}
try {
    exigir_sessao();
    $_SESSION = [];
    session_destroy();
    resposta(200, ['mensagem' => 'Sessão encerrada.']);
} catch (Throwable $erro) {
    error_log($erro->getMessage());
    resposta(500, ['erro' => 'Não foi possível encerrar a sessão.']);
}
