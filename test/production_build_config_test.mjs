import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';
import { productionConfig, verifyToolchain } from '../scripts/build_web.mjs';

const defaults = JSON.parse(readFileSync(new URL('../config/production.json', import.meta.url), 'utf8'));
const expected = JSON.parse(readFileSync(new URL('../config/toolchain.json', import.meta.url), 'utf8'));

test('configuração pública reproduzível e defaults do Flutter correspondem', () => {
  const main = readFileSync(new URL('../lib/main.dart', import.meta.url), 'utf8');
  const actual = productionConfig(defaults);
  assert.ok(main.includes(`defaultValue: '${actual.SUPABASE_URL}'`));
  assert.ok(main.includes(`defaultValue: '${actual.SUPABASE_PUBLISHABLE_KEY}'`));
});

test('configuração de QA local não pode ser publicada por engano', () => {
  for (const url of ['http://127.0.0.1:54321', 'http://localhost:54321', 'https://outro.supabase.co']) {
    assert.throws(() => productionConfig(defaults, { SUPABASE_URL: url }), /online/);
  }
});

test('chaves administrativas, JWTs legados e valores vazios são rejeitados', () => {
  for (const key of ['sb_secret_ficticio', 'service_role_ficticio', 'eyJficticio.token.value', '']) {
    assert.throws(() => productionConfig(defaults, { SUPABASE_PUBLISHABLE_KEY: key }), /pública/);
  }
});

test('variáveis privadas não entram nos dart-defines', () => {
  const actual = productionConfig(defaults, { SUPABASE_SERVICE_ROLE_KEY: 'ficticio', PASSWORD: 'ficticio' });
  assert.deepEqual(Object.keys(actual).sort(), ['SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_URL']);
});

test('SDK divergente não é aceito silenciosamente no build', () => {
  assert.doesNotThrow(() => verifyToolchain({ frameworkVersion: expected.flutterVersion,
    frameworkRevision: expected.flutterRevision }, expected));
  assert.throws(() => verifyToolchain({ frameworkVersion: '3.49.0', frameworkRevision: 'outro' }, expected));
});
