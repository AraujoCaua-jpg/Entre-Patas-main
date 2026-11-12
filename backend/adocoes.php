<?php
require_once __DIR__ . '/auth_common.php';
function adocao_id($v) {
    $id=filter_var($v,FILTER_VALIDATE_INT,['options'=>['min_range'=>1]]);
    if (!$id) resposta(400,['erro'=>'ID inválido.']);
    return $id;
}
function adocao_erro($pdo,$status,$texto) {
    if ($pdo->inTransaction()) $pdo->rollBack();
    resposta($status,['erro'=>$texto]);
}
function adocao_consulta($pdo,$usuario,$id=null) {
    $sql='SELECT d.*, a.nome AS animal_nome, a.imagem AS animal_imagem, a.idade AS animal_idade, a.sexo AS animal_sexo,
        dono.estado, dono.cidadeDeResidencia, pretendente.nome AS solicitante_nome, pretendente.sobrenome AS solicitante_sobrenome,
        pretendente.email AS solicitante_email, pretendente.telefone AS solicitante_telefone
        FROM adocao d JOIN animal a ON a.id=d.id_animal JOIN cliente dono ON dono.id=d.id_dono
        JOIN cliente pretendente ON pretendente.id=d.id_cliente WHERE (d.id_cliente=? OR d.id_dono=?)';
    $args=[$usuario,$usuario];
    if ($id !== null) { $sql.=' AND d.id=?'; $args[]=$id; }
    $q=$pdo->prepare($sql.' ORDER BY d.data DESC, d.id DESC'); $q->execute($args);
    return array_map(function($r) {
        foreach(['id','id_animal','id_cliente','id_dono','animal_idade'] as $c) $r[$c]=(int)$r[$c];
        return $r;
    },$q->fetchAll());
}
try {
    $cliente=exigir_sessao(); $pdo=banco(); $acao=$_GET['acao'] ?? 'listar';
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        if ($acao==='id') {
            $lista=adocao_consulta($pdo,$cliente['id'],adocao_id($_GET['id'] ?? ''));
            if (!$lista) resposta(404,['erro'=>'Solicitação não encontrada.']);
            resposta(200,['adocao'=>$lista[0]]);
        }
        if ($acao!=='listar') resposta(404,['erro'=>'Operação não encontrada.']);
        resposta(200,['adocoes'=>adocao_consulta($pdo,$cliente['id'])]);
    }
    if ($_SERVER['REQUEST_METHOD']!=='POST') resposta(405,['erro'=>'Método não permitido.']);
    if (!in_array($acao,['solicitar','aceitar','recusar','cancelar'],true)) resposta(404,['erro'=>'Operação não encontrada.']);
    $dados=json_decode(file_get_contents('php://input'),true);
    if (!is_array($dados)) resposta(400,['erro'=>'Dados inválidos.']);
    $id=null;
    if ($acao==='solicitar') $animalId=adocao_id($dados['id_animal'] ?? '');
    else {
        $id=adocao_id($_GET['id'] ?? '');
        $q=$pdo->prepare('SELECT id_animal FROM adocao WHERE id=? AND (id_cliente=? OR id_dono=?)');
        $q->execute([$id,$cliente['id'],$cliente['id']]); $animalId=$q->fetchColumn();
        if (!$animalId) resposta(404,['erro'=>'Solicitação não encontrada.']);
    }
    $pdo->beginTransaction();
    // Todas as transições travam o animal primeiro: só uma solicitação pode ser aceita.
    $q=$pdo->prepare('SELECT * FROM animal WHERE id=? FOR UPDATE'); $q->execute([$animalId]); $a=$q->fetch();
    if (!$a) adocao_erro($pdo,404,'Animal não encontrado.');
    if ($acao==='solicitar') {
        if ((int)$a['id_cliente']===(int)$cliente['id']) adocao_erro($pdo,400,'Você não pode solicitar a adoção do próprio animal.');
        $q=$pdo->prepare('SELECT ativo FROM cliente WHERE id=?'); $q->execute([$a['id_cliente']]);
        if ((int)$a['ativo']!==1 || (int)$q->fetchColumn()!==1 || $a['status']==='Adotado') adocao_erro($pdo,409,'Este animal não está disponível para adoção.');
        $q=$pdo->prepare("SELECT id FROM adocao WHERE id_animal=? AND id_cliente=? AND status IN ('Aguardando','Aceito')");
        $q->execute([$animalId,$cliente['id']]);
        if ($q->fetchColumn()) adocao_erro($pdo,409,'Você já possui uma solicitação em andamento para este animal.');
        $pdo->prepare("INSERT INTO adocao (data,status,id_animal,id_cliente,id_dono) VALUES (NOW(),'Aguardando',?,?,?)")
            ->execute([$animalId,$cliente['id'],$a['id_cliente']]);
        $id=(int)$pdo->lastInsertId();
    } else {
        $q=$pdo->prepare('SELECT * FROM adocao WHERE id=? FOR UPDATE'); $q->execute([$id]); $d=$q->fetch();
        $autorizado=$acao==='cancelar' ? (int)$d['id_cliente']===(int)$cliente['id'] : (int)$d['id_dono']===(int)$cliente['id'];
        if (!$autorizado) adocao_erro($pdo,403,'Você não pode realizar esta ação.');
        if ($d['status']!=='Aguardando') adocao_erro($pdo,409,'Esta solicitação já foi finalizada.');
        if ($acao==='aceitar') {
            $q=$pdo->prepare('SELECT ativo FROM cliente WHERE id=?'); $q->execute([$d['id_cliente']]);
            if ((int)$a['ativo']!==1 || $a['status']==='Adotado' || (int)$q->fetchColumn()!==1 || (int)$a['id_cliente']!==(int)$cliente['id'])
                adocao_erro($pdo,409,'Não é possível aprovar esta adoção.');
            $pdo->prepare("UPDATE animal SET status='Adotado' WHERE id=?")->execute([$animalId]);
            $pdo->prepare("UPDATE adocao SET status='Recusado' WHERE id_animal=? AND id<>? AND status='Aguardando'")->execute([$animalId,$id]);
        }
        $status=['aceitar'=>'Aceito','recusar'=>'Recusado','cancelar'=>'Cancelado'][$acao];
        $pdo->prepare('UPDATE adocao SET status=? WHERE id=?')->execute([$status,$id]);
    }
    $pdo->commit();
    resposta(200,['adocao'=>adocao_consulta($pdo,$cliente['id'],$id)[0]]);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    error_log($e->getMessage()); resposta(500,['erro'=>'Não foi possível concluir a solicitação de adoção.']);
}
