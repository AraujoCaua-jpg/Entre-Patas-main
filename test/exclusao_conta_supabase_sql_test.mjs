import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { after, before, describe, it } from 'node:test';

const requireLocal = createRequire(resolve('.dart_tool/adocao_sql_test/package.json'));
const { PGlite } = requireLocal('@electric-sql/pglite');
const migrationPath = resolve('docs/sql/20_excluir_conta_supabase.sql');
const migration = await readFile(migrationPath, 'utf8');

const uid = '11111111-1111-4111-8111-111111111111';
const uidOutro = '22222222-2222-4222-8222-222222222222';
const uidSolicitante = '33333333-3333-4333-8333-333333333333';

async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create role service_role nologin bypassrls;
    create schema auth;
    create schema storage;
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    create table auth.users (id uuid primary key);
    create table public.cliente (
      id bigint primary key,
      auth_user_id uuid unique references auth.users(id) on delete cascade,
      ativo boolean not null default true,
      nome text not null,
      sobrenome text not null,
      email text not null unique,
      telefone text not null,
      usuario text not null unique,
      "cidadeDeResidencia" text not null,
      estado text not null,
      endereco text,
      imagem text,
      "larDeAdocao" boolean not null default false,
      questionario_pendente integer not null default 0
    );
    create table public.animal (
      id bigint primary key,
      id_cliente bigint not null references public.cliente(id),
      ativo boolean not null default true,
      status text not null,
      nome text not null,
      imagem text,
      idade integer not null default 2,
      sexo text not null default 'Fêmea'
    );
    create table public.adocao (
      id bigint generated always as identity primary key,
      data timestamptz not null default now(),
      status text not null,
      id_animal bigint not null references public.animal(id),
      id_cliente bigint not null references public.cliente(id),
      id_dono bigint not null references public.cliente(id)
    );
    create table public.questionario (
      id bigint generated always as identity primary key,
      id_cliente bigint not null unique references public.cliente(id)
    );
    create table storage.objects (
      bucket_id text not null,
      name text not null,
      owner_id text,
      primary key(bucket_id, name)
    );
    create function public._ep_adocoes_json(bigint, bigint default null)
      returns jsonb language sql stable as $$ select '[]'::jsonb $$;
    alter table public.cliente enable row level security;
    alter table public.animal enable row level security;
    alter table public.adocao enable row level security;
    alter table public.questionario enable row level security;
    insert into auth.users values ('${uid}'), ('${uidOutro}'), ('${uidSolicitante}');
    insert into public.cliente
      (id,auth_user_id,nome,sobrenome,email,telefone,usuario,"cidadeDeResidencia",estado,endereco,imagem,"larDeAdocao")
    values
      (1,'${uid}','Ana','Pessoa','ana@example.com','11999998888','ana','São Paulo','SP','Rua 1','https://storage.example/profile.png',true),
      (2,'${uidOutro}','Bruno','Dono','bruno@example.com','11888887777','bruno','Campinas','SP',null,null,false),
      (3,'${uidSolicitante}','Caio','Adotante','caio@example.com','11777776666','caio','Santos','SP',null,null,false);
    insert into public.animal(id,id_cliente,ativo,status,nome,imagem) values
      (10,1,true,'Disponível','Lua','https://storage.example/lua.png'),
      (20,2,true,'Disponível','Sol',null),
      (30,2,true,'Adotado','Estrela',null);
    insert into public.adocao(status,id_animal,id_cliente,id_dono) values
      ('Aguardando',10,3,1),
      ('Aguardando',20,1,2),
      ('Aceito',30,1,2);
    insert into public.questionario(id_cliente) values (1);
    insert into storage.objects(bucket_id,name,owner_id) values
      ('avatars','ana.png','${uid}'),
      ('animals','lua.png','${uid}'),
      ('avatars','bruno.png','${uidOutro}');
  `);
  return db;
}

describe('Exclusão de conta: SQL relacional em PostgreSQL em memória', { concurrency: false }, () => {
  let db;
  before(async () => {
    db = await fixture();
    await db.exec(migration);
  });
  after(async () => { await db?.close(); });

  it('anonimiza o perfil e preserva as referências históricas', async () => {
    await db.query('delete from auth.users where id=$1::uuid', [uid]);
    const perfil = await db.query(
      'select * from public.cliente where id=1',
    );
    assert.equal(perfil.rows.length, 1);
    assert.equal(perfil.rows[0].auth_user_id, null);
    assert.equal(perfil.rows[0].ativo, false);
    assert.equal(perfil.rows[0].nome, 'Conta');
    assert.equal(perfil.rows[0].sobrenome, 'removida');
    assert.equal(perfil.rows[0].email, `excluido+${uid}@invalid.invalid`);
    assert.equal(perfil.rows[0].telefone, '00000000001');
    assert.equal(perfil.rows[0].usuario, 'excluido_1');
    assert.equal(perfil.rows[0].endereco, null);
    assert.equal(perfil.rows[0].imagem, null);
    assert.equal(perfil.rows[0].larDeAdocao, false);
    assert.equal(perfil.rows[0].questionario_pendente, 0);

    const animais = await db.query(
      'select ativo,imagem from public.animal where id_cliente=1',
    );
    assert.deepEqual(animais.rows, [{ ativo: false, imagem: null }]);
    const pendencias = await db.query(
      "select status from public.adocao where status='Aguardando'",
    );
    assert.deepEqual(pendencias.rows, []);
    const historico = await db.query(
      "select status,id_cliente,id_dono from public.adocao where status='Aceito'",
    );
    assert.deepEqual(historico.rows, [
      { status: 'Aceito', id_cliente: 1, id_dono: 2 },
    ]);
    assert.equal(
      (await db.query('select count(*)::int as n from public.questionario'))
        .rows[0].n,
      0,
    );
    assert.equal(
      (await db.query('select count(*)::int as n from auth.users'))
        .rows[0].n,
      2,
    );
  });

  it('enfileira apenas objetos Storage pertencentes à identidade removida', async () => {
    await db.query('delete from auth.users where id=$1::uuid', [uid]);
    const fila = await db.query(
      'select user_id,bucket_id,object_name from public.ep_account_storage_cleanup order by bucket_id',
    );
    assert.deepEqual(fila.rows, [
      { user_id: uid, bucket_id: 'animals', object_name: 'lua.png' },
      { user_id: uid, bucket_id: 'avatars', object_name: 'ana.png' },
    ]);
    assert.equal(
      (await db.query('select count(*)::int as n from storage.objects'))
        .rows[0].n,
      3,
    );
  });
});
