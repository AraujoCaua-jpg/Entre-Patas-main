import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { after, afterEach, before, beforeEach, describe, it } from 'node:test';

const requireLocal = createRequire(resolve('.dart_tool/adocao_sql_test/package.json'));
const { PGlite } = requireLocal('@electric-sql/pglite');
const migrationPath = resolve('docs/sql/10_migrar_adocoes_supabase.sql');
const migration = await readFile(migrationPath, 'utf8');

// Executa o SQL de produção em PostgreSQL WASM, sem rede ou dados reais.
// PGlite oferece uma conexão: estes testes NÃO demonstram concorrência entre
// conexões, nem confirmam o esquema, as políticas ou os grants do Supabase real.
const uid = Object.fromEntries([1, 2, 3, 4, 5].map((id) => [
  id, `${String(id).repeat(8)}-${String(id).repeat(4)}-4${String(id).repeat(3)}-8${String(id).repeat(3)}-${String(id).repeat(12)}`,
]));

async function fixture({ enums = false, semFk = false, duplicados = false } = {}) {
  const db = new PGlite();
  const animalType = enums ? 'public.fixture_animal_status' : 'text';
  const adocaoType = enums ? 'public.fixture_adocao_status' : 'text';
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema auth to anon, authenticated;
    grant execute on function auth.uid() to anon, authenticated;
    ${enums ? `
      create type public.fixture_animal_status as enum ('Disponível','Adotado','Reservado');
      create type public.fixture_adocao_status as enum ('Aguardando','Aceito','Recusado','Cancelado');
    ` : ''}
    create table public.cliente (
      id bigint primary key,
      auth_user_id uuid unique,
      ativo boolean not null default true,
      nome text not null,
      sobrenome text not null default 'Teste',
      email text not null,
      telefone text not null default '11999998888',
      estado text not null default 'SP',
      "cidadeDeResidencia" text not null default 'Cidade de Teste'
    );
    create table public.animal (
      id bigint primary key,
      id_cliente bigint not null references public.cliente(id),
      ativo boolean not null default true,
      status ${animalType} not null default 'Disponível',
      nome text not null,
      imagem text,
      idade integer not null default 2,
      sexo text not null default 'Fêmea'
    );
    create table public.adocao (
      id bigint generated always as identity primary key,
      data timestamptz not null default now(),
      status ${adocaoType} not null default 'Aguardando',
      id_animal bigint not null ${semFk ? '' : 'references public.animal(id)'},
      id_cliente bigint not null references public.cliente(id),
      id_dono bigint not null references public.cliente(id)
    );
    alter table public.cliente enable row level security;
    alter table public.animal enable row level security;
    alter table public.adocao enable row level security;
    create policy fixture_cliente_proprio on public.cliente for select to authenticated
      using (auth_user_id = auth.uid());
    create policy fixture_animal_proprio on public.animal for all to authenticated
      using (id_cliente = (select id from public.cliente where auth_user_id=auth.uid()))
      with check (id_cliente = (select id from public.cliente where auth_user_id=auth.uid()));
    grant usage on schema public to anon, authenticated;
    grant select on public.cliente to authenticated;
    grant select, insert, update, delete on public.animal to authenticated;
    -- A instalação precisa revogar estes grants diretos preexistentes.
    grant select, insert, update, delete on public.adocao to anon, authenticated;
    grant select (status), update (status) on public.adocao to authenticated;
    insert into public.cliente (id,auth_user_id,ativo,nome,email) values
      (1,'${uid[1]}',true,'Adotante A','a@example.com'),
      (2,'${uid[2]}',true,'Responsável','dono@example.com'),
      (3,'${uid[3]}',true,'Adotante B','b@example.com'),
      (4,'${uid[4]}',true,'Pessoa externa','fora@example.com'),
      (5,'${uid[5]}',false,'Pessoa inativa','inativo@example.com');
    insert into public.animal (id,id_cliente,ativo,status,nome,imagem) values
      (10,2,true,'Disponível','Lua','https://example.com/lua.png'),
      (11,2,false,'Disponível','Inativo',null),
      (12,2,true,'Adotado','Adotado',null),
      (13,2,true,'Reservado','Indisponível',null),
      (14,5,true,'Disponível','Dono inativo',null),
      (15,1,true,'Disponível','Meu animal',null);
    ${duplicados ? `
      insert into public.adocao (status,id_animal,id_cliente,id_dono)
      values ('Aguardando',10,1,2),('Aguardando',10,1,2);
    ` : ''}
  `);
  return db;
}

async function actor(db, id, role = 'authenticated') {
  assert.ok(['authenticated', 'anon'].includes(role));
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub', $1, true)", [id == null ? '' : uid[id]]);
  await db.exec(`set local role ${role}`);
}

async function admin(db) {
  await db.exec('reset role');
}

async function rpc(db, name, args = []) {
  const names = new Set([
    'listar_minhas_adocoes', 'buscar_minha_adocao', 'solicitar_adocao', 'responder_adocao',
  ]);
  assert.ok(names.has(name));
  const params = args.map((_, index) => `$${index + 1}`).join(',');
  const result = await db.query(`select public.${name}(${params}) as resultado`, args);
  return result.rows[0].resultado;
}

async function fails(db, operation, code, message) {
  await db.exec('savepoint expected_failure');
  let error;
  try {
    await operation();
  } catch (caught) {
    error = caught;
  }
  await db.exec('rollback to savepoint expected_failure');
  await db.exec('release savepoint expected_failure');
  assert.ok(error, 'A operação deveria ter sido recusada pelo banco.');
  assert.equal(error.code, code, error.message);
  if (message) assert.match(error.message, message);
}

describe('Adoções: SQL real em PostgreSQL em memória', { concurrency: false }, () => {
  let db;
  before(async () => {
    db = await fixture();
    await db.exec(migration);
  });
  after(async () => { await db?.close(); });
  beforeEach(async () => { await db.exec('begin'); });
  afterEach(async () => { await db.exec('rollback'); });

  it('exige Auth e perfil ativo mesmo com permissão de executar RPC', async () => {
    await actor(db, null);
    await fails(db, () => rpc(db, 'listar_minhas_adocoes'), 'PT401');
    await actor(db, 5);
    await fails(db, () => rpc(db, 'solicitar_adocao', [10]), 'PT403');
  });

  it('cria Aguardando com adotante/dono reais e DTO de detalhes', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    assert.equal(request.status, 'Aguardando');
    assert.equal(request.id_animal, 10);
    assert.equal(request.id_cliente, 1);
    assert.equal(request.id_dono, 2);
    assert.equal(request.animal_nome, 'Lua');
    assert.equal(request.animal_imagem, 'https://example.com/lua.png');
    assert.equal(request.cidadeDeResidencia, 'Cidade de Teste');
    assert.equal(request.solicitante_email, 'a@example.com');
    assert.ok(Number.isFinite(Date.parse(request.data)));
    assert.equal(request.auth_user_id, undefined);
    assert.equal(request.senha, undefined);
  });

  it('recusa autossolicitação', async () => {
    await actor(db, 1);
    await fails(db, () => rpc(db, 'solicitar_adocao', [15]), 'PT400', /próprio animal/);
  });

  for (const [id, reason] of [
    [11, 'animal inativo'], [12, 'animal adotado'],
    [13, 'animal indisponível'], [14, 'responsável inativo'],
  ]) {
    it(`recusa solicitação para ${reason}`, async () => {
      await actor(db, 1);
      await fails(db, () => rpc(db, 'solicitar_adocao', [id]), 'PT409', /não está disponível/);
    });
  }

  it('recusa IDs inválidos, animal ausente e ações desconhecidas', async () => {
    await actor(db, 1);
    await fails(db, () => rpc(db, 'solicitar_adocao', [0]), 'PT400');
    await fails(db, () => rpc(db, 'solicitar_adocao', [9999]), 'PT404');
    await fails(db, () => rpc(db, 'responder_adocao', [1, 'inventado']), 'PT400');
  });

  it('bloqueia Aguardando duplicado sem excluir o pedido anterior', async () => {
    await actor(db, 1);
    const first = await rpc(db, 'solicitar_adocao', [10]);
    await fails(db, () => rpc(db, 'solicitar_adocao', [10]), 'PT409', /em andamento/);
    const list = await rpc(db, 'listar_minhas_adocoes');
    assert.equal(list.length, 1);
    assert.equal(list[0].id, first.id);
  });

  it('adotante cancela e pode solicitar novamente preservando o histórico', async () => {
    await actor(db, 1);
    const first = await rpc(db, 'solicitar_adocao', [10]);
    const canceled = await rpc(db, 'responder_adocao', [first.id, 'cancelar']);
    assert.equal(canceled.status, 'Cancelado');
    const next = await rpc(db, 'solicitar_adocao', [10]);
    assert.notEqual(next.id, first.id);
    const list = await rpc(db, 'listar_minhas_adocoes');
    assert.deepEqual(list.map((request) => request.status), ['Aguardando', 'Cancelado']);
  });

  it('responsável recusa e adotante pode solicitar novamente', async () => {
    await actor(db, 1);
    const first = await rpc(db, 'solicitar_adocao', [10]);
    await actor(db, 2);
    assert.equal((await rpc(db, 'responder_adocao', [first.id, 'recusar'])).status, 'Recusado');
    await actor(db, 1);
    assert.equal((await rpc(db, 'solicitar_adocao', [10])).status, 'Aguardando');
    assert.equal((await rpc(db, 'listar_minhas_adocoes')).length, 2);
  });

  it('adotante não decide e responsável não cancela pelo adotante', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    for (const action of ['aceitar', 'recusar']) {
      await fails(db, () => rpc(db, 'responder_adocao', [request.id, action]), 'PT403');
    }
    await actor(db, 2);
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'cancelar']), 'PT403');
  });

  it('somente as duas partes listam/consultam detalhes de contato do pedido', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    await actor(db, 2);
    assert.equal((await rpc(db, 'listar_minhas_adocoes'))[0].id, request.id);
    assert.equal((await rpc(db, 'buscar_minha_adocao', [request.id])).solicitante_email, 'a@example.com');
    await actor(db, 4);
    assert.deepEqual(await rpc(db, 'listar_minhas_adocoes'), []);
    await fails(db, () => rpc(db, 'buscar_minha_adocao', [request.id]), 'PT404');
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'aceitar']), 'PT404');
  });

  it('aprovação marca Adotado e recusa todas as outras Aguardando atomicamente', async () => {
    await actor(db, 1);
    const first = await rpc(db, 'solicitar_adocao', [10]);
    await actor(db, 3);
    const second = await rpc(db, 'solicitar_adocao', [10]);
    await actor(db, 2);
    assert.equal((await rpc(db, 'responder_adocao', [first.id, 'aceitar'])).status, 'Aceito');
    assert.equal((await rpc(db, 'buscar_minha_adocao', [second.id])).status, 'Recusado');
    await fails(db, () => rpc(db, 'responder_adocao', [second.id, 'aceitar']), 'PT409');
    await admin(db);
    assert.equal((await db.query('select status from public.animal where id=10')).rows[0].status, 'Adotado');
    assert.equal((await db.query("select count(*)::int as total from public.adocao where id_animal=10 and status='Aceito'")).rows[0].total, 1);
    await actor(db, 1);
    await fails(db, () => rpc(db, 'solicitar_adocao', [10]), 'PT409');
  });

  it('não altera novamente uma solicitação finalizada', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    await rpc(db, 'responder_adocao', [request.id, 'cancelar']);
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'cancelar']), 'PT409');
    await actor(db, 2);
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'recusar']), 'PT409');
  });

  it('não aprova se o adotante tornou-se inativo', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    await admin(db);
    await db.exec('update public.cliente set ativo=false where id=1');
    await actor(db, 2);
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'aceitar']), 'PT409');
  });

  it('responsável antigo não decide depois da transferência do animal', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    await admin(db);
    await db.exec('update public.animal set id_cliente=3 where id=10');
    await actor(db, 2);
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'aceitar']), 'PT403');
    await actor(db, 3);
    await fails(db, () => rpc(db, 'responder_adocao', [request.id, 'aceitar']), 'PT404');
  });

  it('falha posterior reverte animal e outros pedidos, sem aprovação parcial', async () => {
    await actor(db, 1);
    const first = await rpc(db, 'solicitar_adocao', [10]);
    await actor(db, 3);
    await rpc(db, 'solicitar_adocao', [10]);
    await admin(db);
    await db.exec(`
      create function public.fixture_falhar_aceite() returns trigger language plpgsql as $$
      begin
        if new.status::text='Aceito' then raise exception 'Falha de escrita simulada'; end if;
        return new;
      end;
      $$;
      create trigger fixture_falhar_aceite before update on public.adocao
      for each row execute function public.fixture_falhar_aceite();
    `);
    await actor(db, 2);
    await fails(db, () => rpc(db, 'responder_adocao', [first.id, 'aceitar']), 'P0001');
    assert.deepEqual((await rpc(db, 'listar_minhas_adocoes')).map((request) => request.status), ['Aguardando', 'Aguardando']);
    await admin(db);
    assert.equal((await db.query('select status from public.animal where id=10')).rows[0].status, 'Disponível');
  });

  it('bloqueia DML e leitura direta de adocao, inclusive grants de coluna antigos', async () => {
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    for (const sql of [
      'select * from public.adocao',
      'select status from public.adocao',
      "insert into public.adocao(id_animal,id_cliente,id_dono) values (10,1,2)",
      `update public.adocao set status='Aceito' where id=${request.id}`,
      `delete from public.adocao where id=${request.id}`,
    ]) {
      await fails(db, () => db.query(sql), '42501');
    }
  });

  it('bloqueia status animal direto sem impedir edição dos demais campos próprios', async () => {
    await actor(db, 2);
    await fails(db, () => db.query("update public.animal set status='Adotado' where id=10"), 'PT403');
    await fails(db, () => db.query("insert into public.animal(id,id_cliente,status,nome) values (90,2,'Adotado','Forjado')"), 'PT403');
    await db.query("update public.animal set nome='Lua editada' where id=10");
    assert.equal((await db.query('select nome from public.animal where id=10')).rows[0].nome, 'Lua editada');
    await db.query("insert into public.animal(id,id_cliente,status,nome) values (91,2,'Disponível','Novo')");
  });

  it('anon não executa RPC e helpers não são expostos para perfis externos', async () => {
    await actor(db, null, 'anon');
    await fails(db, () => rpc(db, 'listar_minhas_adocoes'), '42501');
    await actor(db, 1);
    for (const sql of [
      'select public._ep_adocao_cliente_atual()',
      'select public._ep_adocoes_json(2,null)',
    ]) await fails(db, () => db.query(sql), '42501');
    await admin(db);
    const helper = await db.query("select has_function_privilege('authenticated', 'public._ep_proteger_status_adocao_animal()', 'EXECUTE') as permitido");
    assert.equal(helper.rows[0].permitido, false);
  });

  it('índices parciais impedem dois ativos por par e duas aprovações por animal', async () => {
    await admin(db);
    await db.query("insert into public.adocao(status,id_animal,id_cliente,id_dono) values ('Aguardando',10,1,2)");
    await fails(db, () => db.query("insert into public.adocao(status,id_animal,id_cliente,id_dono) values ('Aguardando',10,1,2)"), '23505');
    await db.query("update public.adocao set status='Aceito' where id_animal=10");
    await fails(db, () => db.query("insert into public.adocao(status,id_animal,id_cliente,id_dono) values ('Aceito',10,3,2)"), '23505');
    await fails(db, () => db.query("insert into public.adocao(status,id_animal,id_cliente,id_dono) values ('Aguardando',10,1,2)"), '23505');
  });
});

it('migração funciona com ENUMs existentes que contêm os estados exigidos', async () => {
  const db = await fixture({ enums: true });
  try {
    await db.exec(migration);
    await db.exec('begin');
    await actor(db, 1);
    const request = await rpc(db, 'solicitar_adocao', [10]);
    await actor(db, 2);
    assert.equal((await rpc(db, 'responder_adocao', [request.id, 'aceitar'])).status, 'Aceito');
    await db.exec('rollback');
  } finally { await db.close(); }
});

it('migração aborta sem instalar funções quando a FK necessária está ausente', async () => {
  const db = await fixture({ semFk: true });
  try {
    await assert.rejects(() => db.exec(migration), /FK validada/);
    await db.exec('rollback');
    assert.equal((await db.query("select to_regprocedure('public.solicitar_adocao(bigint)') as funcao")).rows[0].funcao, null);
    assert.equal((await db.query('select count(*)::int as total from public.cliente')).rows[0].total, 5);
  } finally { await db.close(); }
});

it('histórico duplicado impede instalação sem apagar registros existentes', async () => {
  const db = await fixture({ duplicados: true });
  try {
    await assert.rejects(() => db.exec(migration), /duplicados/);
    await db.exec('rollback');
    assert.equal((await db.query('select count(*)::int as total from public.adocao')).rows[0].total, 2);
    assert.equal((await db.query("select to_regclass('public.ep_adocao_em_andamento_unica') as indice")).rows[0].indice, null);
  } finally { await db.close(); }
});

it('reaplicação é recusada sem modificar a instalação anterior', async () => {
  const db = await fixture();
  try {
    await db.exec(migration);
    await assert.rejects(() => db.exec(migration), /já existem/);
    await db.exec('rollback');
    const check = await db.query("select to_regprocedure('public.solicitar_adocao(bigint)') is not null as existe");
    assert.equal(check.rows[0].existe, true);
    assert.equal((await db.query('select count(*)::int as total from public.animal')).rows[0].total, 6);
  } finally { await db.close(); }
});
