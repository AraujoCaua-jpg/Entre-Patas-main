<?php
const FOTO_PERFIL_LIMITE = 3 * 1024 * 1024;

function validar_foto_perfil($base64) {
    if (!is_string($base64) || strlen($base64) > 4 * ceil(FOTO_PERFIL_LIMITE / 3))
        throw new InvalidArgumentException('Escolha uma foto de até 3 MB.');
    $bytes = base64_decode($base64, true);
    if ($bytes === false || strlen($bytes) === 0 || strlen($bytes) > FOTO_PERFIL_LIMITE)
        throw new InvalidArgumentException('Foto inválida ou maior que 3 MB.');
    $info = @getimagesizefromstring($bytes);
    $tipos = [IMAGETYPE_JPEG=>'jpg', IMAGETYPE_PNG=>'png', IMAGETYPE_WEBP=>'webp'];
    if (!$info || !isset($tipos[$info[2]]) || $info[0] > 6000 || $info[1] > 6000 || $info[0] * $info[1] > 16000000)
        throw new InvalidArgumentException('Escolha uma foto JPG, PNG ou WebP de até 16 megapixels.');
    return [$bytes, $tipos[$info[2]]];
}

function salvar_foto_perfil($foto) {
    [$bytes, $extensao] = $foto;
    $pasta = __DIR__ . '/uploads/perfis';
    if (!is_dir($pasta) && !mkdir($pasta, 0755, true) && !is_dir($pasta))
        throw new RuntimeException('Não foi possível criar a pasta de fotos.');
    $arquivo = bin2hex(random_bytes(24)) . '.' . $extensao;
    $caminho = $pasta . '/' . $arquivo;
    if (file_put_contents($caminho, $bytes, LOCK_EX) !== strlen($bytes)) {
        @unlink($caminho);
        throw new RuntimeException('Não foi possível salvar a foto.');
    }
    return [$caminho, $arquivo];
}

function url_foto_perfil($arquivo) {
    $base = getenv('PUBLIC_API_URL');
    if (!$base) {
        $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
        if (!preg_match('/^[a-zA-Z0-9.\-]+(?::[0-9]+)?$/D', $host))
            throw new RuntimeException('Configure PUBLIC_API_URL no servidor.');
        $https = !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off';
        $base = ($https ? 'https://' : 'http://') . $host . rtrim(dirname($_SERVER['SCRIPT_NAME']), '/\\');
    }
    return rtrim($base, '/') . '/foto_perfil.php?arquivo=' . $arquivo;
}
