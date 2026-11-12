<?php
require_once __DIR__ . '/auth_common.php';
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    header('Allow: GET, OPTIONS');
    resposta(405, ['erro' => 'Método não permitido.']);
}
try {
    $cliente = exigir_sessao();
    session_write_close();
    resposta(200, ['cliente' => cliente_publico($cliente)]);
} catch (Throwable $erro) {
    error_log($erro->getMessage());
    resposta(500, ['erro' => 'Não foi possível verificar sua sessão.']);
}
