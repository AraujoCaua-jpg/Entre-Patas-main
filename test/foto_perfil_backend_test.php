<?php
$base = getenv('API_BASE_URL') ?: 'http://localhost/entrepatas-api';
$pasta = getenv('PHOTO_STORAGE_DIR') ?: dirname(__DIR__).'/backend/uploads/perfis';
$pdo = new PDO('mysql:host=localhost;dbname=entrepatas;charset=utf8mb4', getenv('DB_USER') ?: 'root', getenv('DB_PASSWORD') ?: '', [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
function conferir($ok, $mensagem) { if (!$ok) throw new RuntimeException($mensagem); }
function cadastrar($dados, $rota='cadastrar_cliente.php', $token=null) {
    global $base;
    $contexto = stream_context_create(['http'=>['method'=>'POST', 'header'=>"Content-Type: application/json\r\n".($token ? "Authorization: Bearer $token\r\n" : ''), 'content'=>json_encode($dados), 'ignore_errors'=>true]]);
    $corpo = file_get_contents($base.'/'.$rota, false, $contexto);
    preg_match('/\s(\d{3})\s/', $http_response_header[0], $m);
    return [(int)$m[1], json_decode($corpo, true, 512, JSON_THROW_ON_ERROR)];
}
$s = bin2hex(random_bytes(6));
$dados = ['nome'=>'Foto', 'sobrenome'=>'Teste', 'email'=>"foto$s@example.com", 'usuario'=>"foto$s", 'telefone'=>'11'.random_int(100000000,999999999), 'cidadeDeResidencia'=>'São Paulo', 'estado'=>'SP', 'larDeAdocao'=>false, 'senha'=>'SenhaTeste!123'];
$png = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aMrsAAAAASUVORK5CYII=';
$arquivo = null;
$id = null;
$arquivos = [];
$token = null;
try {
    foreach (['invalido', base64_encode('<svg xmlns="http://www.w3.org/2000/svg"/>'), base64_encode(str_repeat('a', 3*1024*1024+1)), ['arquivo']] as $invalida) {
        [$status] = cadastrar([...$dados, 'fotoBase64'=>$invalida]);
        conferir($status===400, 'Foto inválida foi aceita');
    }
    [$status,$resposta] = cadastrar([...$dados, 'fotoBase64'=>$png]);
    conferir($status===201, 'Cadastro com foto falhou: '.json_encode($resposta));
    $id = $resposta['id'];
    $url = $resposta['imagem'];
    parse_str(parse_url($url, PHP_URL_QUERY), $query);
    $arquivo = $pasta.'/'.$query['arquivo'];
    $arquivos[] = $arquivo;
    conferir(file_get_contents($url)===base64_decode($png), 'Imagem salva não foi exibida corretamente');
    $q=$pdo->prepare('SELECT imagem FROM cliente WHERE id=?'); $q->execute([$id]);
    conferir($q->fetchColumn()===$url, 'URL não persistiu no perfil');
    $antes = count(glob($pasta.'/*') ?: []);
    [$status] = cadastrar([...$dados, 'fotoBase64'=>$png]);
    conferir($status===409, 'Duplicidade não foi rejeitada');
    conferir(count(glob($pasta.'/*') ?: [])===$antes, 'Cadastro duplicado deixou foto órfã');
    [$status,$sessao] = cadastrar(['email'=>$dados['email'],'senha'=>$dados['senha']], 'login.php');
    conferir($status===200, 'Login para editar foto falhou');
    $token = $sessao['token'];
    $edicao = [...$dados, 'imagem'=>$url];
    [$status] = cadastrar([...$edicao,'fotoBase64'=>$png], 'clientes.php?acao=editar');
    conferir($status===401, 'Upload de perfil sem sessão foi aceito');
    [$status,$r] = cadastrar($edicao, 'clientes.php?acao=editar', $token);
    conferir($status===200 && $r['cliente']['imagem']===$url, 'Editar dados apagou foto atual');
    [$status] = cadastrar([...$edicao,'fotoBase64'=>'invalido'], 'clientes.php?acao=editar', $token);
    conferir($status===400, 'Foto inválida foi aceita na edição');
    [$status,$r] = cadastrar([...$edicao,'fotoBase64'=>$png], 'clientes.php?acao=editar', $token);
    conferir($status===200, 'Trocar foto falhou');
    $novaUrl=$r['cliente']['imagem'];
    parse_str(parse_url($novaUrl, PHP_URL_QUERY), $query);
    $arquivos[]=$pasta.'/'.$query['arquivo'];
    conferir($novaUrl!==$url && file_get_contents($novaUrl)===base64_decode($png), 'Nova foto não foi persistida');
    [$status,$r] = cadastrar([...$edicao,'imagem'=>null], 'clientes.php?acao=editar', $token);
    conferir($status===200 && $r['cliente']['imagem']===null, 'Remover foto falhou');
    $contexto = stream_context_create(['http'=>['ignore_errors'=>true]]);
    file_get_contents($base.'/foto_perfil.php?arquivo=../cadastrar_cliente.php', false, $contexto);
    conferir(str_contains($http_response_header[0], '404'), 'Endpoint aceitou caminho inválido');
    echo "OK: upload, validação, limite, exibição, persistência e limpeza de cadastro duplicado.\n";
} finally {
    if ($token !== null) cadastrar([], 'logout.php', $token);
    if ($id !== null) $pdo->prepare('DELETE FROM cliente WHERE id=?')->execute([$id]);
    foreach ($arquivos as $arquivo) if (is_file($arquivo)) unlink($arquivo);
}
