<?php
require_once __DIR__ . '/auth_common.php';
require_once __DIR__ . '/adocao_consulta.php';
try {
    $cliente = exigir_sessao();
    $pdo = banco();
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $q = $pdo->prepare('SELECT id_adocao, status FROM notificacao_lida WHERE id_cliente=?');
        $q->execute([$cliente['id']]);
        $lidas = [];
        foreach ($q->fetchAll() as $r) $lidas[$r['id_adocao'].':'.$r['status']] = true;
        $lista = array_values(array_filter(adocao_consulta($pdo, $cliente['id']), function($a) use ($cliente, $lidas) {
            $recebida = (int)$a['id_dono'] === (int)$cliente['id']
                ? in_array($a['status'], ['Aguardando', 'Cancelado'], true)
                : in_array($a['status'], ['Aceito', 'Recusado'], true);
            return $recebida && !isset($lidas[$a['id'].':'.$a['status']]);
        }));
        resposta(200, ['adocoes'=>$lista]);
    }
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') resposta(405, ['erro'=>'Método não permitido.']);
    $dados = json_decode(file_get_contents('php://input'), true);
    $id = filter_var($dados['id'] ?? null, FILTER_VALIDATE_INT, ['options'=>['min_range'=>1]]);
    if (!$id) resposta(400, ['erro'=>'ID inválido.']);
    $lista = adocao_consulta($pdo, $cliente['id'], $id);
    if (!$lista) resposta(404, ['erro'=>'Notificação não encontrada.']);
    $status = $dados['status'] ?? '';
    if (!in_array($status, ['Aguardando', 'Aceito', 'Recusado', 'Cancelado'], true)) resposta(400, ['erro'=>'Status inválido.']);
    if ($status !== $lista[0]['status']) resposta(200, ['ok'=>true]);
    // Marca apenas a versão exibida, preservando respostas recebidas durante a leitura.
    $pdo->prepare('INSERT IGNORE INTO notificacao_lida (id_cliente,id_adocao,status) VALUES (?,?,?)')
        ->execute([$cliente['id'], $id, $status]);
    resposta(200, ['ok'=>true]);
} catch (Throwable $e) {
    error_log($e->getMessage());
    resposta(500, ['erro'=>'Não foi possível atualizar as notificações.']);
}
