<?php
if (PHP_SAPI !== 'cli') exit;
$pdo = new PDO('mysql:host=localhost;dbname=entrepatas;charset=utf8mb4', getenv('DB_USER') ?: 'root', getenv('DB_PASSWORD') ?: '', [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION]);
foreach (['questionario','adocao'] as $t) {
    $id = $pdo->query("SHOW COLUMNS FROM `$t` LIKE 'id'")->fetch(PDO::FETCH_ASSOC);
    if (!$id) throw new RuntimeException("Tabela $t sem coluna id.");
    if (stripos($id['Extra'], 'auto_increment') === false) $pdo->exec("ALTER TABLE `$t` MODIFY id INT NOT NULL AUTO_INCREMENT");
}
foreach (['imovel','apoio','compromisso','moradores','financeiro','rotina'] as $campo) {
    $q = $pdo->prepare("SHOW COLUMNS FROM questionario LIKE ?"); $q->execute([$campo]);
    if (!$q->fetch()) $pdo->exec("ALTER TABLE questionario ADD `$campo` TINYINT NULL DEFAULT NULL");
}
$coluna = $pdo->query("SHOW COLUMNS FROM cliente LIKE 'questionario_pendente'")->fetch();
if (!$coluna) $pdo->exec('ALTER TABLE cliente ADD questionario_pendente TINYINT NOT NULL DEFAULT 0');
foreach (['vacinado','castrado'] as $campo) {
    $q = $pdo->prepare('SHOW COLUMNS FROM animal LIKE ?');
    $q->execute([$campo]);
    if (!$q->fetch()) $pdo->exec("ALTER TABLE animal ADD `$campo` VARCHAR(5) NULL DEFAULT NULL");
}
echo "Questionário, adoções e dados de vacinação/castração preparados.\n";
