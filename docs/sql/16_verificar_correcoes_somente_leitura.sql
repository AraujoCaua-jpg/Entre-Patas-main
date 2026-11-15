-- SOMENTE SELECT: verificações de catálogo após SQLs 12, 15 e 10.
-- Não chama RPCs de negócio, não consulta dados pessoais, não altera permissões.
-- Esperado: aprovado=true em todas as linhas. Antes das instalações haverá false.
with esperadas(assinatura,definer,executavel_auth) as (values
  ('public.buscar_resumo_responsavel(integer)',false,true),
  ('public.buscar_perfil_publico(integer)',false,true),
  ('private.resumo_responsavel(integer)',true,true),
  ('private.detalhe_publico_responsavel(integer)',true,true),
  ('public.excluir_meu_animal(bigint)',true,true),
  ('public.listar_minhas_adocoes()',true,true),
  ('public.buscar_minha_adocao(bigint)',true,true),
  ('public.solicitar_adocao(bigint)',true,true),
  ('public.responder_adocao(bigint,text)',true,true),
  ('public._ep_adocao_cliente_atual()',false,false),
  ('public._ep_adocoes_json(bigint,bigint)',false,false),
  ('public._ep_proteger_status_adocao_animal()',false,false)
), funcoes as (
  select e.*,p.oid,p.prosecdef,p.proconfig,p.proowner,
    (r.rolsuper or r.rolbypassrls) as owner_privilegiado
  from esperadas e left join pg_catalog.pg_proc p on p.oid=to_regprocedure(e.assinatura)
  left join pg_catalog.pg_roles r on r.oid=p.proowner
), checks as (
  select assinatura as verificacao,
    coalesce(oid is not null and prosecdef=definer and owner_privilegiado
      and 'search_path=""'=any(proconfig)
      and has_function_privilege('authenticated',oid,'EXECUTE')=executavel_auth
      and not has_function_privilege('anon',oid,'EXECUTE'),false) as aprovado
  from funcoes
  union all
  select 'RLS de cliente, animal e adocao mantida',
    count(*)=3 and bool_and(relrowsecurity)
    from pg_catalog.pg_class where oid in
      (to_regclass('public.cliente'),to_regclass('public.animal'),to_regclass('public.adocao'))
  union all
  select 'UPDATE direto de animal.ativo negado',
    not has_column_privilege('authenticated','public.animal','ativo','UPDATE')
    and not has_column_privilege('anon','public.animal','ativo','UPDATE')
  union all
  select 'DELETE fisico de animal negado',
    not has_table_privilege('authenticated','public.animal','DELETE')
    and not has_table_privilege('anon','public.animal','DELETE')
  union all
  select 'Tabela adocao sem DML direto de clientes',
    not has_table_privilege('authenticated','public.adocao','SELECT,INSERT,UPDATE,DELETE')
    and not has_table_privilege('anon','public.adocao','SELECT,INSERT,UPDATE,DELETE')
    and not has_any_column_privilege('authenticated','public.adocao','SELECT,INSERT,UPDATE')
    and not has_any_column_privilege('anon','public.adocao','SELECT,INSERT,UPDATE')
  union all
  select 'Marca dos helpers SQL 12 presente',
    coalesce(obj_description(to_regprocedure('private.resumo_responsavel(integer)'),'pg_proc') like '%SQL12 v1%',false)
    and coalesce(obj_description(to_regprocedure('private.detalhe_publico_responsavel(integer)'),'pg_proc') like '%SQL12 v1%',false)
  union all
  select 'Sem overload ambiguo de RPC de perfil ou exclusao',
    count(*)=3 and count(distinct p.proname)=3
    from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in
      ('buscar_perfil_publico','buscar_resumo_responsavel','excluir_meu_animal')
  union all
  select 'Indices unicos de adocao presentes',
    count(*)=2 and bool_and(i.indisunique and i.indisvalid)
    from pg_catalog.pg_index i where i.indexrelid in
      (to_regclass('public.ep_adocao_em_andamento_unica'),to_regclass('public.ep_adocao_aceita_unica'))
  union all
  select 'Trigger protetor de status presente',
    exists(select 1 from pg_catalog.pg_trigger t where t.tgrelid=to_regclass('public.animal')
      and t.tgname='ep_proteger_status_adocao_animal' and t.tgenabled<>'D')
)
select verificacao,aprovado from checks order by verificacao;
