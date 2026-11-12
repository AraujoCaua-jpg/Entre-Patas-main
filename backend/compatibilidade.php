<?php
// Regra de afinidade do produto, versão 1. Não aprova adoções automaticamente.
function questionario_atual($pdo, $id) {
    $q = $pdo->prepare('SELECT * FROM questionario WHERE id_cliente=? ORDER BY id DESC LIMIT 1');
    $q->execute([$id]);
    $d = $q->fetch(PDO::FETCH_ASSOC);
    if (!$d) return null;
    foreach (['imovel','apoio','compromisso','moradores','financeiro','rotina'] as $campo) if (!isset($d[$campo])) return null;
    return $d;
}
function compatibilidade($a, $q) {
    if (!$q) return null;
    $niveis = ['Baixo'=>0,'Médio'=>1,'Alto'=>2,'Pequeno'=>0,'Grande'=>2];
    if (!isset($niveis[$a['energia'] ?? ''], $niveis[$a['porte'] ?? ''])) return null;
    $energia = $niveis[$a['energia']]; $porte = $niveis[$a['porte']];
    $dedicacao = min(1, (int)$q['dedicacao'] / ($energia + 1));
    $companhia = $a['carencia'] === 'Sim' ? ((int)$q['sozinho'] - 1) / 4 : 1;
    $preparo = ((int)$q['imovel'] + (int)$q['apoio'] + (int)$q['compromisso'] + (int)$q['moradores'] + (int)$q['rotina'] + ((int)$q['financeiro'] - 1) / 2) / 6;
    $rotina = ($dedicacao + $companhia + $preparo) / 3 * 100;
    $espaco = ($a['tipo'] === 'Gato' || $porte === 0) ? 1
        : (['Casa c/ Quintal'=>1, 'Casa s/ Quintal'=>$porte === 2 ? .6 : .8, 'Apartamento'=>$porte === 2 ? .4 : .6, 'Outro'=>.5][$q['ambiente']] ?? .5);
    $convivencia = $q['animais'] === 'Sim' && $a['convivencia'] !== 'Sim' ? 0 : 1;
    $ambiente = ($espaco + $convivencia) / 2 * 100;
    $preferencias = (($q['tipo'] === $a['tipo'] ? 1 : 0) + ($q['sexo'] === $a['sexo'] ? 1 : 0)
        + ((int)$a['idade'] >= (int)$q['idadeMin'] && (int)$a['idade'] <= (int)$q['idadeMax'] ? 1 : 0)
        + (1 - abs((int)$q['porte'] - $porte) / 2) + (1 - abs((int)$q['energia'] - $energia) / 2)) / 5 * 100;
    return ['rotina'=>round($rotina), 'ambiente'=>round($ambiente), 'preferencias'=>round($preferencias),
        'total'=>(int)round(($rotina * 5 + $ambiente * 3 + $preferencias * 2) / 10), 'versao'=>1];
}
