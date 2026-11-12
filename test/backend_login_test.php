<?php
// Executar por CLI com Apache e MySQL ativos. Usa uma conta temporária.
$base = getenv('API_BASE_URL') ?: 'http://localhost/entrepatas-api';
$pdo = new PDO('mysql:host=localhost;dbname=entrepatas;charset=utf8mb4',
    getenv('DB_USER') ?: 'root', getenv('DB_PASSWORD') ?: '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
function conferir($condicao, $mensagem) {
    if (!$condicao) throw new RuntimeException($mensagem);
}
function chamar($rota, $dados = null, $token = null) {
    global $base;
    $headers = "Content-Type: application/json\r\nOrigin: http://localhost:50000\r\n";
    if ($token) $headers .= "Authorization: Bearer $token\r\n";
    $context = stream_context_create(['http' => [
        'method' => $dados === null ? 'GET' : 'POST',
        'header' => $headers,
        'content' => $dados === null ? '' : json_encode($dados),
        'ignore_errors' => true, 'timeout' => 20,
    ]]);
    $body = file_get_contents("$base/$rota", false, $context);
    preg_match('/\s(\d{3})\s/', $http_response_header[0] ?? '', $match);
    return [(int) ($match[1] ?? 0), json_decode($body, true)];
}
$id = null;
$token = null;
try {
    $sufixo = bin2hex(random_bytes(6));
    $email = "teste_login_$sufixo@example.com";
    $senha = 'TesteLogin!123';
    $q = $pdo->prepare('INSERT INTO cliente (nome,sobrenome,email,telefone,senha,usuario,ativo,larDeAdocao) VALUES (?,?,?,?,?,?,1,0)');
    $q->execute(['Teste', 'Temporario', $email, null,
        password_hash($senha, PASSWORD_DEFAULT), "teste_$sufixo"]);
    $id = (int) $pdo->lastInsertId();

    [$status] = chamar('login.php', ['email' => $email, 'senha' => 'errada']);
    conferir($status === 401, 'Senha incorreta aceita');
    [$status] = chamar('login.php', ['email' => "ausente_$email", 'senha' => $senha]);
    conferir($status === 401, 'E-mail inexistente aceito');
    [$status] = chamar('login.php', ['email' => $email, 'senha' => []]);
    conferir($status === 400, 'Entrada inválida aceita');

    [$status, $dados] = chamar('login.php', ['email' => $email, 'senha' => $senha]);
    conferir($status === 200 && $dados['cliente']['id'] === $id, 'Login válido falhou');
    conferir(!isset($dados['cliente']['senha']), 'Hash vazou na resposta');
    $token = $dados['token'];
    [$status, $dados] = chamar('sessao.php', null, $token);
    conferir($status === 200 && $dados['cliente']['id'] === $id, 'Sessão não identifica usuário: ' . $status . ' ' . json_encode($dados));
    [$status] = chamar('sessao.php');
    conferir($status === 401, 'Sessão sem token aceita');
    [$status] = chamar('sessao.php', null, str_repeat('a', 32));
    conferir($status === 401, 'Token inválido aceito');
    [$status] = chamar('logout.php', [], $token);
    conferir($status === 200, 'Logout falhou');
    [$status] = chamar('sessao.php', null, $token);
    conferir($status === 401, 'Sessão continua válida após logout');
    $token = null;

    $pdo->prepare('UPDATE cliente SET ativo = 0 WHERE id = ?')->execute([$id]);
    [$status] = chamar('login.php', ['email' => $email, 'senha' => $senha]);
    conferir($status === 401, 'Conta inativa aceita');
    echo "OK: login, senha incorreta, conta inativa, token, logout e validação.\n";
} finally {
    if ($token) chamar('logout.php', [], $token);
    if ($id) $pdo->prepare('DELETE FROM cliente WHERE id = ?')->execute([$id]);
}
