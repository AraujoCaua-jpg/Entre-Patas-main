<?php
require_once __DIR__ . '/auth_common.php';
require_once __DIR__ . '/validacao_cliente.php';
function dados_publicos($c, $basico = false) {
    $campos = $basico ? ['id','nome','usuario','imagem']
        : ['id','nome','sobrenome','usuario','imagem','estado','cidadeDeResidencia','larDeAdocao'];
    // Contatos de lares de adoção são exibidos publicamente pelo produto.
    if (!$basico && $c['larDeAdocao']) $campos = array_merge($campos, ['email','telefone','endereco']);
    return array_intersect_key(cliente_publico($c), array_flip($campos));
}
try {
    $proprio = exigir_sessao();
    $pdo = banco();
    $acao = $_GET['acao'] ?? 'perfil';
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        if ($acao === 'perfil') resposta(200, ['cliente' => cliente_publico($proprio)]);
        if ($acao === 'buscar') {
            $termo = trim($_GET['q'] ?? '');
            if (strlen($termo) > 100) resposta(400, ['erro' => 'Pesquisa muito longa.']);
            $termo = ltrim($termo, '@');
            $termo = str_replace(['!','%','_'], ['!!','!%','!_'], $termo);
            $q = $pdo->prepare("SELECT * FROM cliente WHERE ativo = 1 AND (nome LIKE ? ESCAPE '!' OR usuario LIKE ? ESCAPE '!') ORDER BY nome, id LIMIT 50");
            $q->execute(["%$termo%", "%$termo%"]);
            resposta(200, ['clientes' => array_map(fn($c) => dados_publicos($c), $q->fetchAll())]);
        }
        if ($acao === 'id' || $acao === 'basico') {
            $id = filter_var($_GET['id'] ?? '', FILTER_VALIDATE_INT, ['options' => ['min_range' => 1]]);
            if (!$id) resposta(400, ['erro' => 'ID inválido.']);
            $q = $pdo->prepare('SELECT * FROM cliente WHERE id = ? AND ativo = 1');
            $q->execute([$id]);
            $c = $q->fetch();
            if (!$c) resposta(404, ['erro' => 'Usuário não encontrado.']);
            resposta(200, ['cliente' => $acao === 'id' && $id === (int)$proprio['id']
                ? cliente_publico($c) : dados_publicos($c, $acao === 'basico')]);
        }
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if ($acao === 'apagar') {
            $pdo->prepare('UPDATE cliente SET ativo = 0 WHERE id = ?')->execute([$proprio['id']]);
            $_SESSION = [];
            session_destroy();
            resposta(200, ['mensagem' => 'Conta desativada.']);
        }
        if ($acao === 'editar') {
            $d = json_decode(file_get_contents('php://input'), true);
            if (!is_array($d)) resposta(400, ['erro' => 'Dados inválidos.']);
            try {
                $d = validar_cliente($d);
            } catch (InvalidArgumentException $erro) {
                resposta(400, ['erro'=>$erro->getMessage()]);
            }
            $q = $pdo->prepare('UPDATE cliente SET nome=?,sobrenome=?,email=?,telefone=?,usuario=?,cidadeDeResidencia=?,estado=?,larDeAdocao=?,endereco=?,imagem=? WHERE id=? AND ativo=1');
            $q->execute([$d['nome'],$d['sobrenome'],$d['email'],$d['telefone'],$d['usuario'],$d['cidadeDeResidencia'],$d['estado'],
                (int)$d['larDeAdocao'],$d['larDeAdocao'] ? $d['endereco'] : null,$d['imagem'] ?? null,$proprio['id']]);
            $q = $pdo->prepare('SELECT * FROM cliente WHERE id=?');
            $q->execute([$proprio['id']]);
            resposta(200, ['cliente' => cliente_publico($q->fetch())]);
        }
    } else resposta(405, ['erro' => 'Método não permitido.']);
    resposta(404, ['erro' => 'Operação não encontrada.']);
} catch (PDOException $e) {
    if (($e->errorInfo[1] ?? 0) === 1062) resposta(409, ['erro' => 'E-mail, telefone ou usuário já cadastrado.']);
    error_log($e->getMessage());
    resposta(500, ['erro' => 'Não foi possível concluir a operação.']);
} catch (Throwable $e) {
    error_log($e->getMessage());
    resposta(500, ['erro' => 'Não foi possível concluir a operação.']);
}
