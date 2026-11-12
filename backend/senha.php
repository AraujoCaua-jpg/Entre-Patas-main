<?php
require_once __DIR__ . '/auth_common.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') resposta(405, ['erro'=>'Método não permitido.']);
$d = json_decode(file_get_contents('php://input'), true);
if (!is_array($d)) resposta(400, ['erro'=>'Dados inválidos.']);
$acao = $_GET['acao'] ?? 'alterar';
try {
    $pdo = banco();
    if ($acao === 'solicitar') {
        $email = $d['email'] ?? null;
        if (!is_string($email) || !filter_var(trim($email), FILTER_VALIDATE_EMAIL)) resposta(400, ['erro'=>'E-mail inválido.']);
        // Não divulga se uma conta existe e nunca retorna o código ao aplicativo.
        if (getenv('RECOVERY_MAIL_ENABLED') !== '1' || !filter_var(getenv('RECOVERY_FROM'), FILTER_VALIDATE_EMAIL))
            resposta(503, ['erro'=>'O envio de recuperação ainda não está configurado. Entre em contato com o responsável pelo aplicativo.']);
        $q=$pdo->prepare('SELECT id FROM cliente WHERE email=? AND ativo=1'); $q->execute([trim($email)]); $c=$q->fetch();
        if ($c) {
            $q=$pdo->prepare('SELECT criado FROM recuperacao_senha WHERE id_cliente=? AND criado > DATE_SUB(NOW(), INTERVAL 60 SECOND) LIMIT 1');
            $q->execute([$c['id']]);
            if (!$q->fetch()) {
                $codigo=bin2hex(random_bytes(24));
                $q=$pdo->prepare('INSERT INTO recuperacao_senha (id_cliente,token_hash,expira) VALUES (?,?,DATE_ADD(NOW(), INTERVAL 15 MINUTE))');
                $q->execute([$c['id'],hash('sha256',$codigo)]);
                if (!mail(trim($email),'Recuperacao de senha Entre Patas',"Seu codigo de recuperacao: $codigo\nValido por 15 minutos.", 'From: '.getenv('RECOVERY_FROM'))) {
                    $pdo->prepare('DELETE FROM recuperacao_senha WHERE token_hash=?')->execute([hash('sha256',$codigo)]);
                    resposta(503,['erro'=>'Não foi possível enviar o e-mail. Tente novamente mais tarde.']);
                }
            }
        }
        resposta(200,['mensagem'=>'Se o e-mail pertencer a uma conta ativa, você receberá um código de recuperação.']);
    }
    $senha=$d['novaSenha'] ?? null;
    if (!is_string($senha) || strlen($senha)<8 || strlen($senha)>72 || !preg_match('/[A-Z]/',$senha)
        || !preg_match('/[a-z]/',$senha) || !preg_match('/[0-9]/',$senha) || !preg_match('/[^a-zA-Z0-9\s]/',$senha))
        resposta(400,['erro'=>'Use uma senha de 8 a 72 bytes com maiúscula, minúscula, número e símbolo.']);
    if ($acao === 'alterar') {
        $c=exigir_sessao();
        if (!is_string($d['senhaAtual'] ?? null) || !password_verify($d['senhaAtual'],$c['senha'])) resposta(400,['erro'=>'Senha atual incorreta.']);
        $pdo->prepare('UPDATE cliente SET senha=? WHERE id=? AND ativo=1')->execute([password_hash($senha,PASSWORD_DEFAULT),$c['id']]);
        $pdo->prepare('DELETE FROM recuperacao_senha WHERE id_cliente=?')->execute([$c['id']]);
        $_SESSION=[]; session_destroy();
    } elseif ($acao === 'recuperar') {
        if (!is_string($d['codigo'] ?? null) || !preg_match('/^[a-f0-9]{48}$/D',$d['codigo'])) resposta(400,['erro'=>'Código inválido ou expirado.']);
        $pdo->beginTransaction();
        $q=$pdo->prepare('SELECT r.id_cliente FROM recuperacao_senha r JOIN cliente c ON c.id=r.id_cliente WHERE r.token_hash=? AND r.expira>NOW() AND c.ativo=1 FOR UPDATE');
        $q->execute([hash('sha256',$d['codigo'])]); $c=$q->fetch();
        if (!$c) { $pdo->rollBack(); resposta(400,['erro'=>'Código inválido ou expirado.']); }
        $pdo->prepare('UPDATE cliente SET senha=? WHERE id=?')->execute([password_hash($senha,PASSWORD_DEFAULT),$c['id_cliente']]);
        $pdo->prepare('DELETE FROM recuperacao_senha WHERE id_cliente=?')->execute([$c['id_cliente']]);
        $pdo->commit();
    } else resposta(404,['erro'=>'Operação inválida.']);
    resposta(200,['mensagem'=>'Senha atualizada. Entre novamente.']);
} catch (Throwable $e) {
    if (isset($pdo) && $pdo->inTransaction()) $pdo->rollBack();
    error_log($e->getMessage()); resposta(500,['erro'=>'Não foi possível concluir a operação.']);
}
