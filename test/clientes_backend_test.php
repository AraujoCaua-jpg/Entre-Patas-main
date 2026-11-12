<?php
$base = getenv('API_BASE_URL') ?: 'http://localhost/entrepatas-api';
$pdo = new PDO('mysql:host=localhost;dbname=entrepatas;charset=utf8mb4', getenv('DB_USER') ?: 'root',getenv('DB_PASSWORD') ?: '',[PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
function check($ok,$msg){if(!$ok)throw new RuntimeException($msg);}
function callApi($route,$data=null,$token=null){
    global $base;
    $headers="Content-Type: application/json\r\nOrigin: http://localhost:50000\r\n";
    if($token)$headers.="Authorization: Bearer $token\r\n";
    $ctx=stream_context_create(['http'=>['method'=>$data===null?'GET':'POST','header'=>$headers,'content'=>$data===null?'':json_encode($data),'ignore_errors'=>true,'timeout'=>20]]);
    $body=file_get_contents("$base/$route",false,$ctx);preg_match('/\s(\d{3})\s/',$http_response_header[0]??'',$m);
    $json=json_decode($body,true);check(is_array($json),'Resposta não JSON em '.$route.': '.$body);
    return [(int)($m[1]??0),$json];
}
$ids=[];$tokens=[];
try{
    $s=bin2hex(random_bytes(5));$senha='TesteCrud!123';
    foreach(['a','b'] as $key){
        $email="$key$s@example.com";
        $q=$pdo->prepare('INSERT INTO cliente (nome,sobrenome,email,senha,usuario,ativo,larDeAdocao) VALUES (?,?,?,?,?,1,0)');
        $q->execute(['Teste','CRUD',$email,password_hash($senha,PASSWORD_DEFAULT),"u$key$s"]);$ids[$key]=(int)$pdo->lastInsertId();
        [$status,$d]=callApi('login.php',['email'=>$email,'senha'=>$senha]);check($status===200,'Login falhou');$tokens[$key]=$d['token'];
    }
    [$status]=callApi('clientes.php');check($status===401,'Perfil sem sessão aceito');
    [$status,$d]=callApi('clientes.php',null,$tokens['a']);check($status===200&&$d['cliente']['id']===$ids['a'],'Perfil errado');check(!isset($d['cliente']['senha']),'Senha vazou');
    [$status,$d]=callApi('clientes.php?acao=basico&id='.$ids['b'],null,$tokens['a']);check($status===200&&count($d['cliente'])===4,'Projeção básica incorreta');
    [$status,$d]=callApi('clientes.php?acao=id&id='.$ids['b'],null,$tokens['a']);check($status===200&&!isset($d['cliente']['email'])&&!isset($d['cliente']['telefone']),'Dados privados vazaram');
    [$status]=callApi('clientes.php?acao=id&id=-1',null,$tokens['a']);check($status===400,'ID inválido aceito');
    $edit=['nome'=>'Atualizado','sobrenome'=>'CRUD','email'=>"a$s@example.com",'telefone'=>'','usuario'=>"ua$s",'cidadeDeResidencia'=>'São Paulo','estado'=>'SP','larDeAdocao'=>false,'imagem'=>null];
    [$status]=callApi('clientes.php?acao=editar',$edit,$tokens['a']);check($status===400,'Telefone inválido aceito');
    $edit['telefone']='11'.random_int(100000000,999999999);$edit['id']=$ids['b'];
    [$status,$d]=callApi('clientes.php?acao=editar',$edit,$tokens['a']);check($status===200&&$d['cliente']['id']===$ids['a']&&$d['cliente']['nome']==='Atualizado','Edição não persistiu');
    [$status,$d]=callApi('clientes.php?acao=id&id='.$ids['b'],null,$tokens['a']);check($d['cliente']['nome']==='Teste','ID do corpo alterou outra pessoa');
    $edit['email']="b$s@example.com";
    [$status]=callApi('clientes.php?acao=editar',$edit,$tokens['a']);check($status===409,'E-mail duplicado aceito');
    [$status,$d]=callApi('clientes.php?acao=buscar&q='.urlencode("ua$s"),null,$tokens['b']);check($status===200&&count($d['clientes'])===1,'Pesquisa falhou');
    [$status,$d]=callApi('clientes.php?acao=buscar&q=%25',null,$tokens['b']);check($status===200&&count($d['clientes'])===0,'Curinga não escapado');
    [$status]=callApi('senha.php',['senhaAtual'=>'errada','novaSenha'=>'NovaTeste!123'],$tokens['a']);check($status===400,'Senha atual errada aceita');
    [$status]=callApi('senha.php',['senhaAtual'=>$senha,'novaSenha'=>'NovaTeste!123'],$tokens['a']);check($status===200,'Troca de senha falhou');
    [$status]=callApi('clientes.php',null,$tokens['a']);check($status===401,'Sessão não revogada após troca de senha');
    [$status]=callApi('login.php',['email'=>"a$s@example.com",'senha'=>$senha]);check($status===401,'Senha antiga ainda aceita');
    [$status,$d]=callApi('login.php',['email'=>"a$s@example.com",'senha'=>'NovaTeste!123']);check($status===200,'Nova senha rejeitada');$tokens['a']=$d['token'];
    $codigo=bin2hex(random_bytes(24));
    $pdo->prepare('INSERT INTO recuperacao_senha(id_cliente,token_hash,expira) VALUES (?,?,DATE_ADD(NOW(),INTERVAL 10 MINUTE))')->execute([$ids['a'],hash('sha256',$codigo)]);
    [$status]=callApi('senha.php?acao=recuperar',['codigo'=>str_repeat('f',48),'novaSenha'=>'Recuperada!123']);check($status===400,'Código inválido aceito');
    [$status]=callApi('senha.php?acao=recuperar',['codigo'=>$codigo,'novaSenha'=>'Recuperada!123']);check($status===200,'Código válido rejeitado');
    [$status]=callApi('senha.php?acao=recuperar',['codigo'=>$codigo,'novaSenha'=>'OutraSenha!123']);check($status===400,'Código reutilizado aceito');
    [$status]=callApi('clientes.php',null,$tokens['a']);check($status===401,'Recuperação não revogou sessão');
    [$status,$d]=callApi('login.php',['email'=>"a$s@example.com",'senha'=>'Recuperada!123']);check($status===200,'Senha recuperada rejeitada');$tokens['a']=$d['token'];
    [$status]=callApi('clientes.php?acao=apagar',[],$tokens['a']);check($status===200,'Exclusão falhou');
    $q=$pdo->prepare('SELECT ativo FROM cliente WHERE id=?');$q->execute([$ids['a']]);check((int)$q->fetchColumn()===0,'Exclusão não foi lógica');
    [$status]=callApi('clientes.php?acao=id&id='.$ids['a'],null,$tokens['b']);check($status===404,'Perfil inativo visível');
    [$status,$d]=callApi('clientes.php?acao=buscar&q='.urlencode("ua$s"),null,$tokens['b']);check($status===200&&$d['clientes']===[],'Pesquisa inclui inativos');
    [$status]=callApi('login.php',['email'=>"a$s@example.com",'senha'=>'Recuperada!123']);check($status===401,'Login de excluído aceito');
    echo "OK: perfil, privacidade, busca, edição, duplicidade, senha, recuperação e exclusão lógica.\n";
}finally{
    foreach($tokens as $token){callApi('logout.php',[],$token);}
    foreach($ids as $id){$pdo->prepare('DELETE FROM recuperacao_senha WHERE id_cliente=?')->execute([$id]);$pdo->prepare('DELETE FROM cliente WHERE id=?')->execute([$id]);}
}
