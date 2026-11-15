import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const onlineUrl = 'https://cyaxnaflvnjnpryryorr.supabase.co';

export function productionConfig(defaults, env = {}) {
  const url = env.SUPABASE_URL ?? defaults.SUPABASE_URL;
  const key = env.SUPABASE_PUBLISHABLE_KEY ?? defaults.SUPABASE_PUBLISHABLE_KEY;
  if (url !== onlineUrl) {
    throw new Error('O build de produção exige o Supabase online do Entre Patas.');
  }
  if (typeof key !== 'string' || !/^sb_publishable_[A-Za-z0-9_-]+$/.test(key)) {
    throw new Error('Use somente uma chave pública publishable no Flutter Web.');
  }
  // Não propaga outras variáveis do ambiente para o bundle.
  return { SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: key };
}

export function verifyToolchain(actual, expected) {
  if (actual.frameworkVersion !== expected.flutterVersion ||
      actual.frameworkRevision !== expected.flutterRevision) {
    throw new Error(`Use Flutter ${expected.flutterVersion}, na revisão fixada em config/toolchain.json.`);
  }
}

function execute(program, args, capture = false) {
  if (process.platform === 'win32' && program === 'flutter') {
    // O Flutter é um .bat no Windows. Só os argumentos internos e fixos abaixo
    // podem formar a linha do cmd; valores de configuração ficam no JSON.
    if (args.some((arg) => !/^[A-Za-z0-9_./=:-]+$/.test(arg))) {
      throw new Error('Argumento de build inválido.');
    }
    program = 'cmd.exe';
    args = ['/d', '/s', '/c', `flutter ${args.join(' ')}`];
  }
  return spawnSync(program, args, {
    cwd: root,
    encoding: 'utf8',
    stdio: capture ? 'pipe' : 'inherit',
    env: { ...process.env, CI: 'true', FLUTTER_SUPPRESS_ANALYTICS: 'true' },
  });
}

function command(program, args, capture = false) {
  const result = execute(program, args, capture);
  if (result.error || result.status !== 0) {
    throw new Error(`Falha ao executar ${program}. Verifique o SDK e a saída do comando.`);
  }
  return result.stdout ?? '';
}

export function build() {
  const defaults = JSON.parse(readFileSync(join(root, 'config/production.json'), 'utf8'));
  const expected = JSON.parse(readFileSync(join(root, 'config/toolchain.json'), 'utf8'));
  const config = productionConfig(defaults, process.env);

  // A Vercel não fornece Flutter por padrão. Instala somente o SDK fixado,
  // dentro de um cache ignorado, sem modificar o backend.
  const available = execute('flutter', ['--version', '--machine'], true);
  if (available.error || available.status !== 0) {
    const sdk = join(root, '.vercel', 'flutter');
    if (!existsSync(sdk)) {
      mkdirSync(dirname(sdk), { recursive: true });
      command('git', ['clone', '--depth', '1', '--branch', expected.flutterVersion,
        'https://github.com/flutter/flutter.git', sdk]);
    }
    process.env.PATH = `${join(sdk, 'bin')}${process.platform === 'win32' ? ';' : ':'}${process.env.PATH}`;
  }
  const versionOutput = command('flutter', ['--version', '--machine'], true);
  const actual = JSON.parse(versionOutput.slice(versionOutput.indexOf('{')));
  verifyToolchain(actual, expected);

  mkdirSync(join(root, '.dart_tool'), { recursive: true });
  writeFileSync(join(root, '.dart_tool', 'production-build.json'), `${JSON.stringify(config)}\n`);
  command('flutter', ['pub', 'get', '--enforce-lockfile']);
  command('flutter', ['build', 'web', '--release', '--no-pub',
    '--dart-define-from-file=.dart_tool/production-build.json']);
  const bundle = readFileSync(join(root, 'build/web/main.dart.js'), 'utf8');
  if (!bundle.includes(onlineUrl) || bundle.includes('http://127.0.0.1:54321') ||
      bundle.includes('http://localhost:54321') || /sb_secret_[A-Za-z0-9_-]+/.test(bundle)) {
    throw new Error('O bundle não passou na conferência do endpoint/chave pública. Não publicar.');
  }
  console.log('Build Web verificado: Supabase online e configuração pública. Nenhum deploy executado.');
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  try {
    build();
  } catch (error) {
    // As mensagens de validação não incluem o valor da chave/configuração.
    console.error(error.message);
    process.exitCode = 1;
  }
}
