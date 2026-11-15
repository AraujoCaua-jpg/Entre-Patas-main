<?php
if (PHP_SAPI !== 'cli') exit;
$_SERVER['REQUEST_METHOD'] = 'CLI';
require_once __DIR__ . '/auth_common.php';
banco()->exec(file_get_contents(__DIR__ . '/notificacoes.sql'));
echo "Controle de leitura de notificações preparado.\n";
