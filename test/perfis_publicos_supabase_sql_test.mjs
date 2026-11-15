import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { after, afterEach, before, beforeEach, describe, it } from 'node:test';

const requireLocal = createRequire(resolve('.dart_tool/adocao_sql_test/package.json'));
const { PGlite } = requireLocal('@electric-sql/pglite');
const [original, fix, search, adoption] = await Promise.all([
  readFile('test/support/perfis_publicos_producao.sql', 'utf8'),
  readFile('docs/sql/12_corrigir_perfis_publicos_supabase.sql', 'utf8'),
  readFile('docs/sql/30_migrar_pesquisa_publica_supabase.sql', 'utf8'),
  readFile('docs/sql/10_migrar_adocoes_supabase.sql', 'utf8'),
]);
const callerUid = '11111111-1111-4111-8111-111111111111';
const ownerUid = '22222222-2222-4222-8222-222222222222';

// PostgreSQL WASM em memória. Não cria conexão, servidor ou chamadas de rede.
async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon nologin;
    create role authenticated nologin;
    create schema auth;
    create schema private;
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    grant usage on schema auth,private to anon,authenticated;
    create table public.cliente (
      id integer primary key, auth_user_id uuid unique, ativo boolean not null default true,
      nome text, sobrenome text, usuario text, imagem text,
      "cidadeDeResidencia" text, estado text, "larDeAdocao" boolean,
      email text, telefone text, endereco text
    );
    create table public.animal (
      id integer primary key, id_cliente integer references public.cliente(id),
      ativo boolean default true, status text default 'Disponível',
      nome text, idade integer, imagem text, tipo text, descricao text,
      sexo text, energia text, porte text, convivencia text, carencia text,
      vacinado text, castrado text
    );
    create table public.adocao (
      id integer generated always as identity primary key,
      data timestamp default now(), status text default 'Aguardando',
      id_animal integer references public.animal(id),
      id_cliente integer references public.cliente(id),
      id_dono integer references public.cliente(id)
    );
    alter table public.cliente enable row level security;
    alter table public.animal enable row level security;
    insert into public.cliente values
      (1,'${callerUid}',true,'Ana','Pessoa','ana',null,'Cidade','SP',false,'ana@example.com','11999998888','Privado A'),
      (2,'${ownerUid}',true,'Lar','Responsável','lar',null,'Cidade','SP',true,'lar@example.com','11999997777','Privado B'),
      (3,null,false,'Inativo','Pessoa','inativo',null,'Cidade','SP',false,'inativo@example.com','11999996666','Privado C');
    insert into public.animal(id,id_cliente,nome,tipo) values (10,2,'Lua','Gato');
  `);
  await db.exec(original);
  for (const signature of [
    'private.resumo_responsavel(integer)', 'private.detalhe_publico_responsavel(integer)',
    'public.buscar_resumo_responsavel(integer)', 'public.buscar_perfil_publico(integer)',
    'public.buscar_clientes_publicos(text)',
  ]) {
    await db.exec(`revoke all on function ${signature} from public,anon,authenticated;
      grant execute on function ${signature} to authenticated;`);
  }
  return db;
}

async function actor(db, uid = callerUid, role = 'authenticated') {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [uid ?? '']);
  await db.exec(`set role ${role}`);
}

async function admin(db) { await db.exec('reset role'); }
async function fails(db, call, expected) {
  await db.exec('savepoint expected_failure');
  try { await assert.rejects(call, expected); }
  finally {
    await db.exec('rollback to savepoint expected_failure');
    await db.exec('release savepoint expected_failure');
  }
}
async function profile(db, id = 2) {
  return (await db.query('select * from public.buscar_perfil_publico($1::integer)', [id])).rows;
}
async function summary(db, id = 2) {
  return (await db.query('select * from public.buscar_resumo_responsavel($1::integer)', [id])).rows;
}
async function wrappers(db) {
  return (await db.query(`select oid::regprocedure::text as signature,pg_get_functiondef(oid) as definition
    from pg_proc where oid in ('public.buscar_perfil_publico(integer)'::regprocedure,
      'public.buscar_resumo_responsavel(integer)'::regprocedure) order by oid::regprocedure::text`)).rows;
}

async function legacy(db, { id = 4, active = true, petStatus = null, shelter = false } = {}) {
  await db.query(`insert into public.cliente
    (id,auth_user_id,ativo,nome,sobrenome,usuario,imagem,"cidadeDeResidencia",estado,"larDeAdocao",email,telefone,endereco)
    values ($1,null,$2,'Legado','Pessoa',$3,null,'Cidade','SP',$4,$5,'11999995555','Contato privado fictício')`,
  [id, active, `legado${id}`, shelter, `legado${id}@example.com`]);
  if (petStatus !== null) {
    await db.query(`insert into public.animal(id,id_cliente,nome,tipo,status)
      values ($1,$2,'Animal legado','Gato',$3)`, [100 + id, id, petStatus]);
  }
}

async function storedState(db) {
  return {
    clients: (await db.query('select * from public.cliente order by id')).rows,
    pets: (await db.query('select * from public.animal order by id')).rows,
  };
}

function assertPublicOnly(row, id) {
  assert.equal(row.id, id);
  for (const field of ['email', 'telefone', 'endereco', 'auth_user_id']) {
    assert.equal(Object.hasOwn(row, field), false);
  }
}

it('reproduz desaparecimento após único animal Adotado e corrige sem alterar wrappers', async () => {
  const db = await fixture();
  try {
    const before = await wrappers(db);
    await actor(db);
    assert.equal((await profile(db)).length, 1);
    await admin(db);
    await db.exec("update public.animal set status='Adotado' where id=10");
    await actor(db);
    assert.deepEqual(await profile(db), []);
    assert.deepEqual(await summary(db), []);
    await admin(db);
    await db.exec(fix);
    assert.deepEqual(await wrappers(db), before);
    await actor(db);
    assert.equal((await profile(db))[0].id, 2);
    assert.equal((await summary(db))[0].id, 2);
  } finally { await db.close(); }
});

for (const [label, petStatus, shelter] of [
  ['sem qualquer animal', null, false], ['somente com animal Adotado', 'Adotado', true],
]) {
  it(`perfil legado ativo sem vínculo Auth ${label}: corrige leitura sem alterar dados`, async () => {
    const db = await fixture();
    try {
      await legacy(db, { petStatus, shelter });
      const before = await storedState(db);
      const contracts = await wrappers(db);
      await actor(db);
      assert.deepEqual(await profile(db, 4), []);
      assert.deepEqual(await summary(db, 4), []);
      await admin(db);
      await db.exec(fix);
      assert.deepEqual(await storedState(db), before);
      assert.deepEqual(await wrappers(db), contracts);
      await actor(db);
      const details = await profile(db, 4);
      const brief = await summary(db, 4);
      assert.equal(details.length, 1);
      assert.equal(brief.length, 1);
      assertPublicOnly(details[0], 4);
      assertPublicOnly(brief[0], 4);
      assert.equal(details[0].lar_de_adocao, shelter);
    } finally { await db.close(); }
  });
}

describe('Perfis públicos corrigidos: Auth, privacidade e estabilidade', { concurrency: false }, () => {
  let db;
  before(async () => { db = await fixture(); await db.exec(fix); });
  after(async () => { await db?.close(); });
  beforeEach(async () => { await admin(db); await db.exec('begin'); });
  afterEach(async () => { await admin(db); await db.exec('rollback'); });

  it('retorna perfil/resumo sem qualquer animal, inclusive ao próprio usuário', async () => {
    await db.exec('delete from public.animal');
    await actor(db);
    assert.equal((await profile(db)).length, 1);
    assert.equal((await summary(db)).length, 1);
    assert.equal((await profile(db, 1))[0].id, 1);
  });

  it('não exibe perfil nem resumo de alvo inativo', async () => {
    await db.exec('update public.cliente set ativo=false where id=2');
    await actor(db);
    assert.deepEqual(await profile(db), []);
    assert.deepEqual(await summary(db), []);
  });

  it('alvos legados inativos sem Auth ficam ocultos, mesmo com animal Disponível', async () => {
    await legacy(db, { id: 4, active: false });
    await legacy(db, { id: 5, active: false, petStatus: 'Disponível', shelter: true });
    await actor(db);
    for (const id of [4, 5]) {
      assert.deepEqual(await profile(db, id), []);
      assert.deepEqual(await summary(db, id), []);
    }
  });

  it('perfil legado sem Auth continua público ao passar seu único animal para Adotado', async () => {
    await legacy(db, { petStatus: 'Disponível' });
    await actor(db);
    assert.equal((await profile(db, 4)).length, 1);
    assert.equal((await summary(db, 4)).length, 1);
    await admin(db);
    await db.exec("update public.animal set status='Adotado' where id=104");
    await actor(db);
    assert.equal((await profile(db, 4)).length, 1);
    assert.equal((await summary(db, 4)).length, 1);
    await admin(db);
    const stored = await db.query('select auth_user_id,ativo from public.cliente where id=4');
    assert.deepEqual(stored.rows, [{ auth_user_id: null, ativo: true }]);
  });

  it('não permite chamador inativo', async () => {
    await db.exec('update public.cliente set ativo=false where id=1');
    await actor(db);
    for (const call of [profile, summary]) {
      await fails(db, () => call(db), { code: 'PT403' });
    }
  });

  it('não permite identidade sem perfil ou ausência de Auth', async () => {
    for (const [uid, code] of [
      ['44444444-4444-4444-8444-444444444444', 'PT403'], [null, 'PT401'],
    ]) {
      await actor(db, uid);
      for (const call of [profile, summary]) await fails(db, () => call(db), { code });
    }
  });

  it('anon não executa helpers ou wrappers', async () => {
    await actor(db, null, 'anon');
    for (const fn of ['private.resumo_responsavel', 'private.detalhe_publico_responsavel',
      'public.buscar_resumo_responsavel', 'public.buscar_perfil_publico']) {
      await fails(db, () => db.query(`select * from ${fn}(2)`), { code: '42501' });
    }
  });

  it('projeções públicas omitem contatos para pessoas e lares', async () => {
    await actor(db);
    for (const id of [1, 2]) {
      for (const row of [...await profile(db, id), ...await summary(db, id)]) {
        for (const field of ['email', 'telefone', 'endereco', 'auth_user_id']) {
          assert.equal(Object.hasOwn(row, field), false);
        }
      }
    }
  });

  it('rejeita IDs inválidos e retorna vazio para ausente', async () => {
    await actor(db);
    for (const call of [profile, summary]) {
      await fails(db, () => call(db, 0), { code: 'PT400' });
      assert.deepEqual(await call(db, 9999), []);
    }
  });

  it('pode reaplicar SQL12 mantendo contratos e ACLs', async () => {
    const before = await wrappers(db);
    await db.exec(fix);
    assert.deepEqual(await wrappers(db), before);
  });
});

it('SQL12 aborta overload divergente sem instalar alteração parcial', async () => {
  const db = await fixture();
  try {
    const before = await wrappers(db);
    await db.exec('create function public.buscar_perfil_publico(p_cliente_id bigint) returns text language sql as $$select null::text$$');
    await assert.rejects(() => db.exec(fix), /overloads/);
    await db.exec('rollback');
    assert.deepEqual(await wrappers(db), before);
    assert.equal((await db.query("select obj_description('private.resumo_responsavel(integer)'::regprocedure,'pg_proc') as marker")).rows[0].marker, null);
  } finally { await db.close(); }
});

it('SQL30 mantém contrato INTEGER da pesquisa, mascara contatos e não recria perfis BIGINT', async () => {
  const db = await fixture();
  try {
    await db.exec(adoption);
    await db.exec(fix);
    const before = await wrappers(db);
    await db.exec(search);
    assert.deepEqual(await wrappers(db), before);
    assert.equal((await db.query("select to_regprocedure('public.buscar_perfil_publico(bigint)') as extra")).rows[0].extra, null);
    await actor(db);
    const result = await db.query('select * from public.buscar_clientes_publicos(null)');
    assert.equal(result.rows.length, 2);
    for (const row of result.rows) {
      assert.equal(row.email, '');
      assert.equal(row.telefone, '');
      assert.equal(row.endereco, '');
    }
    const found = await db.query("select * from public.buscar_clientes_publicos('@lar')");
    assert.equal(found.rows[0].id, 2);
    const pets = await db.query("select * from public.ep_buscar_animais(p_tipo=>'Gato')");
    assert.equal(pets.rows[0].id, 10);
    await actor(db, ownerUid);
    const mine = await db.query('select * from public.ep_buscar_animais(p_somente_proprios=>true)');
    assert.equal(mine.rows[0].id, 10);
    await actor(db, null, 'anon');
    await assert.rejects(() => db.query('select * from public.buscar_clientes_publicos(null)'), { code: '42501' });
  } finally { await db.close(); }
});

it('SQL30 exige SQL12 antes de mudar funções de pesquisa', async () => {
  const db = await fixture();
  try {
    await db.exec(adoption);
    await assert.rejects(() => db.exec(search), /SQL 12/);
    await db.exec('rollback');
    assert.equal((await db.query("select to_regprocedure('public.ep_buscar_animais(text,text,text,text,text,text,text,text,text,text,bigint,boolean,bigint,integer)') as fn")).rows[0].fn, null);
  } finally { await db.close(); }
});

it('SQL30 pesquisa e perfis incluem legados ativos sem Auth ou animais e ocultam inativos sem vazar contatos', async () => {
  const db = await fixture();
  try {
    await legacy(db, { id: 4 });
    await legacy(db, { id: 5, petStatus: 'Adotado', shelter: true });
    await legacy(db, { id: 6, active: false });
    await legacy(db, { id: 7, active: false, petStatus: 'Disponível', shelter: true });
    const before = await storedState(db);
    await db.exec(adoption);
    await db.exec(fix);
    await db.exec(search);
    assert.deepEqual(await storedState(db), before);
    for (const name of ['buscar_perfil_publico', 'buscar_resumo_responsavel']) {
      const metadata = await db.query(`select p.pronargs,p.proargtypes::text as types
        from pg_proc p join pg_namespace n on n.oid=p.pronamespace
        where n.nspname='public' and p.proname=$1`, [name]);
      assert.deepEqual(metadata.rows, [{ pronargs: 1, types: '23' }]);
    }
    await actor(db);
    const results = await db.query('select * from public.buscar_clientes_publicos(null)');
    assert.deepEqual(results.rows.map(row => row.id).sort((a, b) => a - b), [1, 2, 4, 5]);
    for (const row of results.rows) {
      assert.equal(row.email, '');
      assert.equal(row.telefone, '');
      assert.equal(row.endereco, '');
      assert.equal(Object.hasOwn(row, 'auth_user_id'), false);
    }
    for (const id of [4, 5]) {
      const details = await profile(db, id);
      const brief = await summary(db, id);
      assert.equal(details.length, 1);
      assert.equal(brief.length, 1);
      assertPublicOnly(details[0], id);
      assertPublicOnly(brief[0], id);
    }
    for (const id of [6, 7]) {
      assert.deepEqual(await profile(db, id), []);
      assert.deepEqual(await summary(db, id), []);
    }
  } finally { await db.close(); }
});
