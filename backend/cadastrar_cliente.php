<?php
header('Content-Type: application/json; charset=utf-8');

// Permite o Flutter rodando localmente no navegador.
$origem = $_SERVER['HTTP_ORIGIN'] ?? '';
if (preg_match('~^http://(localhost|127\.0\.0\.1)(:\d+)?$~', $origem)) {
    header("Access-Control-Allow-Origin: $origem");
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function responder($codigo, $dados) {
    http_response_code($codigo);
    echo json_encode($dados, JSON_UNESCAPED_UNICODE);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST, OPTIONS');
    responder(405, ['erro' => 'Envie o cadastro pelo aplicativo.']);
}

$dados = json_decode(file_get_contents('php://input'), true);

if (!is_array($dados)) {
    responder(400, ['erro' => 'Dados inválidos.']);
}

foreach (['nome', 'sobrenome', 'email', 'telefone', 'senha', 'usuario'] as $campo) {
    if (!isset($dados[$campo]) ||
        !is_string($dados[$campo]) ||
        trim($dados[$campo]) === '') {
        responder(400, ['erro' => "Preencha o campo $campo."]);
    }
}

$email = trim($dados['email']);
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    responder(400, ['erro' => 'E-mail inválido.']);
}

if (strlen($dados['senha']) < 8) {
    responder(400, ['erro' => 'A senha deve ter pelo menos 8 caracteres.']);
}

$telefone = preg_replace('/\D/', '', $dados['telefone']);
if (!preg_match('/^\d{10,11}$/', $telefone)) {
    responder(400, ['erro' => 'Informe o telefone com DDD.']);
}

try {
    $pdo = new PDO(
        'mysql:host=localhost;dbname=entrepatas;charset=utf8mb4',
        'root',
        '',
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );

    $consulta = $pdo->prepare(
        'INSERT INTO cliente
        (nome, sobrenome, email, telefone, senha, usuario, larDeAdocao, ativo, estado, cidadeDeResidencia, endereco, imagem)
        VALUES
        (:nome, :sobrenome, :email, :telefone, :senha, :usuario, :larDeAdocao, 1, :estado, :cidade, :endereco, :imagem)'
    );

    $consulta->execute([
        ':nome' => trim($dados['nome']),
        ':sobrenome' => trim($dados['sobrenome']),
        ':email' => $email,
        ':telefone' => $telefone,
        ':senha' => password_hash($dados['senha'], PASSWORD_DEFAULT),
        ':usuario' => trim($dados['usuario']),
        ':larDeAdocao' => ($dados['larDeAdocao'] ?? false) === true ? 1 : 0,
        ':estado' => $dados['estado'] ?? null,
        ':cidade' => $dados['cidadeDeResidencia'] ?? null,
        ':endereco' => $dados['endereco'] ?? null,
        ':imagem' => $dados['imagem'] ?? null
    ]);

    responder(201, [
        'mensagem' => 'Cliente cadastrado com sucesso!',
        'id' => (int) $pdo->lastInsertId()
    ]);
} catch (PDOException $erro) {
    if (($erro->errorInfo[1] ?? null) === 1062) {
        responder(409, [
            'erro' => 'E-mail, telefone ou usuário já cadastrado.'
        ]);
    }

    error_log($erro->getMessage());
    responder(500, ['erro' => 'Não foi possível cadastrar o cliente.']);
}