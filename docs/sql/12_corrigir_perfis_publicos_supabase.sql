-- REVISAR E APLICAR MANUALMENTE, APENAS APÓS BACKUP RECUPERÁVEL CONFIRMADO.
-- Correção independente do SQL 10. Compatível com as assinaturas INTEGER
-- inspecionadas em produção: os wrappers públicos e seus retornos são preservados.
-- Um perfil ativo não depende de possuir animal Disponível para ser consultado.
-- Não altera registros, políticas RLS, tabelas ou vínculos Auth.
-- Não remove overloads: se existir uma versão BIGINT, interrompe para revisão.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $preflight$
declare
  esperado record;
  funcao record;
  total integer;
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname=current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Executar com administrador do banco, nunca pelo aplicativo.';
  end if;
  if to_regprocedure('auth.uid()') is null
     or not exists (select 1 from pg_catalog.pg_roles where rolname='authenticated')
     or not exists (select 1 from pg_catalog.pg_roles where rolname='anon') then
    raise exception 'Supabase Auth e papéis esperados não encontrados.';
  end if;
  if to_regclass('public.cliente') is null then
    raise exception 'Tabela public.cliente não encontrada.';
  end if;
  for esperado in select * from (values
    ('id','integer'),('auth_user_id','uuid'),('ativo','boolean'),
    ('nome',null),('sobrenome',null),('usuario',null),('imagem',null),
    ('cidadeDeResidencia',null),('estado',null),('larDeAdocao','boolean')
  ) as campos(nome,tipo)
  loop
    if not exists (
      select 1 from pg_catalog.pg_attribute a
      where a.attrelid='public.cliente'::regclass and a.attname=esperado.nome
        and a.attnum>0 and not a.attisdropped
        and (esperado.tipo is null or a.atttypid=esperado.tipo::regtype)
    ) then
      raise exception 'Coluna/tipo public.cliente.% divergente. Revisar antes de aplicar SQL 12.', esperado.nome;
    end if;
  end loop;
  if not (select relrowsecurity from pg_catalog.pg_class where oid='public.cliente'::regclass) then
    raise exception 'A RLS de cliente deve permanecer habilitada.';
  end if;
  if not has_schema_privilege('authenticated','private','USAGE') then
    raise exception 'Wrappers SECURITY INVOKER precisam de USAGE existente em private; revisar privilégios sem expor o schema na API.';
  end if;

  for esperado in select * from (values
    ('private','resumo_responsavel',true,
     'TABLE(id integer, nome text, usuario text, imagem text)',
     array['p_cliente_id','id','nome','usuario','imagem']::text[]),
    ('private','detalhe_publico_responsavel',true,
     'TABLE(id integer, nome text, sobrenome text, usuario text, imagem text, cidade text, estado text, lar_de_adocao boolean)',
     array['p_cliente_id','id','nome','sobrenome','usuario','imagem','cidade','estado','lar_de_adocao']::text[]),
    ('public','buscar_resumo_responsavel',false,
     'TABLE(id integer, nome text, usuario text, imagem text)',
     array['p_cliente_id','id','nome','usuario','imagem']::text[]),
    ('public','buscar_perfil_publico',false,
     'TABLE(id integer, nome text, sobrenome text, usuario text, imagem text, cidade text, estado text, lar_de_adocao boolean)',
     array['p_cliente_id','id','nome','sobrenome','usuario','imagem','cidade','estado','lar_de_adocao']::text[])
  ) as funcoes(esquema,nome,definer,resultado,argumentos)
  loop
    select count(*) into total from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname=esperado.esquema and p.proname=esperado.nome;
    if total<>1 then
      raise exception 'Esperada uma única função %.%(integer), sem overloads. Revisar versões locais BIGINT separadamente; não usar DROP CASCADE.', esperado.esquema,esperado.nome;
    end if;
    select p.*, r.rolsuper, r.rolbypassrls into funcao
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    join pg_catalog.pg_roles r on r.oid=p.proowner
    where n.nspname=esperado.esquema and p.proname=esperado.nome;
    if funcao.pronargs<>1 or funcao.proargtypes::text<>'23'
       or funcao.proargnames is distinct from esperado.argumentos
       or pg_catalog.pg_get_function_result(funcao.oid)<>esperado.resultado
       or funcao.prosecdef is distinct from esperado.definer
       or funcao.provolatile<>'s'
       or not coalesce(funcao.proconfig,array[]::text[]) @> array['search_path=""']::text[]
       or not (funcao.rolsuper or funcao.rolbypassrls) then
      raise exception 'Assinatura, retorno, proprietário ou segurança divergente em %.%. Conferir a inspeção antes de aplicar SQL 12.', esperado.esquema,esperado.nome;
    end if;
    if esperado.esquema='public' and (
      (esperado.nome='buscar_resumo_responsavel' and
       lower(regexp_replace(funcao.prosrc,'\s','','g'))<>'select*fromprivate.resumo_responsavel(p_cliente_id);')
      or (esperado.nome='buscar_perfil_publico' and
       lower(regexp_replace(funcao.prosrc,'\s','','g'))<>'select*fromprivate.detalhe_publico_responsavel(p_cliente_id);')
    ) then
      raise exception 'Wrapper público %.% não corresponde à delegação inspecionada. Revisar sem substituir seu corpo.', esperado.esquema,esperado.nome;
    end if;
  end loop;
end;
$preflight$;

create or replace function private.resumo_responsavel(p_cliente_id integer)
returns table(id integer,nome text,usuario text,imagem text)
language plpgsql stable security definer set search_path=''
as $function$
begin
  if auth.uid() is null then
    raise sqlstate 'PT401' using message='Entre novamente para continuar.';
  end if;
  if (select count(*) from public.cliente eu
      where eu.auth_user_id=auth.uid() and eu.ativo is true)<>1 then
    raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.';
  end if;
  if p_cliente_id is null or p_cliente_id<=0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  return query
  select c.id,c.nome::text,c.usuario::text,c.imagem::text
  from public.cliente c where c.id=p_cliente_id and c.ativo is true;
end;
$function$;

create or replace function private.detalhe_publico_responsavel(p_cliente_id integer)
returns table(id integer,nome text,sobrenome text,usuario text,imagem text,
              cidade text,estado text,lar_de_adocao boolean)
language plpgsql stable security definer set search_path=''
as $function$
begin
  if auth.uid() is null then
    raise sqlstate 'PT401' using message='Entre novamente para continuar.';
  end if;
  if (select count(*) from public.cliente eu
      where eu.auth_user_id=auth.uid() and eu.ativo is true)<>1 then
    raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.';
  end if;
  if p_cliente_id is null or p_cliente_id<=0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  return query
  select c.id,c.nome::text,c.sobrenome::text,c.usuario::text,c.imagem::text,
         c."cidadeDeResidencia"::text,c.estado::text,coalesce(c."larDeAdocao",false)
  from public.cliente c where c.id=p_cliente_id and c.ativo is true;
end;
$function$;

-- Helpers precisam de EXECUTE para os wrappers INVOKER, mas o schema private
-- não deve ser incluído nos schemas expostos do PostgREST.
revoke all on function private.resumo_responsavel(integer) from public,anon,authenticated;
revoke all on function private.detalhe_publico_responsavel(integer) from public,anon,authenticated;
revoke all on function public.buscar_resumo_responsavel(integer) from public,anon,authenticated;
revoke all on function public.buscar_perfil_publico(integer) from public,anon,authenticated;
grant execute on function private.resumo_responsavel(integer) to authenticated;
grant execute on function private.detalhe_publico_responsavel(integer) to authenticated;
grant execute on function public.buscar_resumo_responsavel(integer) to authenticated;
grant execute on function public.buscar_perfil_publico(integer) to authenticated;

comment on function private.resumo_responsavel(integer)
  is 'Entre Patas SQL12 v1: perfil ativo, chamador Auth ativo, sem filtro de animais e sem contatos privados.';
comment on function private.detalhe_publico_responsavel(integer)
  is 'Entre Patas SQL12 v1: perfil ativo, chamador Auth ativo, sem filtro de animais e sem contatos privados.';

do $postflight$
declare funcao record;
begin
  for funcao in
    select p.oid,p.oid::regprocedure as assinatura
    from pg_catalog.pg_proc p where p.oid in (
      'private.resumo_responsavel(integer)'::regprocedure,
      'private.detalhe_publico_responsavel(integer)'::regprocedure,
      'public.buscar_resumo_responsavel(integer)'::regprocedure,
      'public.buscar_perfil_publico(integer)'::regprocedure
    )
  loop
    if has_function_privilege('anon',funcao.oid,'EXECUTE')
       or not has_function_privilege('authenticated',funcao.oid,'EXECUTE') then
      raise exception 'Privilégios efetivos inesperados em %. Revisar papéis herdados.', funcao.assinatura;
    end if;
  end loop;
end;
$postflight$;

notify pgrst,'reload schema';
commit;
