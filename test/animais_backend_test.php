<?php
$base = getenv('API_BASE_URL') ?: 'http://127.0.0.1:8091';
$pdo = new PDO('mysql:host=localhost;dbname=entrepatas;charset=utf8mb4', getenv('DB_USER') ?: 'root', getenv('DB_PASSWORD') ?: '', [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
function check($ok, $msg) { if (!$ok) throw new RuntimeException($msg); }
function api($route, $data=null, $token=null) {
    global $base;
    $headers = "Content-Type: application/json\r\n";
    if ($token) $headers .= "Authorization: Bearer $token\r\n";
    $ctx = stream_context_create(['http'=>['method'=>$data===null?'GET':'POST','header'=>$headers,'content'=>$data===null?'':json_encode($data),'ignore_errors'=>true,'timeout'=>15]]);
    $body = file_get_contents("$base/$route", false, $ctx);
    preg_match('/\s(\d{3})\s/', $http_response_header[0] ?? '', $m);
    $json = json_decode($body, true);
    check(is_array($json), "Resposta inválida: $route $body");
    return [(int)($m[1] ?? 0), $json];
}
$ids=[]; $animais=[]; $tokens=[];
try {
    $s=bin2hex(random_bytes(5));
    foreach (['a','b'] as $k) {
        $email="$k$s@example.com";
        $q=$pdo->prepare('INSERT INTO cliente (nome,sobrenome,email,senha,usuario,ativo,larDeAdocao,estado,cidadeDeResidencia) VALUES (?,?,?,?,?,1,0,?,?)');
        $q->execute(['Teste','Animal',$email,password_hash('TesteAnimal!123', PASSWORD_DEFAULT),"u$k$s",$k==='a'?'SP':'RJ',"Cidade$k$s"]);
        $ids[$k]=(int)$pdo->lastInsertId();
        [$status,$d]=api('login.php',['email'=>$email,'senha'=>'TesteAnimal!123']);
        check($status===200,'Login falhou'); $tokens[$k]=$d['token'];
    }
    [$status]=api('animais.php'); check($status===401,'Consulta sem sessão aceita');
    $dados=['nome'=>"Pet$s",'idade'=>0,'imagem'=>null,'tipo'=>'Gato','descricao'=>'Animal de teste','sexo'=>'Fêmea','status'=>'Disponível','energia'=>'Médio','porte'=>'Pequeno','convivencia'=>'Sim','carencia'=>'Não','id_cliente'=>$ids['b']];
    [$status,$d]=api('animais.php?acao=cadastrar',$dados,$tokens['a']);
    check($status===200,'Cadastro falhou: '.json_encode($d));
    $id=$d['animal']['id']; $animais[]=$id;
    check($d['animal']['id_cliente']===$ids['a'],'Responsável do corpo foi aceito');
    check($d['animal']['idade']===0 && $d['animal']['estado']==='SP','Idade ou região incorreta');
    [$status,$d]=api("animais.php?acao=id&id=$id",null,$tokens['b']); check($status===200 && $d['animal']['nome']===$dados['nome'],'Busca por ID falhou');
    foreach (['editar','apagar'] as $acao) {
        [$status]=api("animais.php?acao=$acao&id=$id",$dados,$tokens['b']); check($status===403,'Outro usuário alterou animal');
    }
    [$status]=api('animais.php?acao=cadastrar',[...$dados,'idade'=>-1],$tokens['a']); check($status===400,'Idade negativa aceita');
    [$status]=api('animais.php?acao=cadastrar',[...$dados,'imagem'=>'javascript:alert(1)'],$tokens['a']); check($status===400,'Imagem inválida aceita');
    foreach (["q=Pet$s",'id_cliente='.$ids['a'],'estado=SP&porte=Pequeno&tipo=Gato&energia=M%C3%A9dio&sexo=F%C3%AAmea&convivencia=Sim&carencia=N%C3%A3o&cidade='.urlencode("Cidadea$s")] as $filtro) {
        [$status,$d]=api("animais.php?$filtro",null,$tokens['a']);
        check($status===200 && in_array($id,array_column($d['animais'],'id')),'Filtro falhou: '.$filtro);
        foreach ($d['animais'] as $a) check(!isset($a['email']) && !isset($a['endereco']) && !isset($a['senha']),'Dados privados vazaram');
    }
    [$status,$d]=api('animais.php?id_cliente='.$ids['b'],null,$tokens['a']); check($status===200 && $d['animais']===[],'Filtro por responsável incorreto');
    [$status,$d]=api('animais.php?q=%25&id_cliente='.$ids['a'],null,$tokens['a']); check($d['animais']===[],'Curinga não escapado');
    [$status]=api('animais.php?pagina=0',null,$tokens['a']); check($status===400,'Página inválida aceita');
    $dados['nome']="Editado$s"; $dados['idade']=3;
    [$status,$d]=api("animais.php?acao=editar&id=$id",$dados,$tokens['a']); check($status===200 && $d['animal']['nome']===$dados['nome'],'Edição falhou');
    [$status,$d]=api("animais.php?acao=id&id=$id",null,$tokens['a']); check($d['animal']['idade']===3,'Edição não persistiu');
    $pdo->prepare('UPDATE cliente SET ativo=0 WHERE id=?')->execute([$ids['a']]);
    [$status]=api("animais.php?acao=id&id=$id",null,$tokens['b']); check($status===404,'Animal de responsável inativo visível');
    $pdo->prepare('UPDATE cliente SET ativo=1 WHERE id=?')->execute([$ids['a']]);
    [$status]=api("animais.php?acao=apagar&id=$id",[],$tokens['a']); check($status===200,'Exclusão falhou');
    $q=$pdo->prepare('SELECT ativo FROM animal WHERE id=?'); $q->execute([$id]); check((int)$q->fetchColumn()===0,'Exclusão não foi lógica');
    [$status]=api("animais.php?acao=id&id=$id",null,$tokens['a']); check($status===404,'Animal apagado visível');
    [$status,$d]=api('animais.php?id_cliente='.$ids['a'],null,$tokens['a']); check($d['animais']===[],'Listagem inclui apagado');
    echo "OK: cadastro, ID, edição, filtros, pesquisa, responsável, autorização e exclusão lógica.\n";
} finally {
    foreach ($tokens as $token) api('logout.php',[],$token);
    foreach ($ids as $id) {
        $pdo->prepare('DELETE FROM animal WHERE id_cliente=?')->execute([$id]);
        $pdo->prepare('DELETE FROM cliente WHERE id=?')->execute([$id]);
    }
}
