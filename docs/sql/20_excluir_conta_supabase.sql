-- REVISAR ANTES DE EXECUTAR. Esta migração NÃO foi executada pelo aplicativo.
-- Requer a migração 10 de adoções aplicada, esquema confirmado pela consulta
-- 00_inspecionar_exclusao_conta_supabase.sql e execução manual por administrador.
-- O trigger é BEFORE DELETE em auth.users para anonimizar as FKs antes que
-- eventuais regras ON DELETE da tabela auth removam registros relacionados.
-- Tudo que é relacional participa da transação do DELETE em auth.users.
-- Objetos Storage são tratados por uma fila de limpeza fora da transação.

begin;

lock table public.cliente, public.animal, public.adocao, public.questionario
  in share row exclusive mode;

do $preflight$
declare
  item record;
  status_tipo oid;
  status_classe "char";
  status_rotulos text[];
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname = current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Executar com administrador do banco, nunca pelo aplicativo.';
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticated')
     or not exists (select 1 from pg_catalog.pg_roles where rolname = 'anon')
     or not exists (select 1 from pg_catalog.pg_roles where rolname = 'service_role') then
    raise exception 'Papéis Supabase esperados não encontrados.';
  end if;
  if to_regclass('auth.users') is null or to_regclass('storage.objects') is null
     or to_regprocedure('auth.uid()') is null then
    raise exception 'Auth, Storage ou auth.uid() não encontrado.';
  end if;
  if to_regprocedure('public._ep_adocoes_json(bigint,bigint)') is null then
    raise exception 'A função da migração 10 não existe. Aplicar/revisar primeiro a migração de adoções.';
  end if;

  for item in select * from (values
    ('cliente','id'), ('cliente','auth_user_id'), ('cliente','ativo'),
    ('cliente','nome'), ('cliente','sobrenome'), ('cliente','email'),
    ('cliente','telefone'), ('cliente','usuario'),
    ('cliente','cidadeDeResidencia'), ('cliente','estado'),
    ('cliente','endereco'), ('cliente','imagem'), ('cliente','larDeAdocao'),
    ('cliente','questionario_pendente'),
    ('animal','id'), ('animal','id_cliente'), ('animal','ativo'),
    ('animal','imagem'),
    ('adocao','id_animal'), ('adocao','id_cliente'), ('adocao','id_dono'),
    ('adocao','status'),
    ('questionario','id_cliente'),
    ('storage.objects','owner_id'), ('storage.objects','bucket_id'),
    ('storage.objects','name')
  ) as esperados(tabela,coluna)
  loop
    if item.tabela = 'storage.objects' then
      if not exists (
        select 1 from information_schema.columns
        where table_schema='storage' and table_name='objects'
          and column_name=item.coluna
      ) then
        raise exception 'storage.objects.% ausente; revisar propriedade dos arquivos antes de prosseguir.', item.coluna;
      end if;
    elsif not exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name=item.tabela
        and column_name=item.coluna
    ) then
      raise exception 'Coluna public.%.% ausente. Adaptar a migração após revisar o esquema.', item.tabela, item.coluna;
    end if;
  end loop;

  if (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.cliente'::regclass and attname='auth_user_id') <> 'uuid'::regtype
     or (select atttypid from pg_catalog.pg_attribute
         where attrelid='public.cliente'::regclass and attname='ativo') <> 'boolean'::regtype
     or (select atttypid from pg_catalog.pg_attribute
         where attrelid='public.cliente'::regclass and attname='larDeAdocao') <> 'boolean'::regtype
     or (select attnotnull from pg_catalog.pg_attribute
         where attrelid='public.cliente'::regclass and attname='auth_user_id') then
    raise exception 'cliente.auth_user_id deve ser UUID anulável; ativo e larDeAdocao devem ser boolean.';
  end if;

  if (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.animal'::regclass and attname='ativo') <> 'boolean'::regtype
     or (select attnotnull from pg_catalog.pg_attribute
         where attrelid='public.animal'::regclass and attname='imagem') then
    raise exception 'animal.ativo deve ser boolean e animal.imagem deve aceitar NULL.';
  end if;
  if (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.cliente'::regclass and attname='imagem') not in
        ('text'::regtype, 'character varying'::regtype, 'character'::regtype)
     or (select attnotnull from pg_catalog.pg_attribute
         where attrelid='public.cliente'::regclass and attname='imagem')
     or (select attnotnull from pg_catalog.pg_attribute
         where attrelid='public.cliente'::regclass and attname='endereco') then
    raise exception 'cliente.imagem/endereco devem aceitar NULL e imagem deve ser texto.';
  end if;
  if (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.cliente'::regclass and attname='questionario_pendente')
       not in ('boolean'::regtype,'smallint'::regtype,'integer'::regtype,'bigint'::regtype) then
    raise exception 'Tipo de cliente.questionario_pendente não suportado.';
  end if;

  select a.atttypid, t.typtype into status_tipo, status_classe
  from pg_catalog.pg_attribute a
  join pg_catalog.pg_type t on t.oid=a.atttypid
  where a.attrelid='public.adocao'::regclass and a.attname='status';
  if status_classe='e' then
    select array_agg(enumlabel::text) into status_rotulos
    from pg_catalog.pg_enum where enumtypid=status_tipo;
    if not ('Cancelado'=any(status_rotulos)) then
      raise exception 'adocao.status não aceita Cancelado.';
    end if;
  elsif status_tipo not in ('text'::regtype,'varchar'::regtype) then
    raise exception 'Tipo de adocao.status não suportado.';
  end if;

  for item in select * from (values
    ('animal','id_cliente','cliente'),
    ('adocao','id_animal','animal'),
    ('adocao','id_cliente','cliente'),
    ('adocao','id_dono','cliente'),
    ('questionario','id_cliente','cliente')
  ) as relacoes(tabela,coluna,referencia)
  loop
    if not exists (
      select 1
      from pg_catalog.pg_constraint fk
      join pg_catalog.pg_attribute origem
        on origem.attrelid=fk.conrelid and origem.attnum=fk.conkey[1]
      join pg_catalog.pg_attribute destino
        on destino.attrelid=fk.confrelid and destino.attnum=fk.confkey[1]
      where fk.contype='f' and fk.convalidated and cardinality(fk.conkey)=1
        and fk.conrelid=format('public.%I',item.tabela)::regclass
        and origem.attname=item.coluna
        and fk.confrelid=format('public.%I',item.referencia)::regclass
        and destino.attname='id'
    ) then
      raise exception 'FK validada public.%.% -> public.%.id ausente. Revisar antes de prosseguir.',
        item.tabela,item.coluna,item.referencia;
    end if;
  end loop;

  if exists (
    select 1 from pg_catalog.pg_trigger t
    where t.tgrelid='auth.users'::regclass and not t.tgisinternal
      and (t.tgtype & 8) <> 0 and t.tgname <> 'ep_anonimizar_conta_auth'
  ) then
    raise exception 'Já há trigger de usuário em DELETE de auth.users. Inspecionar e integrar antes de continuar.';
  end if;
  if to_regclass('public.ep_account_storage_cleanup') is not null
     or to_regprocedure('public.ep_anonimizar_conta_auth()') is not null
     or to_regprocedure('public.ep_conta_exclusao_pronta()') is not null
     or exists (
       select 1 from pg_catalog.pg_trigger
       where tgrelid='auth.users'::regclass and tgname='ep_anonimizar_conta_auth'
     ) then
    raise exception 'Objetos desta migração já existem. Não reaplicar sem revisar a versão instalada.';
  end if;
end;
$preflight$;

create table public.ep_account_storage_cleanup (
  id bigint generated by default as identity primary key,
  user_id uuid not null,
  bucket_id text not null,
  object_name text not null,
  attempts integer not null default 0 check (attempts >= 0),
  last_error text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (user_id, bucket_id, object_name)
);
alter table public.ep_account_storage_cleanup enable row level security;
revoke all privileges on table public.ep_account_storage_cleanup
  from public, anon, authenticated;
grant select, update on table public.ep_account_storage_cleanup to service_role;

create or replace function public.ep_anonimizar_conta_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_cliente_id bigint;
  v_perfis integer;
  v_questionario_reset text;
begin
  select count(*), min(c.id)::bigint
    into v_perfis, v_cliente_id
    from public.cliente c
   where c.auth_user_id = old.id;
  if v_perfis > 1 then
    raise exception 'Há perfis duplicados vinculados à conta Auth; exclusão bloqueada.';
  end if;

  insert into public.ep_account_storage_cleanup
    (user_id, bucket_id, object_name)
  select old.id, o.bucket_id, o.name
    from storage.objects o
   where o.owner_id::text = old.id::text
  on conflict (user_id, bucket_id, object_name) do nothing;

  if v_perfis = 1 then
    update public.adocao d
       set status = 'Cancelado'
     where d.status::text = 'Aguardando'
       and (d.id_cliente = v_cliente_id or d.id_dono = v_cliente_id);

    delete from public.questionario q where q.id_cliente = v_cliente_id;

    update public.animal a
       set ativo = false, imagem = null
     where a.id_cliente = v_cliente_id;

    select case
      when a.atttypid = 'boolean'::regtype then 'false'
      else '0'
    end
      into v_questionario_reset
      from pg_catalog.pg_attribute a
     where a.attrelid='public.cliente'::regclass
       and a.attname='questionario_pendente';

    execute format(
      'update public.cliente
          set auth_user_id = null,
              ativo = false,
              nome = $1,
              sobrenome = $2,
              email = $3,
              telefone = $4,
              usuario = $5,
              "cidadeDeResidencia" = $6,
              estado = $7,
              endereco = null,
              imagem = null,
              "larDeAdocao" = false,
              questionario_pendente = %s
        where id = $8',
      v_questionario_reset
    )
    using 'Conta', 'removida',
      format('excluido+%s@invalid.invalid', old.id),
      lpad(v_cliente_id::text, 11, '0'),
      format('excluido_%s', v_cliente_id),
      '', '', v_cliente_id;
  end if;

  return old;
end;
$function$;

revoke all on function public.ep_anonimizar_conta_auth()
  from public, anon, authenticated;
create trigger ep_anonimizar_conta_auth
before delete on auth.users
for each row execute function public.ep_anonimizar_conta_auth();

create or replace function public.ep_conta_exclusao_pronta()
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if auth.uid() is null then
    raise sqlstate 'PT401' using message='Entre novamente para continuar.';
  end if;
  return (
    select count(*) = 1
      from public.cliente c
     where c.auth_user_id = auth.uid() and c.ativo is true
  ) and exists (
    select 1 from pg_catalog.pg_trigger t
     where t.tgrelid='auth.users'::regclass
       and t.tgname='ep_anonimizar_conta_auth'
       and not t.tgisinternal and t.tgenabled='O'
  );
end;
$function$;
revoke all on function public.ep_conta_exclusao_pronta()
  from public, anon, authenticated;
grant execute on function public.ep_conta_exclusao_pronta()
  to authenticated;

-- Tombstones permanecem para manter as FKs do histórico, mas dados de perfil
-- e contato são omitidos nas notificações de adoção.
create or replace function public._ep_adocoes_json(
  p_cliente_id bigint,
  p_adocao_id bigint default null
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',d.id,'data',d.data,'status',d.status,
    'id_animal',d.id_animal,'id_cliente',d.id_cliente,'id_dono',d.id_dono,
    'animal_nome',a.nome,'animal_imagem',a.imagem,'animal_idade',a.idade,'animal_sexo',a.sexo,
    'estado',case when dono.ativo is true then dono.estado end,
    'cidadeDeResidencia',case when dono.ativo is true then dono."cidadeDeResidencia" end,
    'solicitante_nome',case when pretendente.ativo is true then pretendente.nome else 'Conta excluída' end,
    'solicitante_sobrenome',case when pretendente.ativo is true then pretendente.sobrenome end,
    'solicitante_email',case when pretendente.ativo is true then pretendente.email end,
    'solicitante_telefone',case when pretendente.ativo is true then pretendente.telefone end
  ) order by d.data desc,d.id desc),'[]'::jsonb)
  from public.adocao d
  join public.animal a on a.id=d.id_animal
  join public.cliente dono on dono.id=d.id_dono
  join public.cliente pretendente on pretendente.id=d.id_cliente
  where (d.id_cliente=p_cliente_id or d.id_dono=p_cliente_id)
    and (p_adocao_id is null or d.id=p_adocao_id);
$function$;

notify pgrst, 'reload schema';
commit;
