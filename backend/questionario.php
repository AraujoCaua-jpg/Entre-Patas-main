<?php
require_once __DIR__ . '/auth_common.php';
require_once __DIR__ . '/compatibilidade.php';
try {
    $cliente = exigir_sessao(); $pdo = banco();
    if ($_SERVER['REQUEST_METHOD'] === 'GET') resposta(200, ['questionario'=>questionario_atual($pdo, $cliente['id'])]);
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') resposta(405, ['erro'=>'Método não permitido.']);
    $d = json_decode(file_get_contents('php://input'), true);
    if (!is_array($d)) resposta(400, ['erro'=>'Respostas inválidas.']);
    $dados = [];
    foreach (['tipo'=>['Gato','Cachorro'], 'sexo'=>['Macho','Fêmea'], 'ambiente'=>['Casa c/ Quintal','Casa s/ Quintal','Apartamento','Outro'], 'animais'=>['Sim','Não']] as $campo=>$opcoes) {
        if (!in_array($d[$campo] ?? null, $opcoes, true)) resposta(400, ['erro'=>"Confira a resposta $campo."]);
        $dados[$campo] = $d[$campo];
    }
    foreach (['idadeMin'=>[0,2147483647], 'idadeMax'=>[0,2147483647], 'porte'=>[0,2], 'energia'=>[0,2], 'sozinho'=>[1,5], 'dedicacao'=>[1,4],
        'imovel'=>[0,1], 'apoio'=>[0,1], 'compromisso'=>[0,1], 'moradores'=>[0,1], 'financeiro'=>[1,3], 'rotina'=>[0,1]] as $campo=>$limites) {
        if (!is_int($d[$campo] ?? null) || $d[$campo] < $limites[0] || $d[$campo] > $limites[1]) resposta(400, ['erro'=>"Confira a resposta $campo."]);
        $dados[$campo] = $d[$campo];
    }
    if ($dados['idadeMax'] < $dados['idadeMin']) resposta(400, ['erro'=>'A idade máxima deve ser maior ou igual à mínima.']);
    $pdo->beginTransaction();
    $q=$pdo->prepare('SELECT id FROM cliente WHERE id=? FOR UPDATE'); $q->execute([$cliente['id']]);
    $q=$pdo->prepare('SELECT id FROM questionario WHERE id_cliente=? ORDER BY id DESC LIMIT 1'); $q->execute([$cliente['id']]); $id=$q->fetchColumn();
    $campos=array_keys($dados); $valores=array_values($dados);
    if ($id !== false) {
        $valores[]=$id;
        $pdo->prepare('UPDATE questionario SET '.implode(',', array_map(fn($c)=>"`$c`=?",$campos)).' WHERE id=?')->execute($valores);
    } else {
        $valores[]=$cliente['id'];
        $pdo->prepare('INSERT INTO questionario (`'.implode('`,`',$campos).'`,id_cliente) VALUES ('.implode(',',array_fill(0,count($campos)+1,'?')).')')->execute($valores);
    }
    $pdo->prepare('UPDATE cliente SET questionario_pendente=0 WHERE id=?')->execute([$cliente['id']]);
    $pdo->commit();
    resposta(200, ['questionario'=>questionario_atual($pdo,$cliente['id'])]);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    error_log($e->getMessage()); resposta(500, ['erro'=>'Não foi possível salvar ou carregar o teste de compatibilidade.']);
}
