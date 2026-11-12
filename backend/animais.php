<?php
require_once __DIR__ . '/auth_common.php';
require_once __DIR__ . '/compatibilidade.php';

function animal_id($valor) {
    $id = filter_var($valor, FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
    if (!$id) resposta(400, ['erro' => 'ID inválido.']);
    return $id;
}
function animal_json($a) {
    global $questionario;
    foreach (['id', 'idade', 'id_cliente'] as $campo) $a[$campo] = (int)$a[$campo];
    $a['ativo'] = (bool)$a['ativo'];
    $a['compatibilidade'] = compatibilidade($a, $questionario);
    return $a;
}
function animal_dados($d) {
    if (!is_array($d)) resposta(400, ['erro' => 'Dados inválidos.']);
    $resultado = [];
    foreach (['nome'=>100, 'tipo'=>50, 'descricao'=>10000, 'sexo'=>50, 'status'=>50,
        'energia'=>50, 'porte'=>50, 'convivencia'=>5, 'carencia'=>5] as $campo=>$limite) {
        if (!is_string($d[$campo] ?? null) || trim($d[$campo]) === '' || mb_strlen(trim($d[$campo])) > $limite)
            resposta(400, ['erro' => "Confira o campo $campo."]);
        $resultado[$campo] = trim($d[$campo]);
    }
    foreach (['tipo'=>['Cachorro','Gato'], 'sexo'=>['Macho','Fêmea'],
        'energia'=>['Baixo','Médio','Alto'], 'porte'=>['Pequeno','Médio','Grande'],
        'convivencia'=>['Sim','Não'], 'carencia'=>['Sim','Não']] as $campo=>$opcoes) {
        if (!in_array($resultado[$campo], $opcoes, true)) resposta(400, ['erro'=>"Confira o campo $campo."]);
    }
    if (!is_int($d['idade'] ?? null) || $d['idade'] < 0 || $d['idade'] > 2147483647)
        resposta(400, ['erro'=>'Informe uma idade inteira em anos, a partir de zero.']);
    $resultado['idade'] = $d['idade'];
    $imagem = $d['imagem'] ?? null;
    if ($imagem === '') $imagem = null;
    if ($imagem !== null && (!is_string($imagem) || strlen($imagem) > 255
        || !filter_var($imagem, FILTER_VALIDATE_URL) || !in_array(strtolower(parse_url($imagem, PHP_URL_SCHEME) ?? ''), ['https','http'], true)))
        resposta(400, ['erro'=>'Informe um endereço HTTP ou HTTPS válido para a imagem.']);
    $resultado['imagem'] = $imagem;
    return $resultado;
}
try {
    $cliente = exigir_sessao();
    $pdo = banco();
    $questionario = questionario_atual($pdo, $cliente['id']);
    $acao = $_GET['acao'] ?? 'listar';
    $select = 'SELECT a.*, c.estado, c.cidadeDeResidencia FROM animal a JOIN cliente c ON c.id=a.id_cliente WHERE a.ativo=1 AND c.ativo=1';
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        if ($acao === 'id') {
            $q = $pdo->prepare($select . ' AND a.id=?');
            $q->execute([animal_id($_GET['id'] ?? '')]);
            $a = $q->fetch();
            if (!$a) resposta(404, ['erro'=>'Animal não encontrado.']);
            resposta(200, ['animal'=>animal_json($a)]);
        }
        if (!in_array($acao, ['listar','buscar','usuario','melhores'], true)) resposta(404, ['erro'=>'Operação não encontrada.']);
        $params = [];
        if ($acao === 'usuario' || isset($_GET['id_cliente'])) {
            $select .= ' AND a.id_cliente=?';
            $params[] = animal_id($_GET['id_cliente'] ?? $cliente['id']);
        }
        foreach (['estado'=>'c.estado', 'cidade'=>'c.cidadeDeResidencia', 'tipo'=>'a.tipo', 'sexo'=>'a.sexo',
            'porte'=>'a.porte', 'energia'=>'a.energia', 'convivencia'=>'a.convivencia', 'carencia'=>'a.carencia', 'status'=>'a.status'] as $campo=>$coluna) {
            if (!isset($_GET[$campo]) || $_GET[$campo] === '') continue;
            if (!is_string($_GET[$campo]) || mb_strlen($_GET[$campo]) > 100) resposta(400, ['erro'=>'Filtro inválido.']);
            $select .= " AND $coluna=?";
            $params[] = trim($_GET[$campo]);
        }
        if (isset($_GET['q'])) {
            if (!is_string($_GET['q']) || mb_strlen($_GET['q']) > 100) resposta(400, ['erro'=>'Pesquisa muito longa.']);
            $termo = str_replace(['!','%','_'], ['!!','!%','!_'], trim($_GET['q']));
            $select .= " AND a.nome LIKE ? ESCAPE '!'";
            $params[] = "%$termo%";
        }
        $pagina = animal_id($_GET['pagina'] ?? 1);
        $offset = ($pagina - 1) * 50;
        if ($acao === 'melhores') {
            $q = $pdo->prepare($select . ' ORDER BY a.nome, a.id');
            $q->execute($params);
            $animais = array_map('animal_json', $q->fetchAll());
            usort($animais, fn($a,$b)=> (($b['compatibilidade']['total'] ?? -1) <=> ($a['compatibilidade']['total'] ?? -1)) ?: strcmp($a['nome'],$b['nome']) ?: ($a['id'] <=> $b['id']));
            resposta(200, ['animais'=>array_slice($animais, $offset, 50), 'pagina'=>$pagina]);
        }
        $q = $pdo->prepare($select . " ORDER BY a.nome, a.id LIMIT 50 OFFSET $offset");
        $q->execute($params);
        resposta(200, ['animais'=>array_map('animal_json', $q->fetchAll()), 'pagina'=>$pagina]);
    }
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') resposta(405, ['erro'=>'Método não permitido.']);
    if (!in_array($acao, ['cadastrar','editar','apagar'], true)) resposta(404, ['erro'=>'Operação não encontrada.']);
    if ($acao !== 'cadastrar') {
        $id = animal_id($_GET['id'] ?? '');
        $q = $pdo->prepare('SELECT id_cliente FROM animal WHERE id=? AND ativo=1');
        $q->execute([$id]);
        $dono = $q->fetchColumn();
        if ($dono === false) resposta(404, ['erro'=>'Animal não encontrado.']);
        if ((int)$dono !== (int)$cliente['id']) resposta(403, ['erro'=>'Apenas o responsável pode alterar este animal.']);
    }
    if ($acao === 'apagar') {
        $pdo->prepare('UPDATE animal SET ativo=0 WHERE id=? AND id_cliente=? AND ativo=1')->execute([$id,$cliente['id']]);
        resposta(200, ['mensagem'=>'Animal apagado.']);
    }
    $dados = animal_dados(json_decode(file_get_contents('php://input'), true));
    if ($acao === 'cadastrar' && $dados['status'] === 'Adotado') resposta(400, ['erro'=>'A adoção deve ser aprovada pela solicitação.']);
    if ($acao === 'editar') {
        $q = $pdo->prepare('SELECT status FROM animal WHERE id=?');
        $q->execute([$id]);
        $anterior = $q->fetchColumn();
        if ($dados['status'] === 'Adotado' && $anterior !== 'Adotado') resposta(400, ['erro'=>'A adoção deve ser aprovada pela solicitação.']);
        if ($anterior === 'Adotado') $dados['status'] = 'Adotado';
    }
    $campos = array_keys($dados);
    $valores = array_values($dados);
    if ($acao === 'cadastrar') {
        $sql = 'INSERT INTO animal (' . implode(',', $campos) . ',id_cliente,ativo) VALUES (' . implode(',', array_fill(0, count($campos), '?')) . ',?,1)';
        $valores[] = $cliente['id'];
        $pdo->prepare($sql)->execute($valores);
        $id = (int)$pdo->lastInsertId();
    } else {
        $sql = 'UPDATE animal SET ' . implode(',', array_map(fn($c)=>$c === 'status' ? "status=IF(status='Adotado',status,?)" : "$c=?", $campos)) . ' WHERE id=? AND id_cliente=? AND ativo=1';
        $valores[] = $id;
        $valores[] = $cliente['id'];
        $pdo->prepare($sql)->execute($valores);
    }
    $q = $pdo->prepare($select . ' AND a.id=?');
    $q->execute([$id]);
    resposta(200, ['animal'=>animal_json($q->fetch())]);
} catch (Throwable $e) {
    error_log($e->getMessage());
    resposta(500, ['erro'=>'Não foi possível concluir a operação com o animal.']);
}
