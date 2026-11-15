<?php
$arquivo = $_GET['arquivo'] ?? '';
if (!is_string($arquivo) || !preg_match('/^[a-f0-9]{48}\.(jpg|png|webp)$/D', $arquivo, $m)) {
    http_response_code(404);
    exit;
}
$caminho = __DIR__ . '/uploads/perfis/' . $arquivo;
if (!is_file($caminho)) {
    http_response_code(404);
    exit;
}
header('Content-Type: ' . ['jpg'=>'image/jpeg','png'=>'image/png','webp'=>'image/webp'][$m[1]]);
header('Content-Length: ' . filesize($caminho));
header('X-Content-Type-Options: nosniff');
header('Cache-Control: public, max-age=86400');
header('Access-Control-Allow-Origin: *');
readfile($caminho);
