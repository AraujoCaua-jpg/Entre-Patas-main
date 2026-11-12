<?php
// Executar apenas pela linha de comando.
if (PHP_SAPI !== 'cli') exit;
$pdo = new PDO('mysql:host=localhost;dbname=entrepatas;charset=utf8mb4',
    getenv('DB_USER') ?: 'root', getenv('DB_PASSWORD') ?: '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$pdo->exec(file_get_contents(__DIR__ . '/recuperacao.sql'));
echo "Tabela de recuperação preparada.\n";
