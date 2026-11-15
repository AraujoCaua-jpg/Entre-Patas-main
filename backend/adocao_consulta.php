<?php
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
