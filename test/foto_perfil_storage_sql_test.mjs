import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { test } from 'node:test';

const requireLocal = createRequire(resolve('.dart_tool/adocao_sql_test/package.json'));
const { PGlite } = requireLocal('@electric-sql/pglite');
const migration = await readFile('docs/sql/40_configurar_fotos_perfil_storage.sql', 'utf8');
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';

test('Fotos: proposta SQL em PostgreSQL isolado, sem Storage remoto', async (t) => {
  const db = new PGlite();
  try {
    await db.exec(`
      create role anon nologin;
      create role authenticated nologin;
      create schema auth;
      create schema storage;
      create function auth.uid() returns uuid language sql stable as
        $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
      create function storage.foldername(name text) returns text[] language sql immutable as
        $$ select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1)-1] $$;
      create table public.cliente (id int primary key, auth_user_id uuid, ativo boolean);
      insert into public.cliente values (1, '${a}', true), (2, '${b}', false);
      create table storage.buckets (id text primary key, name text, public boolean,
        file_size_limit bigint, allowed_mime_types text[]);
      create table storage.objects (name text primary key, bucket_id text, owner_id text);
      alter table storage.objects enable row level security;
      grant usage on schema storage, auth to anon, authenticated;
      grant select on public.cliente to authenticated;
      grant select, insert, delete on storage.objects to authenticated;
    `);
    await db.exec(migration);
    async function como(role, uid, sql) {
      await db.exec('begin');
      try {
        await db.exec(`set local role ${role}; select set_config('request.jwt.claim.sub', '${uid}', true);`);
        const result = await db.query(sql);
        await db.exec('commit');
        return result;
      } catch (error) {
        await db.exec('rollback');
        throw error;
      }
    }
    await t.test('bucket é público com limite de 2 MB e tipos de imagem permitidos', async () => {
      const { rows: [bucket] } = await db.query('select * from storage.buckets');
      assert.equal(bucket.public, true);
      assert.equal(Number(bucket.file_size_limit), 2097152);
      assert.deepEqual(bucket.allowed_mime_types, ['image/jpeg', 'image/png', 'image/webp']);
    });
    await t.test('perfil ativo envia na própria pasta', async () => {
      await como('authenticated', a, `insert into storage.objects values ('${a}/foto.png', 'avatars', '${a}')`);
      assert.equal((await como('authenticated', a, 'select * from storage.objects')).rows.length, 1);
    });
    await t.test('não envia em pasta alheia nem em outro bucket', async () => {
      await assert.rejects(como('authenticated', a, `insert into storage.objects values ('${b}/foto.png', 'avatars', '${a}')`));
      await assert.rejects(como('authenticated', a, `insert into storage.objects values ('${a}/forjado.png', 'avatars', '${b}')`));
      await assert.rejects(como('authenticated', a, `insert into storage.objects values ('${a}/outra.png', 'privado', '${a}')`));
    });
    await t.test('anônimo e perfil inativo não enviam', async () => {
      await assert.rejects(como('anon', '', `insert into storage.objects values ('foto.png', 'avatars', null)`));
      await assert.rejects(como('authenticated', b, `insert into storage.objects values ('${b}/foto.png', 'avatars', '${b}')`));
    });
    await t.test('outra conta não lista nem remove o arquivo do proprietário', async () => {
      assert.equal((await como('authenticated', b, 'select * from storage.objects')).rows.length, 0);
      await como('authenticated', b, 'delete from storage.objects');
      assert.equal((await db.query('select * from storage.objects')).rows.length, 1);
    });
    await t.test('proprietário consegue limpar o próprio envio', async () => {
      await como('authenticated', a, 'delete from storage.objects');
      assert.equal((await db.query('select * from storage.objects')).rows.length, 0);
    });
    await t.test('bucket existente impede reaplicação sem alteração parcial', async () => {
      const antes = await db.query('select * from storage.buckets');
      await assert.rejects(db.exec(migration), /já existe/);
      await db.exec('rollback');
      assert.deepEqual((await db.query('select * from storage.buckets')).rows, antes.rows);
    });
  } finally {
    await db.close();
  }
});
