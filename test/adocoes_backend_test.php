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
$ids=[]; $tokens=[];
try {
    $s=bin2hex(random_bytes(5));
    foreach (['dono','a','b','fora'] as $k) {
        $email="$k$s@example.com";
        $q=$pdo->prepare('INSERT INTO cliente (nome,sobrenome,email,senha,usuario,telefone,ativo,larDeAdocao,estado,cidadeDeResidencia) VALUES (?,?,?,?,?,?,1,0,?,?)');
        $q->execute([$k,'Teste',$email,password_hash('TesteAnimal!123',PASSWORD_DEFAULT),"u$k$s",'11'.random_int(100000000,999999999),'SP',"Cidade$s"]);
        $ids[$k]=(int)$pdo->lastInsertId();
        [$status,$d]=api('login.php',['email'=>$email,'senha'=>'TesteAnimal!123']); check($status===200,'Login falhou'); $tokens[$k]=$d['token'];
    }
    [$status,$d]=api('questionario.php',null,$tokens['a']); check($status===200 && $d['questionario']===null,'Sem teste deve retornar null');
    [$status]=api('questionario.php'); check($status===401,'Teste sem sessão aceito');
    $respostas=['tipo'=>'Gato','sexo'=>'Fêmea','idadeMin'=>0,'idadeMax'=>10,'porte'=>0,'energia'=>1,'ambiente'=>'Apartamento','sozinho'=>5,'dedicacao'=>4,'animais'=>'Não',
      'imovel'=>1,'apoio'=>1,'compromisso'=>1,'moradores'=>1,'financeiro'=>3,'rotina'=>1,'id_cliente'=>$ids['b']];
    [$status,$d]=api('login.php',['email'=>"a$s@example.com",'senha'=>'TesteAnimal!123']);
    check((int)$d['cliente']['questionario_pendente']===0,'Conta antiga foi obrigada a fazer teste');
    $tokens['antigo']=$d['token'];
    [$status,$d]=api('cadastrar_cliente.php',['nome'=>'Novo','sobrenome'=>'Teste','email'=>"novo$s@example.com",'telefone'=>'11'.random_int(100000000,999999999),'senha'=>'TesteAnimal!123','usuario'=>"novo$s",'questionario_pendente'=>0]);
    check($status===201,'Cadastro novo falhou'); $ids['novo']=$d['id'];
    [$status,$d]=api('login.php',['email'=>"novo$s@example.com",'senha'=>'TesteAnimal!123']);
    check($status===200 && (int)$d['cliente']['questionario_pendente']===1,'Novo cadastro não exige teste'); $tokens['novo']=$d['token'];
    [$status]=api('questionario.php',$respostas,$tokens['novo']); check($status===200,'Novo usuário não salvou teste');
    [$status,$d]=api('login.php',['email'=>"novo$s@example.com",'senha'=>'TesteAnimal!123']);
    check((int)$d['cliente']['questionario_pendente']===0,'Teste concluído continua obrigatório'); $tokens['novo_concluido']=$d['token'];
    [$status,$d]=api('questionario.php',$respostas,$tokens['a']); check($status===200,'Salvar questionário falhou: '.json_encode($d));
    check((int)$d['questionario']['id_cliente']===$ids['a'],'Responsável do teste forjado');
    $questionarioId=$d['questionario']['id'];
    [$status,$d]=api('questionario.php',null,$tokens['b']); check($d['questionario']===null,'Respostas de outro usuário vazaram');
    [$status]=api('questionario.php',[...$respostas,'idadeMax'=>-1],$tokens['a']); check($status===400,'Idade inválida aceita');
    [$status,$d]=api('questionario.php',$respostas,$tokens['a']); check((int)$d['questionario']['id']===(int)$questionarioId,'Refazer duplicou teste');
    $animal=['nome'=>"Pet$s",'idade'=>2,'imagem'=>null,'tipo'=>'Gato','descricao'=>'Animal temporário','sexo'=>'Fêmea','status'=>'Disponível','energia'=>'Médio','porte'=>'Pequeno','convivencia'=>'Sim','carencia'=>'Sim'];
    [$status,$d]=api('animais.php?acao=cadastrar',$animal,$tokens['dono']); check($status===200,'Cadastro animal falhou'); $animalId=$d['animal']['id'];
    [$status,$d]=api("animais.php?acao=id&id=$animalId",null,$tokens['a']); check($d['animal']['compatibilidade']['total']===100,'Compatibilidade perfeita não é 100');
    [$status,$d]=api("animais.php?acao=id&id=$animalId",null,$tokens['b']); check($d['animal']['compatibilidade']===null,'Inventou nota sem respostas');
    $desfavoravel=[...$respostas,'tipo'=>'Cachorro','sexo'=>'Macho','porte'=>2,'energia'=>2,'idadeMin'=>20,'idadeMax'=>30,'sozinho'=>1,'dedicacao'=>1,'imovel'=>0,'apoio'=>0,'compromisso'=>0,'moradores'=>0,'financeiro'=>1,'rotina'=>0];
    api('questionario.php',$desfavoravel,$tokens['a']);
    [$status,$d]=api("animais.php?acao=id&id=$animalId",null,$tokens['a']); $score=$d['animal']['compatibilidade'];
    check($score['total']<100 && $score['total']>=0,'Nota não mudou com respostas');
    api('questionario.php',$respostas,$tokens['a']);
    [$status,$d]=api('animais.php?acao=melhores&q='.urlencode("Pet$s"),null,$tokens['a']); check($status===200 && $d['animais'][0]['id']===$animalId,'Lista de melhores falhou');
    [$status]=api('adocoes.php?acao=solicitar',['id_animal'=>$animalId],$tokens['dono']); check($status===400,'Adotou próprio animal');
    [$status,$d]=api('adocoes.php?acao=solicitar',['id_animal'=>$animalId,'id_cliente'=>$ids['b'],'id_dono'=>$ids['fora'],'status'=>'Aceito'],$tokens['a']);
    check($status===200 && $d['adocao']['status']==='Aguardando' && $d['adocao']['id_cliente']===$ids['a'] && $d['adocao']['id_dono']===$ids['dono'],'Solicitação forjada'); $pedido=$d['adocao']['id'];
    [$status]=api('adocoes.php?acao=solicitar',['id_animal'=>$animalId],$tokens['a']); check($status===409,'Pedido duplicado aceito');
    [$status,$d]=api('adocoes.php?acao=solicitar',['id_animal'=>$animalId],$tokens['b']); check($status===200,'Segundo pretendente falhou'); $outro=$d['adocao']['id'];
    [$status]=api("adocoes.php?acao=id&id=$pedido",null,$tokens['fora']); check($status===404,'Solicitação privada exposta');
    [$status,$d]=api('adocoes.php',null,$tokens['fora']); check($d['adocoes']===[],'Lista expôs pedidos alheios');
    [$status,$d]=api("adocoes.php?acao=id&id=$pedido",null,$tokens['dono']); check($status===200 && $d['adocao']['solicitante_email']==="a$s@example.com",'Responsável não recebe contato');
    [$status]=api("adocoes.php?acao=aceitar&id=$pedido",[],$tokens['a']); check($status===403,'Solicitante aprovou pedido');
    [$status]=api("adocoes.php?acao=cancelar&id=$pedido",[],$tokens['dono']); check($status===403,'Responsável cancelou pelo solicitante');
    [$status,$d]=api("adocoes.php?acao=aceitar&id=$pedido",[],$tokens['dono']); check($status===200 && $d['adocao']['status']==='Aceito','Aprovação falhou');
    [$status,$d]=api("animais.php?acao=id&id=$animalId",null,$tokens['a']); check($d['animal']['status']==='Adotado','Animal não marcado adotado');
    [$status,$d]=api("adocoes.php?acao=id&id=$outro",null,$tokens['b']); check($d['adocao']['status']==='Recusado','Pedido concorrente não encerrado');
    [$status]=api("adocoes.php?acao=aceitar&id=$outro",[],$tokens['dono']); check($status===409,'Segunda adoção aceita');
    [$status]=api('adocoes.php?acao=solicitar',['id_animal'=>$animalId],$tokens['fora']); check($status===409,'Pedido em animal adotado aceito');
    [$status,$d]=api("animais.php?acao=editar&id=$animalId",$animal,$tokens['dono']); check($status===200 && $d['animal']['status']==='Adotado','Edição reabriu adoção');
    [$status,$d]=api('animais.php?acao=cadastrar',$animal,$tokens['dono']); $segundo=$d['animal']['id'];
    [$status,$d]=api('adocoes.php?acao=solicitar',['id_animal'=>$segundo],$tokens['a']); $cancelar=$d['adocao']['id'];
    [$status,$d]=api("adocoes.php?acao=cancelar&id=$cancelar",[],$tokens['a']); check($status===200 && $d['adocao']['status']==='Cancelado','Cancelamento falhou');
    [$status,$d]=api('adocoes.php?acao=solicitar',['id_animal'=>$segundo],$tokens['a']); check($status===200,'Não pôde solicitar após cancelamento'); $recusar=$d['adocao']['id'];
    [$status,$d]=api("adocoes.php?acao=recusar&id=$recusar",[],$tokens['dono']); check($status===200 && $d['adocao']['status']==='Recusado','Recusa falhou');
    api("animais.php?acao=apagar&id=$segundo",[],$tokens['dono']);
    [$status]=api('adocoes.php?acao=solicitar',['id_animal'=>$segundo],$tokens['b']); check($status===409,'Pedido em animal inativo aceito');
    echo "OK: questionário persistente, notas reais, isolamento, solicitações, privacidade, duplicidade, aprovação única, recusa e cancelamento.\n";
} finally {
    foreach ($tokens as $token) api('logout.php',[],$token);
    foreach ($ids as $id) {
        $pdo->prepare('DELETE FROM adocao WHERE id_cliente=? OR id_dono=?')->execute([$id,$id]);
        $pdo->prepare('DELETE FROM questionario WHERE id_cliente=?')->execute([$id]);
    }
    foreach ($ids as $id) {
        $pdo->prepare('DELETE FROM animal WHERE id_cliente=?')->execute([$id]);
        $pdo->prepare('DELETE FROM cliente WHERE id=?')->execute([$id]);
    }
}
