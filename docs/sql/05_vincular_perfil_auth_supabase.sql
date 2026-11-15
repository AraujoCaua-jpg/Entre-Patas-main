-- REVISAR E APLICAR MANUALMENTE ANTES DAS MIGRAÇÕES 10, 20 E 30.
-- Não executado pelo aplicativo. O projeto já possui o trigger
-- on_entre_patas_auth_user_created -> private.criar_cliente_entre_patas().
-- Esta migração valida e preserva esse mecanismo; não cria nem substitui
-- função/trigger de criação de perfil. O corpo da função existente precisa
-- ser revisado manualmente antes da aplicação.

begin;

lock table public.cliente in share row exclusive mode;

do $preflight$
declare item record;
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname=current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Executar com administrador do banco, nunca pelo aplicativo.';
  end if;
  if to_regclass('auth.users') is null or to_regprocedure('auth.uid()') is null then
    raise exception 'Supabase Auth não encontrado.';
  end if;
  for item in select * from (values
    ('auth_user_id'),('ativo'),('email')
  ) as esperados(coluna)
  loop
    if not exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name='cliente'
        and column_name=item.coluna
    ) then
      raise exception 'public.cliente.% ausente. Adaptar a migração após revisar o esquema.',
        item.coluna;
    end if;
  end loop;

  if (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.cliente'::regclass and attname='auth_user_id') <> 'uuid'::regtype
     or (select atttypid from pg_catalog.pg_attribute
         where attrelid='public.cliente'::regclass and attname='ativo') <> 'boolean'::regtype then
    raise exception 'Tipos incompatíveis em cliente.auth_user_id/ativo.';
  end if;
  if exists (
    select 1 from public.cliente
    where auth_user_id is not null
    group by auth_user_id having count(*)>1
  ) then
    raise exception 'Há perfis duplicados por auth_user_id; revisar sem apagar dados.';
  end if;

  if to_regprocedure('private.criar_cliente_entre_patas()') is null
     or not exists (
       select 1
       from pg_catalog.pg_trigger t
       join pg_catalog.pg_proc p on p.oid=t.tgfoid
       where t.tgrelid='auth.users'::regclass
         and t.tgname='on_entre_patas_auth_user_created'
         and t.tgfoid=to_regprocedure('private.criar_cliente_entre_patas()')
         and not t.tgisinternal
         and t.tgtype=5
         and t.tgenabled='O'
         and p.prosecdef
         and coalesce(p.proconfig, array[]::text[])
             @> array['search_path=""']::text[]
     ) then
    raise exception 'O trigger ativo AFTER INSERT private.criar_cliente_entre_patas() não foi validado.';
  end if;
  if (
    select count(*) from pg_catalog.pg_trigger
    where tgrelid='auth.users'::regclass
      and tgfoid=to_regprocedure('private.criar_cliente_entre_patas()')
      and not tgisinternal
  ) <> 1 then
    raise exception 'A função existente deve estar ligada a exatamente um trigger em auth.users.';
  end if;
  if exists (
    select 1 from pg_catalog.pg_trigger t
    where t.tgrelid='auth.users'::regclass and not t.tgisinternal
      and (t.tgtype & 4) <> 0
      and t.tgname<>'on_entre_patas_auth_user_created'
  ) then
    raise exception 'Há outro trigger AFTER/BEFORE INSERT em auth.users. Revisar para evitar criação duplicada de perfis.';
  end if;
  if exists (
    select 1 from pg_catalog.pg_trigger t
    where t.tgrelid='auth.users'::regclass and not t.tgisinternal
      and (t.tgtype & 16) <> 0
      and t.tgname<>'ep_sincronizar_email_auth'
  ) then
    raise exception 'Há outro trigger UPDATE em auth.users. Revisar antes de adicionar a sincronização de e-mail.';
  end if;
  if to_regprocedure('public.ep_sincronizar_email_auth()') is not null
     or exists (
       select 1 from pg_catalog.pg_trigger
       where tgrelid='auth.users'::regclass
         and tgname='ep_sincronizar_email_auth'
     ) then
    raise exception 'Objetos desta migração já existem. Não reaplicar sem revisar a versão instalada.';
  end if;
end;
$preflight$;

do $indice$
begin
  if not exists (
    select 1
    from pg_catalog.pg_index i
    join pg_catalog.pg_attribute a
      on a.attrelid=i.indrelid and a.attname='auth_user_id'
    where i.indrelid='public.cliente'::regclass
      and i.indisunique and i.indnkeyatts=1 and i.indkey[0]=a.attnum
  ) then
    create unique index ep_cliente_auth_user_id_unica
      on public.cliente(auth_user_id);
  end if;
end;
$indice$;

create or replace function public.ep_sincronizar_email_auth()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.email is distinct from old.email then
    update public.cliente
       set email=lower(new.email)
     where auth_user_id=new.id and ativo is true;
  end if;
  return new;
end;
$function$;

revoke all on function public.ep_sincronizar_email_auth()
  from public,anon,authenticated;
create trigger ep_sincronizar_email_auth
after update of email on auth.users
for each row
when (old.email is distinct from new.email)
execute function public.ep_sincronizar_email_auth();

commit;
