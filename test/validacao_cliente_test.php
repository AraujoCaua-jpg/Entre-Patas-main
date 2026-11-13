<?php
require_once __DIR__ . '/../backend/validacao_cliente.php';
function verificar($ok, $mensagem) { if (!$ok) throw new RuntimeException($mensagem); }
foreach (['SenhaValida!123','Aa1!'.str_repeat('x',68),'Aa1!'.str_repeat('á',34)] as $senha) verificar(senha_valida($senha),'Senha válida rejeitada');
foreach (['12345678','Aa1!', 'Aa1!'.str_repeat('x',69), 'Aa1!'.str_repeat('á',35), "Senha!123\0", [], null] as $senha) verificar(!senha_valida($senha),'Senha inválida aceita');
$base=['nome'=>' Ana ','sobrenome'=>'Silva','email'=>'ana@example.com','usuario'=>'ana_1','telefone'=>'(11) 99999-9999','estado'=>'SP','cidadeDeResidencia'=>'São Paulo','larDeAdocao'=>false];
$valido=validar_cliente($base);
verificar($valido['nome']==='Ana' && $valido['telefone']==='11999999999','Normalização incorreta');
foreach ([['nome'=>str_repeat('a',51)],['sobrenome'=>str_repeat('a',101)],['usuario'=>'nome inválido'],['usuario'=>str_repeat('a',51)],['estado'=>'XX'],['cidadeDeResidencia'=>''],['cidadeDeResidencia'=>str_repeat('a',101)],['email'=>'inválido'],['telefone'=>'123'],['larDeAdocao'=>'true'],['larDeAdocao'=>true],['imagem'=>[]],['endereco'=>str_repeat('x',256)]] as $mudanca) {
    try { validar_cliente(array_replace($base,$mudanca)); }
    catch (InvalidArgumentException $e) { continue; }
    throw new RuntimeException('Dados inválidos aceitos: '.json_encode($mudanca));
}
verificar(validar_cliente([...$base,'larDeAdocao'=>true,'endereco'=>'Rua 1'])['endereco']==='Rua 1','Endereço válido rejeitado');
echo "OK: limites de senha em bytes/caracteres e validação comum de perfil.\n";
