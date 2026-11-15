<?php
require_once __DIR__ . '/validacao_cliente.php';
require_once __DIR__ . '/foto_perfil_storage.php';
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

$corpo = file_get_contents('php://input', false, null, 0, 5 * 1024 * 1024 + 1);
if (strlen($corpo) > 5 * 1024 * 1024) responder(413, ['erro'=>'O cadastro excedeu o limite. Escolha uma foto de até 3 MB.']);
$dados = json_decode($corpo, true);

if (!is_array($dados)) {
    responder(400, ['erro' => 'Dados inválidos.']);
}

try {
    $dados = validar_cliente($dados);
    $foto = isset($dados['fotoBase64']) ? validar_foto_perfil($dados['fotoBase64']) : null;
} catch (InvalidArgumentException $erro) {
    responder(400, ['erro'=>$erro->getMessage()]);
}
if (!senha_valida($dados['senha'] ?? null)) {
    responder(400, ['erro'=>'Use ao menos 8 caracteres, até 72 bytes, com maiúscula, minúscula, número e símbolo.']);
}
$email = $dados['email'];
$telefone = $dados['telefone'];
$arquivoFoto = null;
try {
    $host = getenv('DB_HOST') ?: 'localhost';
    $nome = getenv('DB_NAME') ?: 'entrepatas';
    $pdo = new PDO(
        "mysql:host=$host;dbname=$nome;charset=utf8mb4",
        getenv('DB_USER') ?: 'root',
        getenv('DB_PASSWORD') === false ? '' : getenv('DB_PASSWORD'),
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_EMULATE_PREPARES => false
        ]
    );

    if ($foto !== null) {
        [$arquivoFoto, $nomeFoto] = salvar_foto_perfil($foto);
        $dados['imagem'] = url_foto_perfil($nomeFoto);
    }
    $consulta = $pdo->prepare(
        'INSERT INTO cliente
        (nome, sobrenome, email, telefone, senha, usuario, larDeAdocao, ativo, estado, cidadeDeResidencia, endereco, imagem, questionario_pendente)
        VALUES
        (:nome, :sobrenome, :email, :telefone, :senha, :usuario, :larDeAdocao, 1, :estado, :cidade, :endereco, :imagem, 1)'
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
        'id' => (int) $pdo->lastInsertId(),
        'imagem' => $dados['imagem'] ?? null
    ]);
} catch (PDOException $erro) {
    if ($arquivoFoto !== null) @unlink($arquivoFoto);
    if (($erro->errorInfo[1] ?? null) === 1062) {
        responder(409, [
            'erro' => 'E-mail, telefone ou usuário já cadastrado.'
        ]);
    }

    error_log($erro->getMessage());
    responder(500, ['erro' => 'Não foi possível cadastrar o cliente.']);
} catch (Throwable $erro) {
    if ($arquivoFoto !== null) @unlink($arquivoFoto);
    error_log($erro->getMessage());
    responder(500, ['erro' => 'Não foi possível salvar a foto e concluir o cadastro.']);
}
