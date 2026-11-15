import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { after, before, describe, it } from 'node:test';

const requireLocal = createRequire(resolve('.dart_tool/adocao_sql_test/package.json'));
const { PGlite } = requireLocal('@electric-sql/pglite');
const migration = await readFile(
  resolve('docs/sql/05_vincular_perfil_auth_supabase.sql'),
  'utf8',
);

const uid = '11111111-1111-4111-8111-111111111111';

async function fixture({ includeProfileTrigger = true } = {}) {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    create table auth.users (
      id uuid primary key,
      email text,
      raw_user_meta_data jsonb
    );
    create table public.cliente (
      id bigint generated always as identity primary key,
      auth_user_id uuid,
      ativo boolean not null,
      nome text not null,
      sobrenome text not null,
      email text not null unique,
      telefone text not null,
      usuario text not null unique,
      estado text not null,
      "cidadeDeResidencia" text not null,
      endereco text,
      imagem text,
      "larDeAdocao" boolean not null,
      questionario_pendente integer not null
    );
  `);
  if (includeProfileTrigger) {
    await db.exec(`
      create schema private;
      create table private.trigger_calls (user_id uuid primary key);
      create function private.criar_cliente_entre_patas()
      returns trigger
      language plpgsql
      security definer
      set search_path = ''
      as $function$
      begin
        insert into private.trigger_calls values (new.id);
        return new;
      end;
      $function$;
      create trigger on_entre_patas_auth_user_created
      after insert on auth.users
      for each row execute function private.criar_cliente_entre_patas();
    `);
  }
  return db;
}

describe('Vínculo perfil/Auth: SQL em PostgreSQL em memória', { concurrency: false }, () => {
  let db;
  before(async () => {
    db = await fixture();
    await db.exec(migration);
  });
  after(async () => { await db?.close(); });

  it('preserva o único trigger de cadastro existente e não instala outro', async () => {
    const triggers = await db.query(`
      select t.tgname, n.nspname as function_schema, p.proname,
             t.tgtype, t.tgenabled
      from pg_catalog.pg_trigger t
      join pg_catalog.pg_proc p on p.oid=t.tgfoid
      join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      where t.tgrelid='auth.users'::regclass and not t.tgisinternal
        and (t.tgtype & 4) <> 0
      order by t.tgname
    `);
    assert.deepEqual(triggers.rows, [{
      tgname: 'on_entre_patas_auth_user_created',
      function_schema: 'private',
      proname: 'criar_cliente_entre_patas',
      tgtype: 5,
      tgenabled: 'O',
    }]);
    assert.equal(
      (await db.query(
        `select to_regprocedure('public.ep_criar_perfil_auth()') as profile_function`,
      )).rows[0].profile_function,
      null,
    );
  });

  it('mantém o trigger existente ativo e sincroniza e-mail confirmado', async () => {
    await db.query(
      `insert into auth.users(id,email,raw_user_meta_data)
       values ($1::uuid,'ANA@EXAMPLE.COM','{}'::jsonb)`,
      [uid],
    );
    assert.equal(
      (await db.query('select count(*)::int as n from private.trigger_calls'))
        .rows[0].n,
      1,
    );

    await db.query(
      `insert into public.cliente (
         auth_user_id, ativo, nome, sobrenome, email, telefone, usuario,
         estado, "cidadeDeResidencia", "larDeAdocao", questionario_pendente
       ) values ($1::uuid,true,'Ana','Silva','ana@example.com','11999998888',
                 'ana_silva','SP','São Paulo',false,1)`,
      [uid],
    );
    await db.query(
      'update auth.users set email=$2 where id=$1::uuid',
      [uid, 'ana.nova@example.com'],
    );
    assert.equal(
      (await db.query(
        'select email from public.cliente where auth_user_id=$1::uuid',
        [uid],
      )).rows[0].email,
      'ana.nova@example.com',
    );
  });

  it('aborta sem trigger preexistente e não deixa mudanças parciais', async () => {
    const dbWithoutTrigger = await fixture({ includeProfileTrigger: false });
    try {
      await assert.rejects(
        dbWithoutTrigger.exec(migration),
        /trigger ativo AFTER INSERT private\.criar_cliente_entre_patas\(\) não foi validado/,
      );
      await dbWithoutTrigger.exec('rollback');
      assert.equal(
        (await dbWithoutTrigger.query(
          `select to_regclass('public.ep_cliente_auth_user_id_unica') as idx`,
        )).rows[0].idx,
        null,
      );
      assert.equal(
        (await dbWithoutTrigger.query(
          `select to_regprocedure('public.ep_sincronizar_email_auth()') as sync_function`,
        )).rows[0].sync_function,
        null,
      );
    } finally {
      await dbWithoutTrigger.close();
    }
  });
});
