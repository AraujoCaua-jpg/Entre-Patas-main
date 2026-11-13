<?php
function senha_valida($senha) {
    return is_string($senha) && mb_check_encoding($senha, 'UTF-8')
        && mb_strlen($senha, 'UTF-8') >= 8 && strlen($senha) <= 72
        && strpos($senha, "\0") === false
        && preg_match('/[A-Z]/', $senha) && preg_match('/[a-z]/', $senha)
        && preg_match('/[0-9]/', $senha) && preg_match('/[^a-zA-Z0-9\s]/u', $senha);
}

function validar_cliente($dados) {
    foreach (['nome'=>50,'sobrenome'=>100,'email'=>100,'usuario'=>50,'cidadeDeResidencia'=>100,'estado'=>2] as $campo=>$limite) {
        if (!is_string($dados[$campo] ?? null) || trim($dados[$campo]) === ''
            || mb_strlen(trim($dados[$campo]), 'UTF-8') > $limite) {
            throw new InvalidArgumentException("Confira o campo $campo.");
        }
        $dados[$campo] = trim($dados[$campo]);
    }
    if (!filter_var($dados['email'], FILTER_VALIDATE_EMAIL)
        || !preg_match('/^[a-zA-Z0-9_]+$/D', $dados['usuario'])
        || !preg_match('/^(AC|AL|AP|AM|BA|CE|DF|ES|GO|MA|MT|MS|MG|PA|PB|PR|PE|PI|RJ|RN|RS|RO|RR|SC|SP|SE|TO)$/D', $dados['estado'])) {
        throw new InvalidArgumentException('E-mail, usuário ou estado inválido.');
    }
    if (!is_string($dados['telefone'] ?? null)) throw new InvalidArgumentException('Telefone inválido.');
    $dados['telefone'] = preg_replace('/\D/', '', $dados['telefone']);
    if (!preg_match('/^\d{10,11}$/D', $dados['telefone'])) throw new InvalidArgumentException('Informe o telefone com DDD.');
    if (!is_bool($dados['larDeAdocao'] ?? null)) throw new InvalidArgumentException('Tipo de conta inválido.');
    foreach (['endereco','imagem'] as $campo) {
        if (isset($dados[$campo]) && (!is_string($dados[$campo]) || mb_strlen($dados[$campo], 'UTF-8') > 255))
            throw new InvalidArgumentException("Confira o campo $campo.");
    }
    if ($dados['larDeAdocao'] && trim($dados['endereco'] ?? '') === '') throw new InvalidArgumentException('Informe o endereço do lar.');
    if (!$dados['larDeAdocao']) $dados['endereco'] = null;
    return $dados;
}
