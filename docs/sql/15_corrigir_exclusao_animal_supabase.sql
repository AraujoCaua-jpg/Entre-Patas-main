-- REVISÃO/INSTALAÇÃO MANUAL APÓS BACKUP RECUPERÁVEL E AUTORIZAÇÃO.
-- Validado somente em teste local. Não executar automaticamente na produção.
-- Exclusão lógica por RPC: não concede UPDATE de ativo nem DELETE ao cliente.
-- Não modifica registros durante a instalação nem altera policies RLS.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $preflight$
declare
  item record;
  existente oid := to_regprocedure('public.excluir_meu_animal(bigint)');
begin
  if not exists (select 1 from pg_catalog.pg_roles
      where rolname=current_user and (rolsuper or rolbypassrls)) then
    raise exception 'Executar com administrador autorizado, nunca pelo aplicativo.';
  end if;
  if to_regprocedure('auth.uid()') is null or
     to_regclass('public.cliente') is null or to_regclass('public.animal') is null then
    raise exception 'Auth, cliente e animal precisam estar configurados antes do SQL 15.';
  end if;
  for item in select * from (values
    ('cliente','id'),('cliente','auth_user_id'),('cliente','ativo'),
    ('animal','id'),('animal','id_cliente'),('animal','ativo'),('animal','imagem')
  ) e(tabela,coluna) loop
    if not exists (select 1 from information_schema.columns
        where table_schema='public' and table_name=item.tabela and column_name=item.coluna) then
      raise exception 'Coluna public.%.% ausente. Revisar o esquema.',item.tabela,item.coluna;
    end if;
  end loop;
  if exists (select 1 from pg_catalog.pg_class
      where oid in ('public.cliente'::regclass,'public.animal'::regclass) and not relrowsecurity) then
    raise exception 'RLS de cliente e animal precisa permanecer habilitada.';
  end if;
  for item in select * from (values
    ('cliente','id'),('animal','id'),('animal','id_cliente')
  ) e(tabela,coluna) loop
    if (select atttypid from pg_catalog.pg_attribute
        where attrelid=format('public.%I',item.tabela)::regclass and attname=item.coluna)
        not in ('smallint'::regtype,'integer'::regtype,'bigint'::regtype) then
      raise exception 'Tipo de public.%.% não suportado.',item.tabela,item.coluna;
    end if;
  end loop;
  if (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.cliente'::regclass and attname='auth_user_id') <> 'uuid'::regtype or
     (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.cliente'::regclass and attname='ativo') <> 'boolean'::regtype or
     (select atttypid from pg_catalog.pg_attribute
      where attrelid='public.animal'::regclass and attname='ativo') <> 'boolean'::regtype or
     (select attnotnull from pg_catalog.pg_attribute
      where attrelid='public.animal'::regclass and attname='imagem') then
    raise exception 'Esperados Auth UUID, ativo boolean e imagem anulável. Revisar sem converter dados.';
  end if;
  -- Uma concessão ampla herdada também permitiria contornar a RPC.
  if has_column_privilege('authenticated','public.animal','ativo','UPDATE') or
     has_column_privilege('anon','public.animal','ativo','UPDATE') then
    raise exception 'UPDATE direto de animal.ativo já está concedido. Revisar grants antes de instalar, sem ampliar permissões.';
  end if;
  if exists (select 1 from pg_catalog.pg_proc p
      join pg_catalog.pg_namespace n on n.oid=p.pronamespace
      where n.nspname='public' and p.proname='excluir_meu_animal'
        and p.oid is distinct from existente) then
    raise exception 'Overload de excluir_meu_animal encontrado. Revisar sem DROP/CASCADE.';
  end if;
  if existente is not null and not exists (
      select 1 from pg_catalog.pg_proc p join pg_catalog.pg_roles r on r.oid=p.proowner
      where p.oid=existente and p.prorettype='jsonb'::regtype
        and p.proargnames=array['p_animal_id']::text[] and (r.rolsuper or r.rolbypassrls)) then
    raise exception 'RPC existente incompatível ou proprietário inadequado. Não substituir automaticamente.';
  end if;
end;
$preflight$;

create or replace function public.excluir_meu_animal(p_animal_id bigint)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
  v_usuario uuid := auth.uid();
  v_cliente bigint;
  v_animal bigint;
begin
  if v_usuario is null then
    raise sqlstate 'PT401' using message='Entre novamente para continuar.';
  end if;
  if p_animal_id is null or p_animal_id<=0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  begin
    select c.id into strict v_cliente from public.cliente c
    where c.auth_user_id=v_usuario and c.ativo is true;
  exception when no_data_found or too_many_rows then
    raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.';
  end;
  -- Mesmo sentido das RPCs de adoção: animal antes do lock de perfil.
  -- O filtro de propriedade impede até o lock de um animal alheio.
  select a.id into v_animal from public.animal a
  where a.id=p_animal_id and a.id_cliente=v_cliente for update;
  if not found then
    raise sqlstate 'PT404' using message='Animal não encontrado ou sem permissão para excluir.';
  end if;
  perform 1 from public.cliente c
  where c.id=v_cliente and c.auth_user_id=v_usuario and c.ativo is true for share;
  if not found then
    raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.';
  end if;
  -- Idempotente: nunca reativa, não muda status/proprietário e mantém o histórico.
  update public.animal set ativo=false, imagem=null
  where id=v_animal and id_cliente=v_cliente;
  return jsonb_build_object('id',v_animal,'ativo',false);
end;
$function$;

revoke all on function public.excluir_meu_animal(bigint) from public,anon,authenticated;
grant execute on function public.excluir_meu_animal(bigint) to authenticated;

-- O Flutter atual usa somente soft delete. Evita exclusão física pela API direta.
-- Não afeta a conta administrativa/Edge Function e não altera a RLS.
revoke delete on table public.animal from public,anon,authenticated;

do $postflight$
declare v_rpc oid := 'public.excluir_meu_animal(bigint)'::regprocedure;
begin
  if not has_function_privilege('authenticated',v_rpc,'EXECUTE') or
     has_function_privilege('anon',v_rpc,'EXECUTE') or
     exists (select 1 from pg_catalog.pg_proc p,
       lateral aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
       where p.oid=v_rpc and a.grantee=0 and a.privilege_type='EXECUTE') then
    raise exception 'ACL da RPC de exclusão não está restrita ao usuário autenticado.';
  end if;
  if has_table_privilege('authenticated','public.animal','DELETE') or
     has_table_privilege('anon','public.animal','DELETE') or
     has_column_privilege('authenticated','public.animal','ativo','UPDATE') or
     has_column_privilege('anon','public.animal','ativo','UPDATE') then
    raise exception 'Privilégios herdados permitem contornar a exclusão lógica. Revisar memberships/grants.';
  end if;
  if not exists (select 1 from pg_catalog.pg_proc p join pg_catalog.pg_roles r on r.oid=p.proowner
      where p.oid=v_rpc and p.prosecdef and (r.rolsuper or r.rolbypassrls)
        and 'search_path=""'=any(p.proconfig)) or
     exists (select 1 from pg_catalog.pg_class
       where oid in ('public.animal'::regclass,'public.cliente'::regclass) and not relrowsecurity) then
    raise exception 'Proprietário/search_path/RLS incompatível com a RPC segura.';
  end if;
end;
$postflight$;

notify pgrst, 'reload schema';
commit;
